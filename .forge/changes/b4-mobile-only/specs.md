# Specs: b4-mobile-only

**Namespace** : `FR-MO-*` / `NFR-MO-*` (nouveau, sera consolidé dans
`.forge/specs/mobile-only.md` à l'archive).

**Constitution** : v1.1.0 (premier change post-D.5). Pas d'amendement requis.

**Plateformes** : iOS `15.0+` (App Attest, biometric Face ID/Touch ID),
Android `minSdkVersion = 26` (Play Integrity, biometric StrongBox).

---

## ADDED Requirements

### Cluster 1 — Archetype contract

#### FR-MO-001 : Schéma archétype `mobile-only`

Le fichier `.forge/schemas/mobile-only/schema.yaml` MUST exister.

Le schéma MUST déclarer :
- `archetype: mobile-only`
- `schema_version: "1.0.0"`
- `description` (≥ 30 caractères) résumant le périmètre
- `layers:` avec **exactement 1 entrée** : `id: app, path: .` (single-layer, le projet entier EST l'app mobile)
- `constitution_articles_bound: [I, II, III, IV, V, VI, IX, X, XII]` (VII, VIII, XI explicitement NA pour cet archétype)

**Test L1** : `[[ -f .forge/schemas/mobile-only/schema.yaml ]]` ET parsing YAML valide ET `layers[].id == "app"`.

#### FR-MO-002 : Templates archétype `mobile-only`

Le répertoire `.forge/templates/archetypes/mobile-only/` MUST exister.

Il MUST contenir au minimum les fichiers suivants (extension `.tmpl`
optionnelle pour ceux qui contiennent des placeholders) :
- `pubspec.yaml.tmpl` (avec placeholders `{{project_name}}`, `{{reverse_domain}}`)
- `analysis_options.yaml`
- `.gitignore`
- `README.md.tmpl`
- `CLAUDE.md.tmpl` (scope Flutter mobile)
- `.forge.yaml.tmpl` (déclare `schema: mobile-only`)
- `lib/main.dart.tmpl`
- `lib/app.dart.tmpl`
- `lib/auth/` (au moins 5 fichiers Dart : interfaces + bloc + repository + secure storage adapter + oidc_config placeholder)
- `lib/observability/` (au moins 1 fichier configurant OTel)
- `lib/biometric/` (au moins 1 fichier wrappant `local_auth`)
- `lib/attestation/` (interfaces + impl iOS + impl Android)
- `test/` (≥ 3 fichiers de tests Flutter scaffoldés)
- `integration_test/` (≥ 1 fichier `.feature` cucumber-flutter)
- `ios/Runner/Info.plist.tmpl` (avec placeholders bundle id, display name)
- `ios/Podfile.tmpl` (deployment target `15.0`)
- `android/app/src/main/AndroidManifest.xml.tmpl`
- `android/app/build.gradle.kts.tmpl` (minSdkVersion `26`, targetSdk ≥ `34`)
- `android/build.gradle.kts.tmpl`
- `android/settings.gradle.kts.tmpl`
- `fastlane/Fastfile.tmpl` (au niveau iOS et Android)
- `fastlane/Appfile.tmpl`
- `fastlane/Matchfile.tmpl`
- `.github/workflows/mobile-ci.yml.tmpl`

**Test L1** : présence des fichiers listés (boucle `[ -f ... ]`).

#### FR-MO-003 : Dispatch table — entrée `mobile-only`

`.forge/scaffolding/dispatch-table.yml` MUST avoir une entrée :

```yaml
mobile-only:
  name: mobile-only
  scaffolder: "bin/forge-init-mobile-only.sh"
  description: "Flutter iOS + Android, OIDC via flutter_appauth, secure storage + biometric + attestation. No backend, no BaaS."
  signals:
    - pubspec.yaml
    - ios/Runner/Info.plist
    - android/app/build.gradle
  since: "1.2.0"
```

L'auto-detection MUST distinguer `mobile-only` de `full-stack-monorepo` :
si `pubspec.yaml` ET `Cargo.toml` sont présents, l'archétype est
`full-stack-monorepo` ; si `pubspec.yaml` ET `ios/Runner/Info.plist`
sont présents SANS `Cargo.toml`, l'archétype est `mobile-only`.

**Test L1** : parsing YAML, vérification du nom, des signals, et de
l'absence de `Cargo.toml` dans la liste signals.

#### FR-MO-004 : Wrapper `bin/forge-init-mobile-only.sh`

Le fichier MUST exister et MUST être exécutable (`chmod +x`).

Le wrapper MUST respecter l'**ABI stable** définie par
`.forge/standards/global/scaffolding.md` (B.5.1) :

- Flag `--target <dir>` (REQUIRED)
- Flag `--project-name <slug>` (REQUIRED, format `[a-z][a-z0-9_]+`)
- Flag `--reverse-domain <fqdn>` (REQUIRED, format `^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$`)
- Flag `--force` (OPTIONAL, écrase un répertoire non-vide)

Le wrapper MUST :
1. Refuser de tourner si `$target` n'existe pas (création requise).
2. Refuser si `$target` est non-vide et `--force` absent (exit code 2).
3. Copier l'arborescence de `.forge/templates/archetypes/mobile-only/` vers `$target`.
4. Substituer `{{project_name}}` et `{{reverse_domain}}` dans tous les fichiers `.tmpl` (puis renommer en retirant le suffixe).
5. Ajuster `ios/Runner/` et `android/app/` avec le reverse domain comme bundle/application id.
6. Exit code 0 sur succès, ≠ 0 sur erreur avec message stderr explicite.

**Test L1** : ABI parsing (rejet d'argv invalide), idempotence (deux runs avec --force produisent le même résultat).

#### FR-MO-005 : Snapshot tarball pré-build

`.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz` MUST exister à l'archive.

Le tarball MUST :
- Contenir l'arborescence de `.forge/templates/archetypes/mobile-only/` à la racine.
- Être gzipped (`.tar.gz`, pas `.tar`).
- Avoir une taille ≤ **2 MB gzipped** (NFR-MO-001 budget).
- Être enregistré dans Git (suivi par version control, pas .gitignored).

**Test L1** : `[[ -f ... ]]`, taille ≤ budget, format gzip valide (`file` magic).

---

### Cluster 2 — Flutter project skeleton

#### FR-MO-006 : `pubspec.yaml.tmpl`

Le `pubspec.yaml.tmpl` MUST déclarer les dépendances suivantes (versions
résolues au moment de l'archive, pinnées pour reproductibilité) :

- `flutter_bloc` (Article VI.4 state management)
- `flutter_appauth` (OIDC)
- `flutter_secure_storage` (Keychain/Keystore)
- `local_auth` (biometric)
- `opentelemetry_api` + `opentelemetry_sdk` (Article IX)
- `equatable` (cohérent avec convention bloc)

DevDependencies MUST inclure :
- `flutter_test` (SDK)
- `bloc_test`
- `mocktail` ou `mockito` (au choix, mais explicitement déclaré)
- `integration_test` (SDK)
- `cucumber` ou `gherkin` (Article II + Article VI.7)

Le `pubspec.yaml.tmpl` MUST déclarer `environment.sdk: ">=3.0.0 <4.0.0"`
et `environment.flutter: ">=3.16.0"`.

**Test L1** : grep des packages requis dans le template.

#### FR-MO-007 : `analysis_options.yaml` strict

`analysis_options.yaml` MUST :
- Étendre `package:flutter_lints/flutter.yaml`
- Activer `errors.invalid_annotation_target: ignore` (compatibilité freezed/json_serializable si adopté)
- Activer ≥ 5 lints stricts au-delà du baseline (`prefer_const_constructors`, `unawaited_futures: error`, `avoid_print`, `prefer_final_locals`, `unnecessary_lambdas`)

**Test L1** : grep des règles requises.

#### FR-MO-008 : Architecture clean layered

`lib/` MUST exposer la séparation Article VI.6 :
- `lib/domain/` — entities, repositories interfaces, use cases
- `lib/data/` — repository implementations, data sources, DTOs
- `lib/presentation/` — pages, widgets, blocs (UI)
- `lib/infrastructure/` — adapters concrets vers OS/SDK (auth, storage, biometric, attestation)

Chaque couche MUST contenir au moins **1 fichier exemple** scaffoldé
non-vide (≥ 10 lignes Dart utiles).

**Test L1** : présence des 4 sous-répertoires + comptage de fichiers ≥ 1 par sous-répertoire.

#### FR-MO-009 : Au moins 1 BDD `.feature` scaffoldé

`integration_test/features/` MUST contenir au moins :
- `login.feature` avec scénario Given/When/Then sur le flow OIDC happy path

Le fichier `.feature` MUST suivre la syntaxe Gherkin (commencer par `Feature:`,
contenir `Scenario:` et `Given`/`When`/`Then`).

**Test L1** : présence + grep des mots-clés Gherkin.

#### FR-MO-010 : `main.dart.tmpl` cohérent

`lib/main.dart.tmpl` MUST :
- Initialiser le BlocObserver (logging des transitions)
- Initialiser l'OTel SDK
- Initialiser le secure storage (vérifier disponibilité)
- Lancer `runApp(const App())`

Pas de logique métier dans `main.dart`. Toute la logique est dans
`lib/app.dart.tmpl` (le widget root + DI graph).

**Test L1** : grep des appels d'init attendus.

---

### Cluster 3 — iOS native config

#### FR-MO-011 : `ios/Runner/Info.plist.tmpl`

`Info.plist.tmpl` MUST déclarer au minimum :
- `CFBundleIdentifier` = `{{reverse_domain}}` (placeholder substitué au scaffold)
- `CFBundleDisplayName` = `{{project_name}}` (placeholder)
- `MinimumOSVersion` = `15.0`
- `NSFaceIDUsageDescription` (string non-vide expliquant pourquoi Face ID)
- `LSApplicationQueriesSchemes` includes browser schemes (`https`)

**Test L1** : grep des clés requises + valeur `15.0`.

#### FR-MO-012 : `ios/Podfile.tmpl`

`Podfile.tmpl` MUST :
- Pinner `platform :ios, '15.0'`
- Ne PAS contenir de chemin absolu hardcodé (portable cross-machine)
- Inclure le hook standard Flutter (`flutter_install_all_ios_pods`)

**Test L1** : grep `platform :ios, '15.0'` ET absence de `/Users/`.

#### FR-MO-013 : `ios/Runner/AppAttestService.swift.tmpl`

Un fichier Swift `AppAttestService.swift.tmpl` MUST exister sous `ios/Runner/` (ou un emplacement équivalent documenté), exposant un service Flutter MethodChannel pour App Attest avec :
- Méthode `generateKey()` retournant `keyId` ou erreur
- Méthode `attestKey(keyId, clientHash)` retournant l'attestation token
- Méthode `assert(keyId, clientHash)` retournant l'assertion token

Le code Swift MUST référencer `DeviceCheck` et `DCAppAttestService.shared`.

**Test L1** : présence + grep `DCAppAttestService`.

---

### Cluster 4 — Android native config

#### FR-MO-014 : `android/app/build.gradle.kts.tmpl`

`build.gradle.kts.tmpl` MUST :
- Pinner `minSdk = 26`
- Pinner `targetSdk` ≥ `34`
- Pinner `compileSdk` ≥ `34`
- Activer `buildFeatures.viewBinding = true` (cohérent avec local_auth fragment hosting)
- Inclure `applicationId = "{{reverse_domain}}"` (placeholder)
- Inclure `namespace = "{{reverse_domain}}"` (placeholder, AGP 8+)

**Test L1** : grep des valeurs requises.

#### FR-MO-015 : `AndroidManifest.xml.tmpl`

`AndroidManifest.xml.tmpl` MUST déclarer au minimum :
- Permission `<uses-permission android:name="android.permission.USE_BIOMETRIC" />`
- Permission `<uses-permission android:name="android.permission.INTERNET" />`
- `MainActivity` étend `FlutterFragmentActivity` (REQUIRED par local_auth, pas FlutterActivity)
- Intent filter pour OIDC redirect URI (callback scheme custom)

**Test L1** : grep des permissions ET de `FlutterFragmentActivity`.

#### FR-MO-016 : Play Integrity hook Kotlin

Un fichier Kotlin `PlayIntegrityService.kt.tmpl` MUST exister sous `android/app/src/main/kotlin/{{reverse_domain_path}}/`, exposant un MethodChannel avec :
- Méthode `requestIntegrityToken(nonce)` retournant le token Play Integrity ou erreur

Le code Kotlin MUST référencer `IntegrityManager` et `IntegrityTokenRequest`.

**Test L1** : présence + grep `IntegrityManager`.

---

### Cluster 5 — OIDC + Auth

#### FR-MO-017 : `lib/infrastructure/auth/oidc_config.dart.tmpl`

Le fichier MUST exister vide-mais-structuré :
- Une classe `OidcConfig` avec champs `issuer`, `clientId`, `redirectUri`, `scopes`
- Une constante `defaultConfig` avec valeurs **placeholder explicites** (`'TODO_REPLACE_*'`) — pas de valeurs Auth0/Keycloak/Okta câblées
- Commentaire en tête pointant les 4 providers : Auth0, Keycloak, Okta, AWS Cognito (avec liens documentation)

**Test L1** : présence + grep `TODO_REPLACE_` ET grep des 4 providers en commentaire.

#### FR-MO-018 : `auth_bloc.dart.tmpl`

Un AuthBloc MUST exister sous `lib/presentation/auth/` exposant :
- States : `AuthInitial`, `AuthLoading`, `AuthAuthenticated(token)`, `AuthUnauthenticated`, `AuthError(message)`
- Events : `AuthLoginRequested`, `AuthLogoutRequested`, `AuthTokenRefreshRequested`, `AuthBiometricUnlockRequested`
- Transitions testées via `bloc_test` dans `test/presentation/auth/auth_bloc_test.dart.tmpl`

**Test L1** : présence + grep des states/events.

#### FR-MO-019 : Repository abstraction

`lib/domain/auth/auth_repository.dart.tmpl` MUST déclarer une interface :
- `Future<AuthToken> login()` (lance le flow PKCE via flutter_appauth)
- `Future<AuthToken> refresh(String refreshToken)`
- `Future<void> logout()`
- `Future<AuthToken?> getCurrentToken()` (lit le secure storage)

L'implémentation `lib/data/auth/auth_repository_impl.dart.tmpl` MUST :
- Utiliser `flutter_appauth` pour login/refresh
- Utiliser `flutter_secure_storage` pour persistance
- Ne JAMAIS logger le token (pas de `print(token)` ni `debugPrint(token)`)

**Test L1** : présence + grep `FlutterAppAuth` ET absence de `print($token` / `debugPrint($token`.

#### FR-MO-020 : Secure storage adapter

`lib/infrastructure/storage/secure_storage_adapter.dart.tmpl` MUST :
- Wrap `flutter_secure_storage`
- iOS : configurer `KeychainAccessibility.first_unlock_this_device` (token accessible après premier déverrouillage seulement)
- Android : configurer `EncryptedSharedPreferences` (StrongBox quand disponible via `useStrongBox` flag)

**Test L1** : grep des classes et options.

#### FR-MO-021 : Token refresh flow

Le repository MUST exposer un comportement de refresh automatique :
- Quand `getCurrentToken()` détecte un token expiré, déclencher un refresh transparent
- Si refresh échoue (refresh_token expired, network), retourner `null` et l'auth bloc émet `AuthUnauthenticated`

Documenté en BDD scenario (cf. Acceptance Criteria).

**Test L1** : test unitaire `bloc_test` scaffoldé qui vérifie la transition.

---

### Cluster 6 — Biometric

#### FR-MO-022 : `lib/infrastructure/biometric/biometric_service.dart.tmpl`

Le fichier MUST :
- Wrapper `local_auth`
- Exposer `Future<bool> canCheckBiometric()`
- Exposer `Future<bool> authenticate({required String reason})`
- Configurer `AuthenticationOptions(biometricOnly: true, stickyAuth: true)`

**Test L1** : présence + grep des appels `LocalAuthentication`.

#### FR-MO-023 : Re-prompt après timeout

Le BiometricService MUST documenter (en commentaire dans le fichier) le pattern de re-prompt après backgrounding :
- Quand l'app rentre en `AppLifecycleState.paused` puis revient en `resumed`
- Si la dernière auth a > N secondes (configurable, défaut 60s)
- Re-prompter biometric

L'implémentation effective du WidgetsBindingObserver est scaffoldée dans `lib/app.dart.tmpl` ou un `lib/presentation/biometric/biometric_lock_widget.dart.tmpl`.

**Test L1** : grep `AppLifecycleState` ou `WidgetsBindingObserver` dans les templates.

#### FR-MO-024 : Fallback PIN/passphrase documenté

Le standard `flutter-mobile.md` MUST mentionner le fallback PIN/passphrase
quand biometric n'est pas disponible (utilisateur sans empreinte enregistrée,
matériel défectueux). Le scaffold ne livre PAS d'implémentation PIN
(adopter-specific) mais documente le pattern.

**Test L1** : grep dans `.forge/standards/global/flutter-mobile.md`.

---

### Cluster 7 — Attestation

#### FR-MO-025 : Interface `device_attestor`

`lib/domain/attestation/device_attestor.dart.tmpl` MUST déclarer une interface :
- `Future<String> requestAttestationToken({required String nonce})`
- `Future<bool> isSupported()`

#### FR-MO-026 : Impl iOS via App Attest

`lib/infrastructure/attestation/ios_app_attest_attestor.dart.tmpl` MUST :
- Implémenter `DeviceAttestor`
- Communiquer avec `AppAttestService.swift.tmpl` via MethodChannel `forge.attestation/app_attest`

#### FR-MO-027 : Impl Android via Play Integrity

`lib/infrastructure/attestation/android_play_integrity_attestor.dart.tmpl` MUST :
- Implémenter `DeviceAttestor`
- Communiquer avec `PlayIntegrityService.kt.tmpl` via MethodChannel `forge.attestation/play_integrity`

**Tests L1 (FR-MO-025/026/027)** : présence des 3 fichiers + grep MethodChannel name + grep `IsSupported`.

---

### Cluster 8 — Observability

#### FR-MO-028 : Module `lib/observability/`

`lib/observability/otel_init.dart.tmpl` MUST :
- Initialiser un Tracer + Meter via `opentelemetry_sdk`
- Configurer un OTLP exporter (HTTP/gRPC) avec endpoint **lu depuis env/config**, valeur par défaut `http://localhost:4318` (dev mode)
- Exposer une méthode `Future<void> initOtel({required String endpoint})`

**Test L1** : présence + grep `OtlpExporter` et `endpoint`.

#### FR-MO-029 : Article IX trace propagation hooks

Le repository auth MUST instrumenter ses appels API avec un span OTel
(`auth.login`, `auth.refresh`, `auth.logout`). Le scaffold livre l'instrumentation
exemplaire ; un adopter peut étendre.

**Test L1** : grep `tracer.startSpan` dans les fichiers `*auth_repository*`.

---

### Cluster 9 — Fastlane

#### FR-MO-030 : `fastlane/` structure

Au niveau du projet (post-scaffold), `fastlane/` MUST exister sous **chaque** des
deux racines `ios/` et `android/`, chacun avec :
- `Fastfile.tmpl`
- `Appfile.tmpl`
- `Matchfile.tmpl` (iOS uniquement)
- `Pluginfile.tmpl`

**Test L1** : présence ou template présent côté `.forge/templates/archetypes/mobile-only/ios/fastlane/` + `android/fastlane/`.

#### FR-MO-031 : Lanes minimales

`Fastfile.tmpl` (iOS) MUST définir au minimum les lanes :
- `beta` — build + upload à TestFlight
- `release` — build + upload à App Store Connect (release manuelle, pas auto-publish)
- `screenshots` — `snapshot run`
- `match_setup` — initialise le repo de certs (pas auto-run)

`Fastfile.tmpl` (Android) MUST définir :
- `beta` — build aab + upload à Play Internal Testing
- `release` — build aab + upload à Play Production track
- `screenshots` — `screengrab run`

**Test L1** : grep `lane :beta`, `lane :release`, `lane :screenshots` dans les Fastfile.

#### FR-MO-032 : Pas de secrets hardcodés

Les fichiers Fastlane livrés NE DOIVENT PAS contenir de secret en clair :
- Pas de `app_specific_password`, `api_key`, etc. en clair
- Tous les secrets référencent des **variables d'environnement** (`ENV["APP_STORE_CONNECT_API_KEY_PATH"]`, `ENV["MATCH_PASSWORD"]`, etc.)

**Test L1** : grep `ENV\[` dans Fastfile, ET grep `password.*=.*['"]` (matching un secret literal) NE DOIT PAS matcher.

---

### Cluster 10 — CI workflow

#### FR-MO-033 : `mobile-ci.yml.tmpl`

`.github/workflows/mobile-ci.yml.tmpl` MUST déclarer ≥ 3 jobs :
- `ios` — runs-on `macos-latest`, étapes : checkout, setup-flutter, `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build ios --no-codesign`
- `android` — runs-on `ubuntu-latest`, setup JDK 17 + Flutter, `flutter analyze`, `flutter test`, `flutter build apk --debug`
- `summary` — required status check, conditional sur ios + android

Optional 4th job `e2e-android` (opt-in via workflow_dispatch ou `[ci-e2e]` flag dans commit msg) qui tourne `flutter test integration_test/` sur émulateur Android.

**Test L1** : grep `runs-on: macos-latest` + `runs-on: ubuntu-latest` + ≥ 3 `name:` jobs.

#### FR-MO-034 : Coverage threshold

Le job `android` MUST collecter la couverture (`flutter test --coverage`) et
fail si la couverture est < 70 % (cohérent avec Article X.4 baseline).

**Test L1** : grep `--coverage` ET grep d'un seuil (`70` ou `THRESHOLD`).

#### FR-MO-035 : Cache flutter pub

Les jobs MUST cacher `~/.pub-cache` (clé : `pubspec.lock` hash) pour
réduire le temps CI.

**Test L1** : grep `actions/cache` + référence à `pub-cache`.

---

### Cluster 11 — Standards

#### FR-MO-036 : `.forge/standards/global/flutter-mobile.md`

Le fichier MUST exister et MUST contenir au minimum les sections H2 :
- `## Lifecycle and Backgrounding` (AppLifecycleState, secure data wipe sur background, screenshot blur)
- `## Permissions` (runtime permissions Android, Info.plist usage descriptions iOS)
- `## OIDC and Token Storage` (PKCE flow obligatoire, refresh_token sécurisé, jamais de token dans logs)
- `## Biometric Lock` (re-prompt timeout, fallback PIN, sticky auth)
- `## Device Attestation` (App Attest + Play Integrity, when to attest, server verification)
- `## Native Configuration` (iOS deployment 15.0, Android minSdk 26, Podfile/build.gradle pinning)
- `## CI / Fastlane` (signing strategies, code signing isolation, secrets via ENV)

Le fichier MUST aussi inclure ≥ **3 Interdictions** explicites (anti-patterns) :
- Pas de stockage de token en `SharedPreferences` non-chiffré
- Pas de logging d'access_token / refresh_token
- Pas de bypass biometric en mode debug commit dans `main`

`.forge/standards/index.yml` MUST référencer le nouveau standard avec
triggers sur paths : `lib/`, `ios/`, `android/`, `pubspec.yaml`, `Fastfile`.

**Test L1** : présence du fichier + comptage des H2 attendus + grep
"Interdiction" ≥ 3 fois + entrée dans index.yml.

---

### Cluster 12 — Harness

#### FR-MO-037 : Harness `b4.test.sh`

`.forge/scripts/tests/b4.test.sh` MUST :
- Suivre le pattern manifest (lignes `# MANIFEST: _test_b4_NNN — FR-MO-XXX`)
- Couvrir au minimum **1 test par FR-MO-* listé ci-dessus** (≥ 35 tests)
- Inclure des tests L2 fixture-based : scaffolder un projet temporaire via `bin/forge-init-mobile-only.sh --target /tmp/...` et vérifier la structure produite (≥ 5 tests L2)
- Être exécutable et découvert par `verify.sh`
- Être enregistré dans `.github/workflows/forge-ci.yml` job `harness` par nom

**Test L1** : `[[ -x .forge/scripts/tests/b4.test.sh ]]` + comptage MANIFEST.

---

### Cluster 13 — Intégrations transverses

#### FR-MO-038 : `framework-owned-paths.yml` étendu

`.forge/framework-owned-paths.yml` (A.7) MUST référencer les paths
spécifiques à mobile-only **uniquement quand l'archétype est mobile-only**
sur le projet adopter. Concrètement :

- Le fichier `.forge/framework-owned-paths.yml` côté framework reste
  agnostique (il décrit les paths Forge généralistes).
- L'archétype `mobile-only` peut livrer un `.forge/framework-owned-paths.yml.tmpl`
  qui s'ajoute / remplace lors du scaffold pour décrire les paths
  spécifiques à l'archétype (ex. `lib/observability/otel_init.dart`).

**Test L1** : présence d'un template `framework-owned-paths.yml.tmpl`
sous `.forge/templates/archetypes/mobile-only/.forge/`.

#### FR-MO-039 : `docs/ARCHETYPES.md` mis à jour

`docs/ARCHETYPES.md` MUST avoir une nouvelle ligne dans la matrice de décision pour `mobile-only`, alignée avec les colonnes existantes (Use case / Frontend / Backend / Infra / Auth / Storage / CI/CD / When to use).

**Test L1** : grep `mobile-only` dans la table + ≥ 1 nouvelle ligne dans le tableau Markdown.

#### FR-MO-040 : Périmètre négatif

Le change b4-mobile-only NE DOIT PAS modifier :

- `cli/src/**` (zéro édition TS — preuve par construction du contrat B.5.1)
- `cli/package.json`, `cli/package-lock.json`
- Le schéma `full-stack-monorepo` ou ses templates
- `.forge/constitution.md` (zéro amendement — déjà à v1.1.0)
- Les changes archivés (immuabilité)

**Test L1** : exécuté manuellement au gate `/forge:archive`, via `git diff --name-only main...HEAD`.

---

## Acceptance Criteria (BDD)

### Scénario 1 — Adopter scaffolde un projet mobile-only

```gherkin
Given an empty directory /tmp/myapp
And the Forge CLI installed (npm install -g @sdd-forge/cli)
When the adopter runs `forge init --target /tmp/myapp --archetype mobile-only --project-name myapp --reverse-domain com.example.myapp`
Then the directory /tmp/myapp contains pubspec.yaml, ios/, android/, lib/, test/, integration_test/, fastlane/
And lib/main.dart exists with BlocObserver + OTel init
And ios/Runner/Info.plist contains CFBundleIdentifier = com.example.myapp
And android/app/build.gradle.kts contains applicationId = "com.example.myapp" and minSdk = 26
And running `flutter pub get && flutter analyze` succeeds (no errors)
And exit code = 0
```

### Scénario 2 — User OIDC login happy path

```gherkin
Given a user has launched the scaffolded app
And the app is on the login screen
When the user taps "Sign in"
Then flutter_appauth opens an external browser to the OIDC issuer
And after the user authenticates, the browser redirects to the configured redirect URI
And the AuthBloc transitions Initial -> Loading -> Authenticated(token)
And the access_token is persisted in flutter_secure_storage (Keychain on iOS / EncryptedSharedPreferences on Android)
And no token appears in logs (verified by static grep at template-time)
```

### Scénario 3 — Token refresh transparent

```gherkin
Given a user is authenticated with an access_token expiring in 60 seconds
When 65 seconds elapse and the user triggers an authenticated API call
Then the auth_repository detects expiry
And calls flutter_appauth.token() with the persisted refresh_token
And on success, persists the new token pair and returns the new access_token to the caller
And on failure (refresh_token expired or network error), AuthBloc emits AuthUnauthenticated
And the user is redirected to the login screen
```

### Scénario 4 — Biometric unlock après backgrounding

```gherkin
Given a user is authenticated and the app is in foreground
And BiometricService is configured with timeout = 60s
When the user backgrounds the app for 90 seconds and returns
Then on AppLifecycleState.resumed, the BiometricLockWidget intercepts
And calls LocalAuthentication.authenticate(reason: "Unlock <appname>")
And on success the user can resume their session without re-OIDC
And on failure (user cancels or no biometric), the BiometricLockWidget shows a fallback prompt (PIN entry, adopter-implemented)
```

### Scénario 5 — Attestation token attached to API call

```gherkin
Given the device is integrity-checked (App Attest on iOS or Play Integrity on Android)
When the auth_repository performs login
Then it requests a fresh attestation token via DeviceAttestor.requestAttestationToken(nonce: <random>)
And attaches it to the OIDC request as a custom header (e.g. X-Device-Attestation)
And the backend (out of scope for this archetype) verifies the token before issuing the access_token
And if attestation fails (jailbroken device, emulator without bypass flag), the bloc emits AuthError("Device integrity check failed")
```

### Scénario 6 — CI runs on every PR touching mobile/

```gherkin
Given a PR is opened that modifies lib/auth/ or ios/ or android/
When GitHub Actions triggers mobile-ci.yml
Then the ios job runs on macos-latest with flutter analyze + test + build ios --no-codesign
And the android job runs on ubuntu-latest with flutter analyze + test + build apk --debug
And the summary job becomes the required status check
And merging to main is blocked until summary = success
```

### Scénario 7 — Forge upgrade preserves adopter modifications

```gherkin
Given an adopter has scaffolded a mobile-only project on Forge 1.2.0
And the adopter has customized lib/auth/oidc_config.dart with their issuer URL
When Forge releases 1.3.0 with mobile-only template improvements
And the adopter runs `forge upgrade`
Then the 3-way merge preserves their oidc_config.dart customization
And applies framework-side template improvements that don't conflict
And reports any conflicts via .merge-conflicts companion files
```

---

## Non-Functional Requirements

### NFR-MO-001 : Snapshot tarball size budget

`.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz` SHOULD be ≤ **2 MB
gzipped**. Hard limit ≤ 5 MB. Mesure : `du -h` sur le fichier
post-archive. Rationale : les snapshots transitent dans le tarball npm
de la CLI ; budgetisation similaire à FSM (422 KB).

### NFR-MO-002 : Scaffold time

`forge init --archetype mobile-only --target <dir>` SHOULD compléter en ≤ **5 secondes** sur un MacBook M-series (référence). Hard limit ≤ 15 s. Mesuré par `time` au harness L2.

### NFR-MO-003 : `flutter pub get` post-scaffold

Sur un projet fraîchement scaffoldé, `flutter pub get` MUST retourner exit
code 0 (pas de version incompatible, pas de package introuvable).

Vérification : harness L2 (opt-in `--require-flutter`).

### NFR-MO-004 : `flutter analyze` post-scaffold

Sur un projet fraîchement scaffoldé, `flutter analyze` MUST retourner exit
code 0 (zéro erreur de lint sur le scaffold lui-même).

Vérification : harness L2 (opt-in `--require-flutter`).

### NFR-MO-005 : `flutter test` post-scaffold

Sur un projet fraîchement scaffoldé, `flutter test` MUST passer (les tests
exemple scaffoldés MUST être verts immédiatement, pas de RED initial sur
le scaffold lui-même — l'adopter écrit sa première feature en
RED→GREEN, mais l'état initial est GREEN).

Vérification : harness L2 (opt-in `--require-flutter`).

### NFR-MO-006 : Aucune dépendance npm nouvelle dans `cli/`

Le change b4-mobile-only NE DOIT PAS ajouter de dépendance dans
`cli/package.json` (preuve par construction que B.5.1 ABI suffit).

### NFR-MO-007 : Compatible avec `forge upgrade` (A.7)

Le change MUST :
- Étendre `.forge/framework-owned-paths.yml` (côté framework) si nécessaire
- OU livrer un `framework-owned-paths.yml.tmpl` côté archétype
- Ne casser aucune trajectoire existante d'upgrade pour un adopter sur full-stack-monorepo

Vérification : `bash .forge/scripts/tests/a7.test.sh` passe à 100 % après livraison de B.4.

### NFR-MO-008 : 100 % des FR-MO-* couverts par tests

Chaque FR-MO-NNN MUST avoir au moins 1 test L1 ou L2 dans `b4.test.sh`. Pas de FR sans assertion automatisée. Vérification : audit manuel + manifest counter à l'archive.

---

## Anti-Hallucination Pass

| FR | Testable ? | Ambigu ? | Conforme Constitution ? |
|---|---|---|---|
| FR-MO-001 → FR-MO-005 (archetype contract) | ✅ tests fichiers + parsing YAML | ❌ | ✅ |
| FR-MO-006 → FR-MO-010 (Flutter skeleton) | ✅ grep dépendances + arch | ❌ | ✅ Article VI |
| FR-MO-011 → FR-MO-013 (iOS native) | ✅ grep keys + version | ❌ | ✅ Article VI |
| FR-MO-014 → FR-MO-016 (Android native) | ✅ grep build.gradle + permissions | ❌ | ✅ Article VI |
| FR-MO-017 → FR-MO-021 (OIDC + Auth) | ✅ grep classes + bloc states | ❌ | ✅ Article VI.4 (bloc) |
| FR-MO-022 → FR-MO-024 (Biometric) | ✅ grep `LocalAuthentication` + commentaires lifecycle | ❌ | ✅ |
| FR-MO-025 → FR-MO-027 (Attestation) | ✅ grep MethodChannel + impls | ❌ | ✅ |
| FR-MO-028 → FR-MO-029 (Observability) | ✅ grep `OtlpExporter` + spans | ❌ | ✅ Article IX |
| FR-MO-030 → FR-MO-032 (Fastlane) | ✅ grep lanes + ENV[ | ❌ | ✅ |
| FR-MO-033 → FR-MO-035 (CI) | ✅ YAML structure + grep | ❌ | ✅ |
| FR-MO-036 (standards) | ✅ comptage H2 + index trigger | ❌ | ✅ |
| FR-MO-037 (harness) | ✅ comptage MANIFEST | ❌ | ✅ Article I |
| FR-MO-038 → FR-MO-040 (intégrations) | ✅ présence + git diff | ❌ | ✅ |

**Aucun `[NEEDS CLARIFICATION:]` restant.** Les 3 questions ouvertes du
proposal ont été tranchées par décision utilisateur le 2026-04-30 :
1. Plateformes minimum : iOS 15.0 + Android `minSdkVersion 26`
2. OIDC provider : neutre (placeholder + README pointing 4 providers)
3. Snapshot tarball pré-build : OUI

---

## Constitution Compliance Summary

- **Article I (TDD)** : harness `b4.test.sh` RED→GREEN par phase. Templates Flutter livrent un état GREEN initial. ✅
- **Article II (BDD)** : 7 scénarios documentés ci-dessus. ≥ 1 fichier `.feature` cucumber-flutter scaffoldé. ✅
- **Article III (Specs Before Code)** : pipeline complet. ✅
- **Article III.4 (Anti-hallucination)** : 0 `[NEEDS CLARIFICATION:]`, 3 décisions ouvertes tranchées. ✅
- **Article IV (Delta-based)** : ADDED-only namespace. Modifs limitées d'`index.yml` / `dispatch-table.yml` / `forge-ci.yml` / `docs/ARCHETYPES.md` documentées explicitement. ✅
- **Article V (Process Gates)** : pipeline `propose → specify → design → plan → implement → archive` au complet. ✅
- **Article VI (Flutter)** : flutter_bloc obligatoire (FR-MO-018), clean architecture (FR-MO-008), cucumber-flutter (FR-MO-009). ✅
- **Article VII (Rust)** : NA. ✅
- **Article VIII (Infra)** : NA. ✅
- **Article IX (Observability)** : OTel client (FR-MO-028 + FR-MO-029). ✅
- **Article X (Quality)** : analysis_options strict (FR-MO-007), coverage 70 % (FR-MO-034), pas de secrets en clair (FR-MO-032). ✅
- **Article XI (AI-First)** : NA pour cet archétype. ✅
- **Article XII (Governance)** : premier change post-D.5, `constitution_version: "1.1.0"`. ✅

---

**Status** : `specified`. Next : `/forge:design b4-mobile-only`.
