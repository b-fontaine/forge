# Firebase Standard

## When to Use Firebase

**Appropriate for:**
- Small to medium Flutter projects (< 100k users)
- MVPs and early-stage products
- Projects where a managed backend accelerates delivery
- Applications requiring real-time sync (chat, collaborative tools)

**Not appropriate for:**
- Large-scale or enterprise projects requiring fine-grained access control
- Applications with complex multi-step business logic (use Temporal instead)
- Projects with strict data residency requirements not covered by Firebase regions

---

## Services

| Service | Use Case |
|---|---|
| Firebase Auth | User authentication (email, Google, Apple) |
| Cloud Firestore | Primary database (documents, real-time sync) |
| Cloud Storage | File uploads (images, documents, audio) |
| Cloud Functions | Backend logic triggered by Firestore events, HTTP calls |
| Firebase Hosting | Flutter Web deployment |
| App Check | Protect backend from unauthorized clients |

---

## Flutter Setup

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0
  firebase_app_check: ^0.3.0
  firebase_analytics: ^11.0.0
```

```dart
// lib/main.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
    webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
  );

  await configureDependencies(Environment.prod);
  runApp(const App());
}
```

---

## Firestore Data Modeling

```
users/{userId}
  ├── email: string
  ├── displayName: string
  ├── role: string ("member" | "admin")
  └── createdAt: timestamp

posts/{postId}
  ├── authorId: string (userId)
  ├── title: string
  ├── body: string
  ├── publishedAt: timestamp | null
  └── tags: string[]

posts/{postId}/comments/{commentId}
  ├── authorId: string
  ├── body: string
  └── createdAt: timestamp
```

### Repository Pattern

```dart
// lib/features/posts/adapters/firestore_post_repository.dart
@LazySingleton(as: PostRepository)
class FirestorePostRepository implements PostRepository {
  FirestorePostRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<PostDto> get _collection =>
      _firestore.collection('posts').withConverter<PostDto>(
        fromFirestore: (snap, _) => PostDto.fromJson(snap.data()!..['id'] = snap.id),
        toFirestore: (dto, _) => dto.toJson()..remove('id'),
      );

  @override
  Future<Either<Failure, Post>> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return Left(Failure.notFound(resource: 'post'));
      return Right(doc.data()!.toDomain());
    } on FirebaseException catch (e) {
      return Left(Failure.network(message: e.message ?? 'Firestore error'));
    }
  }

  @override
  Stream<Either<Failure, List<Post>>> watchUserPosts(String userId) {
    return _collection
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => Right(snap.docs.map((d) => d.data().toDomain()).toList()))
        .handleError((e) => Left(Failure.network(message: e.toString())));
  }

  @override
  Future<Either<Failure, Post>> create(CreatePostRequest req) async {
    try {
      final dto = PostDto.fromRequest(req);
      final ref = await _collection.add(dto);
      final created = await ref.get();
      return Right(created.data()!.toDomain());
    } on FirebaseException catch (e) {
      return Left(Failure.network(message: e.message ?? 'Create failed'));
    }
  }
}
```

---

## Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isAdmin() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    function hasValidPostFields() {
      return request.resource.data.keys().hasAll(['title', 'body', 'authorId']) &&
             request.resource.data.title is string &&
             request.resource.data.title.size() > 0 &&
             request.resource.data.title.size() <= 200 &&
             request.resource.data.body is string &&
             request.resource.data.authorId == request.auth.uid;
    }

    // Users: read own, write own (except role — admin only)
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId) &&
                       !request.resource.data.keys().hasAny(['role']);
      allow update: if isOwner(userId) &&
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']) ||
                    isAdmin();
      allow delete: if isAdmin();
    }

    // Posts: any auth user can read; only owner can write
    match /posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && hasValidPostFields();
      allow update: if isOwner(resource.data.authorId) && hasValidPostFields() ||
                    isAdmin();
      allow delete: if isOwner(resource.data.authorId) || isAdmin();

      // Comments: any auth user can read; own comments only
      match /comments/{commentId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() &&
                         request.resource.data.authorId == request.auth.uid &&
                         request.resource.data.body is string &&
                         request.resource.data.body.size() > 0 &&
                         request.resource.data.body.size() <= 2000;
        allow update, delete: if isOwner(resource.data.authorId) || isAdmin();
      }
    }
  }
}
```

---

## Storage Rules

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    match /users/{userId}/avatar/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId &&
                      request.resource.size < 5 * 1024 * 1024 &&  // 5MB max
                      request.resource.contentType.matches('image/.*');
    }

    match /posts/{postId}/attachments/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      request.resource.size < 20 * 1024 * 1024 &&  // 20MB max
                      (request.resource.contentType.matches('image/.*') ||
                       request.resource.contentType.matches('application/pdf'));
    }
  }
}
```

---

## Firestore Indexes

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "authorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tags", "arrayConfig": "CONTAINS" },
        { "fieldPath": "publishedAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## Offline Persistence

```dart
// lib/core/di/firebase_module.dart
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseFirestore firestore() {
    final firestore = FirebaseFirestore.instance;

    // Enable offline persistence with a 50MB cache
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    return firestore;
  }
}
```

---

## Cloud Functions (TypeScript)

```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Trigger: send notification when a new comment is created
export const onCommentCreated = functions
  .region('europe-west1')
  .firestore.document('posts/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const postId = context.params.postId;

    const post = await db.doc(`posts/${postId}`).get();
    const postData = post.data();

    if (!postData || postData.authorId === comment.authorId) return; // don't notify self

    await sendPushNotification(postData.authorId, {
      title: 'New comment on your post',
      body: comment.body.substring(0, 100),
    });
  });

// Callable function with App Check enforcement
export const getAdminReport = functions
  .region('europe-west1')
  .runWith({ enforceAppCheck: true })
  .https.onCall(async (data, context) => {
    if (!context.auth?.token?.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    // ... generate report
  });
```

---

## Emulator Setup for Testing

```json
// firebase.json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "storage": { "port": 9199 },
    "functions": { "port": 5001 },
    "hosting": { "port": 5000 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

```dart
// test/helpers/firebase_test_setup.dart
Future<void> setupFirebaseEmulators() async {
  await Firebase.initializeApp(options: testFirebaseOptions);

  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

---

## Rules

- **Security rules are tested via the emulator**: use `@firebase/rules-unit-testing` or `firebase emulators:exec`
- **Indexes are in `firestore.indexes.json`**: never create indexes manually in the console
- **No sensitive data client-readable**: structure data so clients only read what they own; use server-side Cloud Functions for cross-user data
- **Offline persistence enabled**: always configure `persistenceEnabled: true` in mobile apps
- **App Check enforced in production**: all Cloud Functions callable from clients require `enforceAppCheck: true`
- **Security rules are deployed via CI**: `firebase deploy --only firestore:rules,storage:rules`
- **Field validation in security rules**: validate type, length, and required fields in Firestore rules — not just auth
- **Rate limiting via Cloud Functions**: implement quotas in callable functions to prevent abuse
- **Authentication state persists**: use `FirebaseAuth.instance.authStateChanges()` stream, not one-time read
