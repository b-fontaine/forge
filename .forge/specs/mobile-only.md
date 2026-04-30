# Spec: mobile-only

<!-- Audit: B.4 (b4-mobile-only) — Flutter iOS+Android with OIDC + secure storage + biometric + attestation + Fastlane. -->
<!-- This file accumulates archived requirements for the mobile-only          -->
<!-- archetype. Source change : `.forge/changes/b4-mobile-only/` (archived    -->
<!-- 2026-04-30). First T2 P2 second-archetype delivery.                      -->

**Namespace** : `FR-MO-*` / `NFR-MO-*`.

**Constitution** : v1.1.0 (premier change post-D.5 ratifié sous v1.1.0).

**Plateformes** : iOS `15.0+` (App Attest, Face ID/Touch ID), Android `minSdkVersion = 26` (Play Integrity, biometric strict, StrongBox enclave).

**Validation contrat B.5.1** : extension via 1 entrée `dispatch-table.yml` + 1 wrapper `bin/forge-init-mobile-only.sh`. Zéro édition `cli/src/`.

---

## Functional Requirements (Cluster 1 — Archetype contract)

### FR-MO-001 — Schéma archétype `mobile-only`

`.forge/schemas/mobile-only/schema.yaml` MUST exister, déclarer `archetype: mobile-only`, `schema_version: "1.0.0"`, `layers: [{id: app, path: .}]` (single-layer), `constitution_articles_bound: [I, II, III, IV, V, VI, IX, X, XII]`.

### FR-MO-002 — Templates archétype

`.forge/templates/archetypes/mobile-only/` MUST contenir Flutter project skeleton + iOS native + Android native + observability + tests + Fastlane (per Cluster 9).

### FR-MO-003 — Dispatch table entry

`.forge/scaffolding/dispatch-table.yml` MUST registrer `mobile-only` avec scaffolder `bin/forge-init-mobile-only.sh`, signals `pubspec.yaml + ios/Runner/Info.plist + android/app/build.gradle`, `since: "1.2.0"`. Auto-detection désambiguïse vs `full-stack-monorepo` par absence de `Cargo.toml`.

### FR-MO-004 — Wrapper `bin/forge-init-mobile-only.sh`

Stable ABI B.5.1 : `--target / --project-name / --reverse-domain / --force`. Validation `project-name = [a-z][a-z0-9_]+`, `reverse-domain` FQDN. Refuse target non-vide sans `--force`. Substitution `{{project_name}}` / `{{reverse_domain}}` / `{{reverse_domain_path}}` via `rsync + sed`. Idempotent avec `--force`.

### FR-MO-005 — Snapshot tarball

`.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz` MUST exister, ≤ 2 MB gzipped (NFR-MO-001), produit par `bin/forge-snapshot.sh build mobile-only 1.0.0`.

---

## Functional Requirements (Cluster 2 — Flutter project skeleton)

### FR-MO-006 — `pubspec.yaml.tmpl`

Dépendances pinnées : `flutter_bloc`, `flutter_appauth`, `flutter_secure_storage`, `local_auth`, `opentelemetry_api`, `opentelemetry_sdk`, `equatable`. DevDeps : `flutter_test`, `bloc_test`, `mocktail`, `integration_test`, `gherkin`. Environment : `sdk ">=3.0.0 <4.0.0"`, `flutter ">=3.16.0"`.

### FR-MO-007 — `analysis_options.yaml` strict

Étend `package:flutter_lints/flutter.yaml` + ≥ 5 lints stricts (`prefer_const_constructors`, `unawaited_futures`, `avoid_print`, `prefer_final_locals`, `unnecessary_lambdas`).

### FR-MO-008 — Architecture clean 4 couches

`lib/` : `domain/`, `data/`, `presentation/`, `infrastructure/` (cf. Article VI.6). Chaque couche peuplée (≥ 1 fichier non-vide).

### FR-MO-009 — BDD `.feature` scaffoldé

`integration_test/features/login.feature` Gherkin avec ≥ 1 `Scenario:` (Article II + VI.7).

### FR-MO-010 — `main.dart` + `app.dart` cohérents

`main.dart` : binding init + BlocObserver + OTel init + runApp(App()). `app.dart` : DI graph + BiometricLockWidget enveloppe MaterialApp + BlocProvider AuthBloc.

---

## Functional Requirements (Cluster 3 — iOS native)

### FR-MO-011 — `ios/Runner/Info.plist.tmpl`

`CFBundleIdentifier = {{reverse_domain}}`, `CFBundleDisplayName = {{project_name}}`, `MinimumOSVersion = 15.0`, `NSFaceIDUsageDescription` non-vide, `LSApplicationQueriesSchemes` includes `https`.

### FR-MO-012 — `ios/Podfile.tmpl`

`platform :ios, '15.0'` pinné. Pas de chemin `/Users/` absolu.

### FR-MO-013 — `AppAttestService.swift.tmpl`

Sous `ios/Runner/`, expose MethodChannel `forge.attestation/app_attest`, méthodes `isSupported` + `requestAttestationToken` (génère keyId + attest), utilise `DCAppAttestService.shared`.

---

## Functional Requirements (Cluster 4 — Android native)

### FR-MO-014 — `android/app/build.gradle.kts.tmpl`

`minSdk = 26`, `targetSdk ≥ 34`, `compileSdk ≥ 34`, `applicationId = "{{reverse_domain}}"`, `namespace = "{{reverse_domain}}"`, `viewBinding = true`, dépendance `com.google.android.play:integrity`.

### FR-MO-015 — `AndroidManifest.xml.tmpl`

Permissions `USE_BIOMETRIC` + `INTERNET`. `MainActivity` étend `FlutterFragmentActivity` (REQUIS par `local_auth`). Intent-filter pour OIDC redirect URI custom scheme = `{{reverse_domain}}`.

### FR-MO-016 — `PlayIntegrityService.kt.tmpl`

Sous `android/app/src/main/kotlin/{{reverse_domain_path}}/`, expose MethodChannel `forge.attestation/play_integrity`, utilise `IntegrityManagerFactory.create()` + `IntegrityTokenRequest`.

---

## Functional Requirements (Cluster 5 — OIDC + Auth)

### FR-MO-017 — `oidc_config.dart.tmpl` neutre

Classe `OidcConfig` (issuer/clientId/redirectUri/scopes) + `defaultConfig` avec `TODO_REPLACE_*`. Commentaire en tête référence Auth0, Keycloak, Okta, Cognito.

### FR-MO-018 — `auth_bloc.dart.tmpl`

States `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`. Events `AuthLoginRequested`, `AuthLogoutRequested`, `AuthTokenRefreshRequested`, `AuthBiometricUnlockRequested`. Tests scaffoldés via `bloc_test`.

### FR-MO-019 — `auth_repository.dart` + impl

Interface domain : `login()`, `refresh(refreshToken)`, `logout()`, `getCurrentToken()`. Impl utilise `FlutterAppAuth` + `SecureStorageAdapter` + `DeviceAttestor`. **Aucun token jamais loggé** (no `print(token)` / `debugPrint(token)`).

### FR-MO-020 — `secure_storage_adapter.dart.tmpl`

Wrap `flutter_secure_storage`. iOS = `KeychainAccessibility.first_unlock_this_device`. Android = `EncryptedSharedPreferences` + `useStrongBox` quand dispo.

### FR-MO-021 — Token refresh transparent

`getCurrentToken()` détecte expiry et rafraîchit via `flutter_appauth.token()`. Échec → `clear()` + caller observe `AuthUnauthenticated`.

---

## Functional Requirements (Cluster 6 — Biometric)

### FR-MO-022 — `biometric_service.dart.tmpl`

Wrap `local_auth`. Méthodes `canCheckBiometric()`, `authenticate({reason})`. Options `biometricOnly: true`, `stickyAuth: true`.

### FR-MO-023 — Re-prompt après backgrounding

`biometric_lock_widget.dart.tmpl` implémente `WidgetsBindingObserver`. `paused` enregistre timestamp. `resumed` si delta > timeout (60s défaut, configurable) → overlay `BiometricLockScreen` invoque `BiometricService.authenticate()`.

### FR-MO-024 — Fallback PIN documenté

Standard `flutter-mobile.md` mentionne le pattern fallback PIN/passphrase. Implémentation laissée à l'adopter (UX adopter-specific).

---

## Functional Requirements (Cluster 7 — Attestation)

### FR-MO-025 — Interface `DeviceAttestor`

`lib/domain/attestation/device_attestor.dart` : `requestAttestationToken({nonce})`, `isSupported()`.

### FR-MO-026 — Impl iOS

`lib/infrastructure/attestation/ios_app_attest_attestor.dart` MethodChannel `forge.attestation/app_attest`.

### FR-MO-027 — Impl Android + Fake

`lib/infrastructure/attestation/android_play_integrity_attestor.dart` MethodChannel `forge.attestation/play_integrity`. `fake_attestor.dart` retourne token déterministe (DI tests).

---

## Functional Requirements (Cluster 8 — Observability)

### FR-MO-028 — `otel_init.dart.tmpl`

Initialise `Tracer` + `Meter` via `opentelemetry_sdk` avec OTLP HTTP exporter. Endpoint configurable, défaut `http://localhost:4318`.

### FR-MO-029 — Article IX trace propagation

`auth_repository_impl.dart` instrumente `auth.login`, `auth.refresh`, `auth.logout` via `tracer.startSpan`. Token NE DOIT PAS être attaché aux attributs span.

---

## Functional Requirements (Cluster 9 — Fastlane)

### FR-MO-030 — `fastlane/` structure per-platform

`ios/fastlane/{Fastfile, Appfile, Matchfile}.tmpl` + `android/fastlane/{Fastfile, Appfile}.tmpl`.

### FR-MO-031 — Lanes minimales

iOS : `:beta` (TestFlight), `:release` (App Store manuel), `:screenshots` (snapshot), `:match_setup`. Android : `:beta` (Play Internal), `:release` (Play Production draft), `:screenshots` (screengrab).

### FR-MO-032 — Pas de secrets en clair

Tous les secrets référencent `ENV[...]`. `.envrc.example` documente les ENV vars (MATCH_PASSWORD, APP_STORE_CONNECT_API_KEY_PATH, PLAY_STORE_JSON_KEY, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD, etc.). `.envrc` est `.gitignored`.

---

## Functional Requirements (Cluster 10 — CI workflow)

### FR-MO-033 — `mobile-ci.yml.tmpl`

≥ 3 jobs : `ios` (macos-latest, no codesign), `android` (ubuntu-latest, debug APK + coverage), `summary` (required check). Optionnel `e2e-android` (workflow_dispatch input).

### FR-MO-034 — Coverage threshold

Job `android` MUST collecter `flutter test --coverage` et fail si < 70 % (Article X.4 baseline). Implémenté via `lcov --summary` + awk threshold.

### FR-MO-035 — Cache `~/.pub-cache`

Jobs MUST cacher `~/.pub-cache` clé `pubspec.lock` hash via `actions/cache`.

---

## Functional Requirements (Cluster 11 — Standards)

### FR-MO-036 — `.forge/standards/global/flutter-mobile.md`

Doit contenir 7 H2 sections (Lifecycle and Backgrounding, Permissions, OIDC and Token Storage, Biometric Lock, Device Attestation, Native Configuration, CI / Fastlane) + ≥ 3 Interdictions explicites :
- Interdiction 1 : pas de stockage de token en `SharedPreferences` / `NSUserDefaults`.
- Interdiction 2 : pas de logging d'access_token / refresh_token / id_token.
- Interdiction 3 : pas de bypass biometric en non-debug.

`.forge/standards/index.yml` MUST référencer `global/flutter-mobile` avec triggers `lib/`, `ios/`, `android/`, `oidc`, `biometric`, etc.

---

## Functional Requirements (Cluster 12 — Harness)

### FR-MO-037 — `b4.test.sh`

Pattern manifest. ≥ 35 tests L1 + ≥ 5 tests L2 fixture-based (scaffolder un projet temporaire et vérifier sortie). Découvert par `verify.sh`. Enregistré dans `.github/workflows/forge-ci.yml` job `harness`.

---

## Functional Requirements (Cluster 13 — Intégrations)

### FR-MO-038 — `framework-owned-paths.yml.tmpl` archétype

`.forge/templates/archetypes/mobile-only/.forge/framework-owned-paths.yml.tmpl` liste les paths archétype-spécifiques (oidc_config.dart, otel_init.dart, AppAttestService.swift, PlayIntegrityService.kt, mobile-ci.yml, Fastfile, etc.) que `forge upgrade` doit 3-way-merger. Cohérent avec ADR-014 (framework-side reste agnostique).

### FR-MO-039 — `docs/ARCHETYPES.md` mis à jour

Nouvelle ligne `mobile-only` Active dans la matrice de décision avec persona, when-to-pick, stack, since 1.2.0, lien spec.

### FR-MO-040 — Périmètre négatif

Le change `b4-mobile-only` NE DOIT PAS toucher `cli/src/**`, `.forge/schemas/full-stack-monorepo/**`, `.forge/templates/archetypes/full-stack-monorepo/**` (sauf via D.5 déjà commité), `.forge/constitution.md`, ni les changes archivés. Vérifié automatiquement par `_test_b4_042` (baseline = parent du premier commit b4).

---

## Non-Functional Requirements

### NFR-MO-001 — Snapshot ≤ 2 MB gzipped

Mesuré post-archive : **465 KB gzipped** (23 % du budget). Hard limit 5 MB.

### NFR-MO-002 — Scaffold ≤ 5 s

`forge init --archetype mobile-only --target <dir>` complète en ≤ 5 s sur MacBook M-series. Hard limit 15 s.

### NFR-MO-003 / 004 / 005 — Post-scaffold Flutter

Sur projet scaffoldé : `flutter pub get` + `flutter analyze` + `flutter test` retournent exit 0. Vérifié en L3 opt-in (`--require-flutter`), non bloquant en CI Forge core.

### NFR-MO-006 — Aucune dep `cli/`

Zéro nouveau package dans `cli/package.json` (preuve par construction du contrat B.5.1).

### NFR-MO-007 — Compatible `forge upgrade` (A.7)

`a7.test.sh` reste vert (29/29) après livraison de B.4. Pas de régression.

### NFR-MO-008 — 100 % FR couverts

Chaque FR-MO-NNN a ≥ 1 test L1 ou L2 dans `b4.test.sh`. Vérifié au manifest.

---

## Acceptance Criteria (BDD)

7 scénarios documentés dans `.forge/changes/b4-mobile-only/specs.md`§ "Acceptance Criteria (BDD)" :

1. Adopter scaffolde un projet mobile-only (commande + structure produite + flutter analyze OK).
2. User OIDC login happy path (PKCE flow, token persisté, no log).
3. Token refresh transparent (auto-detection expiry → AppAuth → re-store ou clear).
4. Biometric unlock après backgrounding (lifecycle observer, overlay, fallback).
5. Attestation token attaché aux API calls (DeviceAttestor → header X-Device-Attestation).
6. CI sur PR (paths-filter ios/+lib/+android/, summary required).
7. `forge upgrade` préserve customisations adopter (3-way merge sur framework-owned-paths).

---

## Constitution Compliance Summary

- **Article I (TDD)** : `b4.test.sh` 47 tests, RED→GREEN par phase. ✅
- **Article II (BDD)** : `login.feature` Gherkin scaffoldé. ✅
- **Article III (Specs Before Code)** : pipeline complet exécuté en 3 phases. ✅
- **Article III.4 (Anti-hallucination)** : 3 décisions tranchées (iOS 15.0/Android 26, OIDC neutre, snapshot pré-build). ✅
- **Article IV (Delta-based)** : ADDED-only. ✅
- **Article V (Process Gates)** : pipeline complet, 3 commits par phase. ✅
- **Article VI (Flutter)** : `flutter_bloc` (FR-MO-018), clean arch 4 couches (FR-MO-008), cucumber-flutter (FR-MO-009). ✅
- **Article VII / VIII / XI** : NA. ✅
- **Article IX (Observability)** : OTel SDK + spans auth (FR-MO-028, FR-MO-029). ✅
- **Article X (Quality)** : analysis_options strict, coverage 70 %, secrets via ENV, no token logging. ✅
- **Article XII (Governance)** : `constitution_version: "1.1.0"` dans `.forge.yaml`. ✅
