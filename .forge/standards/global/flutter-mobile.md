# Standard: Flutter Mobile (iOS + Android)

<!-- Audit: B.4 (b4-mobile-only, FR-MO-036) -->

This standard governs Flutter projects scaffolded via the `mobile-only`
archetype (or any Flutter mobile project subscribing to it). It
complements the constitutional Article VI (Flutter Architecture) with
mobile-specific concerns.

Activated by `.forge/standards/index.yml` triggers on paths : `lib/**`,
`ios/**`, `android/**`, `pubspec.yaml`, `Fastfile`.

---

## Lifecycle and Backgrounding

The mobile-only archetype assumes a hostile lifecycle: users background
the app, multitask, swap SIM, lock the device, swap user (Android), kill
the app from the recents tray. The codebase MUST behave correctly under
all these transitions.

- All long-running operations MUST be cancellable via the standard
  Stream / Future cancellation idioms. No "fire and forget" without
  acknowledging the lifecycle owner (cf. `unawaited_futures` lint).
- Sensitive screens (auth tokens visible, payment, PII) MUST clear or
  blur on `AppLifecycleState.paused` to prevent screenshot exposure in
  the OS recents tray. Use `MediaQuery.of(context).platformBrightness`
  + a route observer + `SystemChannels.lifecycle`. Pattern documented
  in `BiometricLockWidget`.
- The biometric re-prompt timer (default 60s) is the canonical
  re-authentication trigger. Do NOT bypass it for "convenience"
  routes — the prompt is the security boundary.
- Network calls in flight when the app is paused MUST not assume a
  return to the same widget tree. Use `mounted` checks before
  `setState` / emit.

## Permissions

iOS uses Info.plist usage descriptions; Android uses runtime permission
prompts via `permission_handler` or platform-specific channels.

- Every entry in `Info.plist` like `NSFaceIDUsageDescription`,
  `NSCameraUsageDescription`, etc. MUST have a non-empty, human-readable
  string explaining WHY the permission is needed. Generic descriptions
  ("App needs camera access") fail App Store review.
- Android `AndroidManifest.xml` permissions MUST be the minimum
  necessary. `USE_BIOMETRIC` is required for `local_auth` in this
  archetype; `INTERNET` for OIDC; nothing else by default.
- Runtime permission requests on Android (camera, location, etc.) MUST
  be deferred to the moment the user taps the affordance — never on
  app startup. iOS follows the same pattern via prompt-on-use.

## OIDC and Token Storage

The mobile-only archetype enforces PKCE for all OIDC flows. Native
mobile clients MUST NOT ship a client_secret (RFC 8252).

- The OIDC config (`lib/infrastructure/auth/oidc_config.dart`) MUST be
  filled with the adopter's actual issuer / clientId / redirectUri
  before the app is shipped. The scaffold ships with `TODO_REPLACE_*`
  values that intentionally fail at runtime.
- The redirect URI scheme MUST match between `oidc_config.dart`,
  `Info.plist` (LSApplicationQueriesSchemes / URL types), and
  `AndroidManifest.xml` intent-filter. Mismatches lead to silent
  drop-during-redirect failures.
- Tokens MUST be persisted via `flutter_secure_storage` only. NEVER
  use `SharedPreferences`, `NSUserDefaults`, or plain files. The
  Keychain (iOS) / EncryptedSharedPreferences (Android, with StrongBox
  when available) are the only acceptable backings.
- Token refresh MUST be transparent (the app code does not see token
  rotation). The `AuthRepositoryImpl` handles it in `getCurrentToken()`.

## Biometric Lock

The biometric lock widget enforces re-authentication after backgrounding.

- The default timeout is 60 seconds. Adopter MAY tune it via the
  `BiometricLockWidget(timeout: ...)` constructor argument, but MUST
  document the chosen value in their CLAUDE.md.
- `MainActivity` MUST extend `FlutterFragmentActivity` (NOT
  `FlutterActivity`). `local_auth` requires the fragment-hosting
  activity for the biometric prompt. Using `FlutterActivity` results
  in a runtime crash.
- Fallback PIN/passphrase: when the user has no biometric enrolled or
  the hardware is unavailable, the BiometricLockWidget overlay MUST
  show a fallback path (PIN entry). The scaffold provides the overlay
  shell; the adopter implements the PIN UI per their UX system.

## Device Attestation

The archetype provides hooks for App Attest (iOS) and Play Integrity
(Android). The actual cryptographic verification MUST happen on the
backend (out of scope of this archetype). The client side merely
generates and attaches the attestation token to outbound API calls.

- Attestation tokens have a short validity window. NEVER cache them
  beyond a single request.
- The `FakeAttestor` (in `lib/infrastructure/attestation/`) MUST NOT
  be injected in production builds. CI MUST verify via
  static grep that no `FakeAttestor()` reference appears outside
  `test/` and `integration_test/` paths.
- Devices without Play Services (Huawei, certain emulators) report
  `isSupported() == false`. The auth flow MUST tolerate this and
  proceed without the attestation header — the backend decides
  whether to reject unattested devices.

## Native Configuration

- iOS deployment target: **15.0** (App Attest, modern Face ID API).
  Lowering this number disables App Attest and is a security
  regression — discuss with adopter before changing.
- Android `minSdkVersion`: **26** (Android 8). Play Integrity requires
  ≥ 21 ; biometric strict ≥ 23 ; StrongBox preferred path ≥ 28.
- `Podfile` and `build.gradle.kts` MUST pin the deployment target
  EXACTLY ONCE, never per-target. Per-target overrides are a
  maintenance nightmare across CocoaPods upgrades.
- AGP and Gradle versions MUST track Flutter's compatibility matrix.
  Bumping AGP independently is a known break vector — do it via
  `flutter upgrade` first, then verify.

## CI / Fastlane

- Fastlane secrets MUST flow exclusively through environment variables
  (`ENV[...]`). NEVER commit `app_specific_password`, signing keys,
  match passwords, or Play Console JSON keys. The `.envrc.example`
  file documents the variables ; the actual `.envrc` is gitignored.
- iOS code signing MUST use `match` (or `xcodebuild -allowProvisioningUpdates`).
  Manual provisioning is not reproducible.
- Android keystores MUST live outside the project tree (typically in
  a Secrets Manager pulled at CI runtime). The keystore alias and
  password come from `ENV[KEY_ALIAS]` and `ENV[KEY_PASSWORD]`.
- The CI workflow `mobile-ci.yml` runs iOS jobs on `macos-latest` and
  Android jobs on `ubuntu-latest`. The `summary` job is the required
  status check for branch protection.
- Coverage threshold is 70 % (Article X.4 baseline). A drop below
  this number fails the CI summary.

---

## Interdictions

These patterns are forbidden in mobile-only projects under Forge governance.

### Interdiction 1 — Token storage in `SharedPreferences` / `NSUserDefaults`

Any persistence of `access_token`, `refresh_token`, `id_token`, or any
other authentication credential outside `flutter_secure_storage`
(or its native equivalents Keychain / EncryptedSharedPreferences) is
a Constitution Article X violation. Why: these stores are not
encrypted, are readable by any app on a rooted device, and are
backed up to iCloud / Google Drive without user awareness.

### Interdiction 2 — Logging access_token / refresh_token / id_token

`print(token)`, `debugPrint(token)`, `developer.log(token)`, and any
form of structured logging that includes the raw token value is
forbidden. Why: logs aggregate to Sentry / Datadog / Crashlytics ;
once a token leaks to a third-party log aggregator, you must rotate
the credential, force-logout users, and notify per data protection
regulations. Use opaque references (`token.runtimeType`,
`token.expiresAt`) when debugging.

### Interdiction 3 — Bypass biometric in non-debug builds

Code patterns like `if (kDebugMode) skipBiometric = true ;` MUST NOT
ship outside debug profiles. Why: a single shipped build with
biometric bypassed is a credential-theft vector. The biometric
prompt is the security boundary ; weakening it with a debug flag
inevitably leaks via build misconfiguration. If you need a "dev mode"
for local iteration, use a separate flavor / build variant whose
binary never sees production stores.

---

*This standard is referenced by Constitution Article VI (Flutter
Architecture) and Article X (Code Quality). Amendments to its
non-trivial rules (e.g. lowering the iOS deployment target, easing
the biometric requirement) MUST go through the formal amendment
process defined in `GOVERNANCE.md`.*
