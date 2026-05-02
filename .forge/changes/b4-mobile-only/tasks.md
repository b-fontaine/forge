# Tasks: b4-mobile-only

**Pipeline** : RED → GREEN incrémental par phase. ADR-013 split en **3 phases** (A, B, C) avec **1 commit par phase** sur `optim`.

**Volume cible** : ~40 tâches groupées en 3 phases. **Multi-session** assumé (XL effort).

**Précondition** : Constitution v1.1.0 active (post-D.5). Le `.forge.yaml` du change déjà à `constitution_version: "1.1.0"`.

---

## Phase A — Core scaffold structure

**Objectif** : structure d'archétype + dispatcher integration + snapshot. Aucune logique runtime Flutter (juste les placeholders syntaxiquement valides).

**Sortie attendue** : `bin/forge-init-mobile-only.sh --target /tmp/foo --project-name foo --reverse-domain com.example.foo` produit un projet qui passe `flutter analyze` sur les fichiers vides présents (les modules runtime arrivent en Phase B).

### A.1 — Harness RED

- [ ] **T001** Créer `.forge/scripts/tests/b4.test.sh` (executable, pattern manifest, sourcing `_helpers.sh`). Implémenter ~20 fonctions `_test_b4_NNN` couvrant FR-MO-001 à FR-MO-016 + FR-MO-038, FR-MO-039 (skeleton + iOS + Android + dispatch + wrapper + snapshot). Inclure le flag `--level 1,2` (cohérent avec scaffolder.test.sh) ; en Phase A, seul `--level 1` matter. [Story: FR-MO-037]
- [ ] **T002** Lancer `bash .forge/scripts/tests/b4.test.sh --level 1` — vérifier RED : ~20 FAIL, 0 PASS. Capturer le compteur initial. [Article I gate]

### A.2 — Schéma + dispatcher

- [ ] **T003** Créer `.forge/schemas/mobile-only/schema.yaml` : `archetype: mobile-only`, `schema_version: "1.0.0"`, `description`, `layers: [{id: app, path: .}]`, `constitution_articles_bound: [I, II, III, IV, V, VI, IX, X, XII]`. [Story: FR-MO-001]
- [ ] **T004** Créer `bin/forge-init-mobile-only.sh` (wrapper bash, ABI B.5.1 stable : `--target / --project-name / --reverse-domain / --force`). Implémenter rsync + sed substitution `{{project_name}}` et `{{reverse_domain}}`. Calcul `reverse_domain_path` (slash-separated) pour le path Kotlin. `chmod +x`. [Story: FR-MO-004]
- [ ] **T005** Ajouter l'entrée `mobile-only` dans `.forge/scaffolding/dispatch-table.yml` avec signals `pubspec.yaml`, `ios/Runner/Info.plist`, `android/app/build.gradle`, `since: "1.2.0"`. [Story: FR-MO-003]

### A.3 — Templates Flutter skeleton (placeholders syntaxiques, pas de logique runtime)

- [ ] **T006** Créer `.forge/templates/archetypes/mobile-only/` avec : `pubspec.yaml.tmpl` (placeholders + dépendances pinnées : `flutter_bloc`, `flutter_appauth`, `flutter_secure_storage`, `local_auth`, `opentelemetry_api`, `opentelemetry_sdk`, `equatable` ; devDependencies : `flutter_test`, `bloc_test`, `mocktail`, `integration_test`, `gherkin`). [Story: FR-MO-006]
- [ ] **T007** Templates supports : `analysis_options.yaml` (extends flutter_lints + 5 lints stricts), `.gitignore`, `README.md.tmpl` (placeholders), `CLAUDE.md.tmpl` (scope Flutter mobile), `.forge.yaml.tmpl` (déclare `schema: mobile-only`, `constitution_version: "1.1.0"`). [Story: FR-MO-007]
- [ ] **T008** Squelette `lib/` 4 couches placeholder vides mais syntaxiquement valides : `lib/main.dart.tmpl` (minimal, runApp), `lib/app.dart.tmpl` (stub MaterialApp), `lib/domain/.gitkeep`, `lib/data/.gitkeep`, `lib/presentation/.gitkeep`, `lib/infrastructure/.gitkeep`, `lib/observability/.gitkeep`. [Story: FR-MO-008]
- [ ] **T009** Templates tests scaffoldés vides : `test/widget_test.dart.tmpl` (stub testant `App()` se construit), `integration_test/app_test.dart.tmpl`, `integration_test/features/login.feature.tmpl` (Gherkin minimal `Feature: OIDC login` + 1 Scenario stub). [Story: FR-MO-009]

### A.4 — Templates iOS natif

- [ ] **T010** `ios/Runner/Info.plist.tmpl` avec `CFBundleIdentifier={{reverse_domain}}`, `CFBundleDisplayName={{project_name}}`, `MinimumOSVersion=15.0`, `NSFaceIDUsageDescription` (string fr/en non-vide), `LSApplicationQueriesSchemes` includes `https`. [Story: FR-MO-011]
- [ ] **T011** `ios/Podfile.tmpl` (`platform :ios, '15.0'`, hooks Flutter standards, pas de chemin absolu) + `ios/Runner/AppDelegate.swift.tmpl` minimal (stub Flutter standard ; les services natifs viennent en Phase B). [Story: FR-MO-012]

### A.5 — Templates Android natif

- [ ] **T012** `android/app/build.gradle.kts.tmpl` (minSdk 26, targetSdk 34, compileSdk 34, viewBinding=true, applicationId={{reverse_domain}}, namespace={{reverse_domain}}). Note : la dépendance Play Integrity est ajoutée en Phase B avec son hook Kotlin. [Story: FR-MO-014]
- [ ] **T013** `android/app/src/main/AndroidManifest.xml.tmpl` (permissions USE_BIOMETRIC + INTERNET, MainActivity étend `FlutterFragmentActivity`, intent-filter pour OIDC redirect URI custom scheme). [Story: FR-MO-015]
- [ ] **T014** `android/app/src/main/kotlin/{{reverse_domain_path}}/MainActivity.kt.tmpl` (étend `FlutterFragmentActivity`, stub minimal — l'enregistrement de PlayIntegrityService viendra en Phase B). Templates root : `android/build.gradle.kts.tmpl`, `android/settings.gradle.kts.tmpl`, `android/gradle.properties.tmpl`. [Story: FR-MO-014, FR-MO-015]

### A.6 — Snapshot + harness GREEN Phase A

- [ ] **T015** Construire le snapshot tarball Phase A : `bin/forge-snapshot.sh build mobile-only 1.0.0`. Vérifier taille ≤ 2 MB gzipped (NFR-MO-001). [Story: FR-MO-005]
- [ ] **T016** Lancer `bash .forge/scripts/tests/b4.test.sh --level 1` — vérifier ~20/20 GREEN. Lancer `bash .forge/scripts/tests/b4.test.sh --level 1,2` — vérifier ≥ 5 tests L2 GREEN (scaffolder produit l'arborescence attendue, idempotent avec `--force`, refuse non-vide sans `--force`). [Story: FR-MO-037]
- [ ] **T017** Lancer `bash .forge/scripts/verify.sh` global + tous les harnais (`foundations`, `scaffolder`, `workflow`, `delivery`, `g1`, `c1`, `a7`, `b5`, `d5`) — vérifier zéro régression. Lancer `bash .forge/scripts/tests/a7.test.sh` spécifiquement (NFR-MO-007). [Article V gate]

### A.7 — Commit Phase A

- [ ] **T018** Stage les fichiers Phase A (schéma + wrapper + dispatch entry + templates skeleton + iOS/Android natif + harness + snapshot tarball). Ne PAS stager les fichiers pré-existants modifiés par d'autres workflows. Commit Phase A avec message dédié. Push vers `origin/optim`. [Article V gate]

**Constitutional check Phase A** : ✅ Article I (RED→GREEN), ✅ Article VI (clean arch placeholders en place), ✅ Article XII (constitution_version 1.1.0 dans le `.forge.yaml.tmpl` archétype).

---

## Phase B — Runtime + standards

**Objectif** : remplir les modules runtime (OIDC, secure storage, biometric, attestation, observability), bridges natifs, standard `flutter-mobile.md`.

**Sortie attendue** : un projet scaffoldé avec Phase B passe `flutter pub get` (NFR-MO-003) et `flutter analyze` (NFR-MO-004) — opt-in en L3.

### B.1 — Harness RED Phase B

- [ ] **T019** Étendre `b4.test.sh` avec ~15 tests supplémentaires couvrant FR-MO-017 à FR-MO-029 + FR-MO-036 (OIDC config, auth bloc, secure storage, biometric, attestation x3, observability, standards `flutter-mobile.md` + index.yml trigger). Lancer `b4.test.sh --level 1` — vérifier ~15 nouveaux FAIL. [Article I gate]

### B.2 — OIDC + Auth (clean arch 4 couches)

- [ ] **T020** `lib/infrastructure/auth/oidc_config.dart.tmpl` avec classe `OidcConfig` + `defaultConfig` constants `TODO_REPLACE_*` + commentaire en tête pointant Auth0/Keycloak/Okta/Cognito (ADR-003). [Story: FR-MO-017]
- [ ] **T021** `lib/domain/auth/auth_repository.dart.tmpl` (interface : `login()`, `refresh(refreshToken)`, `logout()`, `getCurrentToken()`, types `AuthToken` Equatable). [Story: FR-MO-019]
- [ ] **T022** `lib/data/auth/auth_repository_impl.dart.tmpl` (utilise `FlutterAppAuth` + `SecureStorageAdapter` + `DeviceAttestor`, ne logge JAMAIS le token). Test scaffold : `test/data/auth/auth_repository_impl_test.dart.tmpl` avec mocktail. [Story: FR-MO-019, FR-MO-021]
- [ ] **T023** `lib/presentation/auth/auth_bloc.dart.tmpl` (states + events + transitions selon FR-MO-018). Test scaffold : `test/presentation/auth/auth_bloc_test.dart.tmpl` avec bloc_test. [Story: FR-MO-018, FR-MO-021]

### B.3 — Secure storage

- [ ] **T024** `lib/infrastructure/storage/secure_storage_adapter.dart.tmpl` wrapper `flutter_secure_storage` (iOS `KeychainAccessibility.first_unlock_this_device`, Android `EncryptedSharedPreferences` + `useStrongBox=true` quand dispo). [Story: FR-MO-020]

### B.4 — Biometric

- [ ] **T025** `lib/infrastructure/biometric/biometric_service.dart.tmpl` wrapper `local_auth` (`canCheckBiometric()`, `authenticate({reason})`, `biometricOnly=true`, `stickyAuth=true`). [Story: FR-MO-022]
- [ ] **T026** `lib/presentation/biometric/biometric_lock_widget.dart.tmpl` (WidgetsBindingObserver, timeout configurable défaut 60s, overlay BiometricLockScreen, fallback PIN documenté en commentaire — pas implémenté, c'est adopter-specific). Wrapper de `MaterialApp` dans `lib/app.dart.tmpl`. [Story: FR-MO-023]

### B.5 — Attestation (cross-cutting)

- [ ] **T027** `lib/domain/attestation/device_attestor.dart.tmpl` (interface `requestAttestationToken({nonce})`, `isSupported()`). [Story: FR-MO-025]
- [ ] **T028** `lib/infrastructure/attestation/ios_app_attest_attestor.dart.tmpl` + `android_play_integrity_attestor.dart.tmpl` + `fake_attestor.dart.tmpl` (DI test-friendly). MethodChannel names `forge.attestation/app_attest` et `forge.attestation/play_integrity`. [Story: FR-MO-026, FR-MO-027]
- [ ] **T029** Bridge iOS : `ios/Runner/AppAttestService.swift.tmpl` (utilise `DCAppAttestService`, expose `generateKey`, `attestKey`, `assert`). Mettre à jour `AppDelegate.swift.tmpl` pour enregistrer le service. [Story: FR-MO-013]
- [ ] **T030** Bridge Android : `android/app/src/main/kotlin/{{reverse_domain_path}}/PlayIntegrityService.kt.tmpl` (utilise `IntegrityManager`). Mettre à jour `MainActivity.kt.tmpl` pour enregistrer le service. Ajouter dépendance Play Integrity dans `build.gradle.kts.tmpl`. [Story: FR-MO-016]

### B.6 — Observability (Article IX)

- [ ] **T031** `lib/observability/otel_init.dart.tmpl` (Tracer + Meter via opentelemetry_sdk, OTLP exporter, endpoint configurable défaut `http://localhost:4318`). [Story: FR-MO-028]
- [ ] **T032** Instrumenter `auth_repository_impl.dart.tmpl` avec spans `auth.login`, `auth.refresh`, `auth.logout` (ne pas logger valeur token). [Story: FR-MO-029]

### B.7 — main.dart + app.dart cohérents

- [ ] **T033** `lib/main.dart.tmpl` final : init BlocObserver, init OTel, runApp(App()). `lib/app.dart.tmpl` final : DI graph (provide AuthRepository, BiometricService, DeviceAttestor) + BiometricLockWidget englobe MaterialApp + BlocProvider AuthBloc. [Story: FR-MO-010]

### B.8 — Standard `flutter-mobile.md`

- [ ] **T034** Créer `.forge/standards/global/flutter-mobile.md` avec 7 sections H2 (Lifecycle, Permissions, OIDC and Token Storage, Biometric Lock, Device Attestation, Native Configuration, CI / Fastlane) + ≥ 3 Interdictions. [Story: FR-MO-036]
- [ ] **T035** Mettre à jour `.forge/standards/index.yml` avec entrée `flutter-mobile.md` + triggers paths `lib/`, `ios/`, `android/`, `pubspec.yaml`, `Fastfile`. [Story: FR-MO-036]

### B.9 — Snapshot rebuild + harness GREEN Phase B

- [ ] **T036** Reconstruire le snapshot : `bin/forge-snapshot.sh build mobile-only 1.0.0` (overwrite). Vérifier taille reste ≤ 2 MB gzipped. [Story: FR-MO-005, NFR-MO-001]
- [ ] **T037** Lancer `b4.test.sh --level 1,2` — vérifier total ~35/35 GREEN. Lancer `verify.sh` global + 9 harnais existants — zéro régression. [Article V gate]

### B.10 — Commit Phase B

- [ ] **T038** Stage Phase B (tous les fichiers Dart + Swift + Kotlin templates + standard + index.yml + snapshot rebuild). Commit + push. [Article V gate]

**Constitutional check Phase B** : ✅ Article I, ✅ Article II (login.feature scaffoldé), ✅ Article VI (4 couches peuplées + flutter_bloc actif + cucumber-flutter), ✅ Article IX (OTel câblé), ✅ Article X (no token logging vérifié par grep dans le harness).

---

## Phase C — Fastlane + CI + archive

**Objectif** : pipelines store + workflow CI + archive complète.

### C.1 — Harness RED Phase C

- [ ] **T039** Étendre `b4.test.sh` avec ~5 tests Phase C (FR-MO-030 à FR-MO-035 + FR-MO-040 périmètre négatif via `git diff` audit manuel). Lancer harness — vérifier ~5 nouveaux FAIL. [Article I gate]

### C.2 — Fastlane templates

- [ ] **T040** Créer `.forge/templates/archetypes/mobile-only/ios/fastlane/{Fastfile,Appfile,Matchfile,Pluginfile}.tmpl` avec lanes `beta` (TestFlight), `release` (App Store, manuel), `screenshots` (snapshot run), `match_setup`. Tous les secrets référencent `ENV[...]`. [Story: FR-MO-030, FR-MO-031, FR-MO-032]
- [ ] **T041** Créer `.forge/templates/archetypes/mobile-only/android/fastlane/{Fastfile,Appfile,Pluginfile}.tmpl` avec lanes `beta` (Play Internal), `release` (Play prod), `screenshots` (screengrab). Secrets via ENV. [Story: FR-MO-030, FR-MO-031, FR-MO-032]
- [ ] **T042** Créer `.forge/templates/archetypes/mobile-only/.envrc.example` documentant toutes les variables ENV requises (APP_STORE_CONNECT_API_KEY_PATH, MATCH_PASSWORD, PLAY_STORE_JSON_KEY, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD, etc.). [Story: FR-MO-032]

### C.3 — CI workflow

- [ ] **T043** Créer `.forge/templates/archetypes/mobile-only/.github/workflows/mobile-ci.yml.tmpl` (jobs `ios` macos-latest, `android` ubuntu-latest, `summary` required, `e2e-android` opt-in via workflow_dispatch). Cache `~/.pub-cache`. Coverage 70 % seuil. [Story: FR-MO-033, FR-MO-034, FR-MO-035]
- [ ] **T044** Mettre à jour `.github/workflows/forge-ci.yml` (job `harness`) pour enregistrer `b4.test.sh --level 1,2` après `d5.test.sh`. [Story: FR-MO-037]

### C.4 — Documentation + framework-owned-paths

- [ ] **T045** Mettre à jour `docs/ARCHETYPES.md` matrice de décision : ajouter ligne `mobile-only` avec colonnes (Use case, Frontend, Backend, Infra, Auth, Storage, CI/CD, When to use). [Story: FR-MO-039]
- [ ] **T046** Créer `.forge/templates/archetypes/mobile-only/.forge/framework-owned-paths.yml.tmpl` listant les paths archétype-spécifiques (lib/observability/otel_init.dart, lib/infrastructure/auth/oidc_config.dart, etc. — paths que les upgrades futurs DOIVENT 3-way merger). ADR-014. [Story: FR-MO-038]

### C.5 — Snapshot final + verify global

- [ ] **T047** Reconstruire le snapshot final : `bin/forge-snapshot.sh build mobile-only 1.0.0`. Confirmer taille ≤ 2 MB gzipped. [Story: FR-MO-005]
- [ ] **T048** Lancer `b4.test.sh --level 1,2` final — vérifier ~40/40 GREEN. Lancer `verify.sh` global. Lancer **chaque** des 10 harnais (foundations à b4) — vérifier zéro régression. Cible : 187 + ~40 = ~227 tests sur 10 harnais. [Article V gate]
- [ ] **T049** Audit FR-MO-040 (périmètre négatif) : `git diff --name-only main...HEAD` NE DOIT PAS lister de fichiers sous `cli/src/`, `.forge/schemas/full-stack-monorepo/`, `.forge/templates/archetypes/full-stack-monorepo/` (sauf `.forge.yaml.tmpl` si déjà bumpé en D.5), ni de fichiers de changes archivés. [Story: FR-MO-040]

### C.6 — Spec consolidée + admin archive

- [ ] **T050** Créer `.forge/specs/mobile-only.md` consolidant FR-MO-001..040 + NFR-MO-001..008 + 7 BDD scenarios. En-tête référence le change source `b4-mobile-only` + date d'archive. [Story: ADR-008 design]
- [ ] **T051** Mettre à jour `.forge/product/roadmap.md` : marquer B.4 ✅ Done en T2 P2. **T2 P2 désormais complet** = guard-rail PR/release peut être levée. [Story: project tracking]
- [ ] **T052** Mettre à jour `/Users/bfontaine/.claude/plans/il-s-agit-l-d-un-noble-gem.md` : 4-6 emplacements (header, Section 7 T2/T3, conclusion, item B.4) — marquer B.4 ✅ Livré T2, bascule T2 P2 → complet, signaler que la PR `optim → main` + release v0.3.x sont **désormais autorisées** (à la discrétion utilisateur). [Story: project tracking]
- [ ] **T053** Mettre à jour `CHANGELOG.md` `[Unreleased]` : ajouter une entrée `### Added — b4-mobile-only` détaillant les livraisons (schéma, templates, OIDC, biometric, attestation, OTel, Fastlane, CI, standard, harness). **Ne pas sceller** la version (reste `[Unreleased]`) tant que l'utilisateur n'a pas explicitement demandé la release v0.3.x. [Story: project tracking]
- [ ] **T054** Flip `.forge/changes/b4-mobile-only/.forge.yaml` : `status: archived`, ajouter `timeline.implemented` + `timeline.archived` à `2026-04-30`. [Article V gate]

### C.7 — Commit Phase C

- [ ] **T055** Stage Phase C (Fastlane templates + CI workflow + ARCHETYPES.md + framework-owned-paths.yml.tmpl + snapshot rebuild + spec consolidé + roadmap + CHANGELOG + plan d'audit + .forge.yaml status flip). Commit avec message `release(forge): b4-mobile-only archived — second archetype, mobile-only Flutter iOS+Android`. Push vers `origin/optim`. [Article V gate]

**Constitutional check Phase C** : ✅ tous articles respectés. ✅ Article XII — premier change archivé sous Constitution v1.1.0, validation pratique des bumps de templates effectués en D.5.

---

## Constitutional Compliance Gate (sweep final)

| Phase | Tâches | Article violé ? |
|---|---|---|
| Phase A | T001-T018 | Aucun. RED-first respecté (Article I). Single-layer ADR-001 conforme Article VI.6. |
| Phase B | T019-T038 | Aucun. flutter_bloc obligatoire (T023). Clean arch 4 couches (T020-T032). OTel (T031-T032). |
| Phase C | T039-T055 | Aucun. CI gate (T043-T044). Archive admin (T050-T054). Périmètre négatif validé (T049). |

**Aucun `[TASK VIOLATION:]`.**

---

## Risk Register (issu de design.md)

À surveiller pendant l'exécution :

1. **Drift versions Flutter packages** → résoudre versions à T006 via Context7.
2. **Substitution sed sur binaire** → s'assurer que les assets binaires ne soient JAMAIS suffixés `.tmpl`.
3. **Conflits attestation sur émulateur** → FakeAttestor (T028) + warn log.
4. **Snapshot > budget** → mesure à T015, T036, T047.
5. **Secret hardcodé Fastlane** → grep enforcement à T040-T041.
6. **`flutter analyze` sur TODO_REPLACE_*** → utiliser chaînes `String` sans interpolation, pas de const ; documenté.
7. **Régression a7.test.sh** → vérification explicite à T017, T037, T048.
8. **L2 flaky** → normaliser via `find ... -print0 | sort -z`.

---

**Status** : `planned`. Next : `/forge:implement b4-mobile-only` (Phase A).

**Mode d'exécution** : multi-session (XL). Phase A en première session, attendre validation utilisateur avant Phase B, puis Phase C.

**Important** : la **guard-rail PR optim → main / release v0.3.x reste active** jusqu'à la fin de Phase C (T2 P2 complet). Ce n'est qu'après commit Phase C que la guard-rail peut être levée.
