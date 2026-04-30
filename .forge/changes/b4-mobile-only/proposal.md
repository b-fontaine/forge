# Proposal: b4-mobile-only

> **Premier change ratifié sous Constitution v1.1.0** (Article XII Governance
> en vigueur depuis 2026-04-30 via `d5-governance`).

## Problem

Forge ne couvre aujourd'hui qu'**un seul archétype premium** : `full-stack-monorepo`
(Flutter front + Rust back + Infra). Cela exclut une **catégorie majeure
d'équipes** :

- Les équipes **mobile-natives** (iOS + Android, pas de version web/desktop)
- Avec leur **propre backend** (Rust/Go/Python ailleurs, pas de besoin
  d'inclure le backend dans l'archétype)
- Utilisant un **OIDC externe** (Auth0 / Keycloak / Okta / Cognito), pas de
  BaaS Firebase
- Avec exigences **mobile-first** : secure token storage (Keychain /
  Keystore), biometric lock (Face ID / Touch ID / fingerprint),
  attestation device (App Attest / Play Integrity), pipelines store
  (Fastlane), gestion des permissions runtime, lifecycle background

Cette équipe-cible **ne peut pas** utiliser `full-stack-monorepo` :

1. Elle n'a pas besoin du backend Rust → bruit
2. Elle n'a pas besoin de l'infra Kustomize → bruit
3. Le scaffold Flutter de FSM est web-friendly (pas iOS/Android-first)
4. Pas de configuration native iOS/Android dédiée (Info.plist,
   AndroidManifest.xml, Podfile pinning, AGP/Gradle alignment)
5. Pas de scaffold OIDC-AppAuth + secure storage + biometric

Conséquence : **segment XL non couvert** — les équipes mobile-natives sont
forcées de copier-coller des morceaux de l'écosystème Flutter (Very Good
CLI, Mason bricks, recettes Medium) sans respecter la discipline Forge.

Module **B.4** sur la roadmap Phase 3, marqué comme dépendant de **B.1**
(scaffolder infra, ✅ livré) et **B.5.1** (wizard multi-archétype, ✅ livré).
Identifié comme priorité **T2 P2 = second archétype** dans le plan d'audit.

C'est aussi le **premier vrai test** de l'extensibilité du dispatcher
B.5.1 : ajouter B.4 = 1 entrée dans `dispatch-table.yml` + 1 wrapper
`bin/forge-init-mobile-only.sh`, **zéro édition TS**. Si ce contrat ABI
ne tient pas, B.5.1 a un défaut conceptuel à corriger avant B.2 et B.3.

## Solution

Livrer un **archétype mobile-only** alignement Flutter iOS+Android complet,
indépendant de tout backend, avec OIDC externe, secure storage,
biometric, attestation, et pipelines Fastlane.

### Composants livrés

1. **Schéma archétype** `.forge/schemas/mobile-only/schema.yaml`
   - Layers : `app` (single-layer Flutter) — pas de `backend`/`frontend`/`infra`
   - schema_version : `1.0.0`
   - Constitution-bound (Articles I, II, VI, IX, X)
2. **Templates archétype** `.forge/templates/archetypes/mobile-only/`
   - Flutter project skeleton (lib/, test/, integration_test/)
   - iOS native config (ios/Runner/Info.plist, ios/Podfile pinning)
   - Android native config (android/app/build.gradle.kts AGP pinning,
     android/app/src/main/AndroidManifest.xml permissions)
   - CLAUDE.md.tmpl scoping le contexte Flutter mobile
3. **OIDC + secure storage** sous forme de modules pré-câblés mais
   désactivables :
   - `flutter_appauth` pour OIDC (browser-based PKCE flow, pas de
     client_secret embarqué)
   - `flutter_secure_storage` pour token storage
     (Keychain/Keystore-backed)
   - Une couche d'abstraction `auth/` (interface + impl OIDC) avec
     fakes pour tests + golden tests pour les écrans login/refresh
4. **Biometric lock** :
   - `local_auth` pour Face ID / Touch ID / Android biometric
   - Pattern : déverrouillage app (re-prompt après timeout, fallback
     PIN/passphrase)
5. **Attestation device** :
   - Hooks **App Attest** (iOS, attest token attached to API calls)
   - Hooks **Play Integrity** (Android, equivalent)
   - Layer abstraction "device-attestor" qui retourne un token attaché
     aux requêtes ; impl optionnelles par OS, fakes pour tests
6. **Pipelines store** :
   - `fastlane/` au niveau iOS et Android
   - `Fastfile` avec lanes : `beta` (TestFlight / Play Internal),
     `release` (App Store / Play prod), `screenshots` (génération
     automatique), `match` (iOS code signing)
7. **CI workflow** `mobile-ci.yml.tmpl` template :
   - Job iOS (macOS runner) : `flutter analyze`, `flutter test`,
     `flutter build ios --no-codesign`
   - Job Android (ubuntu runner) : `flutter analyze`, `flutter test`,
     `flutter build apk --debug`, optionally `aab` for release branch
   - Job e2e (intégration test sur émulateur Android, opt-in)
8. **Wrapper dispatcher** `bin/forge-init-mobile-only.sh` :
   - Stable ABI declared by B.5.1 (`--target`, `--project-name`,
     `--reverse-domain`, `--force`)
   - Translate to internal scaffolder logic (rsync templates +
     substitute placeholders)
9. **Entrée dispatch table** `.forge/scaffolding/dispatch-table.yml` :
   - Nom : `mobile-only`
   - Scaffolder : `bin/forge-init-mobile-only.sh`
   - Signals : `pubspec.yaml` + absence de `Cargo.toml` ET absence
     de `infra/` (heuristique de désambiguïsation vs
     full-stack-monorepo)
   - `since: "1.2.0"` (B.4 est la première feature de la prochaine
     mineure framework)
10. **Standards** :
    - Nouveau `.forge/standards/global/flutter-mobile.md` —
      conventions iOS/Android natifs, lifecycle, permissions, app
      backgrounding, secure storage, OIDC PKCE, biometric, attestation
    - Mise à jour `.forge/standards/index.yml` avec triggers
      (`flutter-mobile.md` activé sur paths `lib/`, `ios/`, `android/`,
      `pubspec.yaml`)
11. **Spec consolidée** `.forge/specs/mobile-only.md` (post-archive),
    namespace `FR-MO-*` + `NFR-MO-*`
12. **Harness `b4.test.sh`** (pattern manifest, tests structurels L1
    + tests fixture-based L2) — minimum 1 test par FR-MO-*

### Constitution Compliance — Article XII (premier usage)

D.5 a institué le processus d'amendement formel. B.4 ne touche **pas** à
la Constitution (zéro amendement requis). En revanche, B.4 **enregistre
sous Constitution v1.1.0** : son `.forge.yaml` déclare
`constitution_version: "1.1.0"`, conformément au template fraîchement
bumpé.

C'est le premier change post-D.5 et le test pratique que les bumps
de templates fonctionnent : un nouvel archétype créé maintenant
produit un `.forge.yaml` à `1.1.0` automatiquement.

## Scope In

- Schéma archétype `mobile-only` (single-layer `app`)
- Templates Flutter iOS + Android avec config native (Info.plist,
  AndroidManifest.xml, Podfile, build.gradle.kts pinnings)
- Modules OIDC (`flutter_appauth` + abstraction `auth/`)
- Modules secure storage (`flutter_secure_storage`)
- Modules biometric (`local_auth`)
- Modules attestation (App Attest + Play Integrity hooks abstraits)
- Pipelines Fastlane (Fastfile + Appfile + Matchfile templates)
- CI workflow GitHub Actions (`mobile-ci.yml.tmpl`)
- Wrapper `bin/forge-init-mobile-only.sh` (ABI B.5.1)
- Entrée dispatch table avec auto-detection signals + désambiguïsation
- Standards `flutter-mobile.md` (lifecycle / permissions /
  background / OIDC / biometric / attestation)
- Spec consolidée `.forge/specs/mobile-only.md`
- Harness `b4.test.sh` (L1 + L2)
- Documentation `docs/ARCHETYPES.md` mise à jour (matrice de décision
  inclut désormais 3 archétypes actifs au lieu de 2)
- Mise à jour CI `forge-ci.yml` pour enregistrer `b4.test.sh`
- Mise à jour `CHANGELOG.md` `[Unreleased]`
- Mise à jour roadmap `.forge/product/roadmap.md` (B.4 ✅ Done,
  bascule T2 P2 → fini)
- Mise à jour plan d'audit `il-s-agit-l-d-un-noble-gem.md`

## Scope Out (Explicit Exclusions)

- **Backend** — B.4 est mobile-only, ne livre PAS de scaffold
  backend. Si un projet adopte B.4 ET veut un backend, il fait
  cohabiter deux dépôts (mobile + backend séparé) ou utilise B.1
  full-stack-monorepo à la place.
- **B.2 flutter-firebase** — Firebase BaaS n'est PAS scope B.4.
  B.4 est explicitement OIDC externe + backend tiers, pas BaaS.
- **B.3 rust-cli-tui** — distinct, livraison séparée.
- **Fastlane match repo configuration** — la **structure** de
  Fastlane est livrée (Fastfile, Appfile, Matchfile templates),
  mais la config de `match` (URL du repo de certs, secrets) reste
  à l'adopter.
- **App Attest / Play Integrity backend verification** — l'archétype
  livre les **hooks côté client** (token génération + attachement
  aux requêtes). La **vérification serveur** est hors scope (le
  backend est externe).
- **Tests d'intégration sur device physique** — opt-in CI sur
  émulateur Android. Tests sur device physique iOS = effort
  outsized vs valeur ajoutée pour un template.
- **Push notifications, deep links, analytics** — modules optionnels
  laissés à l'adopter (chaque éditeur OIDC ou MDM a son SDK).
- **Multi-language i18n** — ARB scaffold présent (un seul template
  `app_en.arb` + `app_fr.arb`), mais zéro localisation poussée.
- **Migration des projets existants** — pas de tooling de migration
  d'un projet Flutter "à la main" vers `mobile-only`. `forge
  upgrade` (A.7) ne couvre que les projets DÉJÀ scaffoldés via Forge.
- **State management impose** — la Constitution Article VI exige
  flutter_bloc. B.4 livre un exemple `auth_bloc.dart` mais ne
  scaffolde pas une feature complète au-delà du flow login.
- **CI/CD au-delà de GitHub Actions** — pas de Bitrise, Codemagic,
  CircleCI templates. Si demandé en T3+, ajout possible.

## Impact

- **Users affected** :
  - **Équipes mobile-natives** (~30 % du marché Flutter selon
    Stack Overflow Dev Survey 2024 / 2025) — segment majeur
    actuellement non couvert.
  - **Adopteurs Forge existants** — ne sont pas impactés ; B.4 est
    un **ajout**, pas une modification d'archétype existant.
  - **Mainteneurs Forge** — surface de maintenance + 1 archétype
    (templates, scaffolder, harness, spec). Surface bornée par le
    contrat ABI B.5.1.
- **Technical impact** :
  - **Surface de templates** : ~80-150 fichiers (Flutter project
    skeleton + iOS + Android + Fastlane + CI). Plus large que
    `full-stack-monorepo` côté mobile (FSM pousse Flutter
    web-friendly), un peu moins large globalement (FSM a aussi
    backend + infra).
  - **Pas de TS modifié** — preuve par construction du contrat
    B.5.1.
  - **Tests** : harness `b4.test.sh` (≥ 25 tests structurels +
    fixture). Pas de tests Flutter fonctionnels (relèvent de
    l'adopter sur son projet).
  - **Snapshot tarball** (A.7) : un nouveau
    `.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz` sera
    nécessaire pour permettre `forge upgrade` sur ce nouvel
    archétype.
- **Dependencies** :
  - **B.1 full-stack-monorepo** (✅ livré) — pattern de référence
    pour la structure d'archétype.
  - **B.5.1 init-wizard** (✅ livré) — dispatcher + ABI
    `bin/forge-init-<archetype>.sh`.
  - **A.7 forge-upgrade** (✅ livré) — `framework-owned-paths.yml`
    devra inclure les nouveaux paths de l'archétype mobile-only
    (ou le `framework-owned-paths.yml` est par-archétype, à vérifier
    en design).
  - **D.5 governance** (✅ livré) — premier change post-amendement,
    valide les bumps de templates.
  - **G.1 forge-ci** (✅ livré) — `b4.test.sh` s'enregistre dans
    le job `harness`.

## Constitution Compliance

- **Article I (TDD)** : ✅ TDD sur le harness shell `b4.test.sh`
  (RED→GREEN par phase). Les snippets Flutter livrés (auth
  bloc + repository + secure storage adapter) sont écrits avec
  test-first dans le template lui-même : chaque template contient
  son `*_test.dart` et l'adopter peut lancer
  `flutter test` immédiatement après scaffold pour vérifier que
  le contrat est respecté.
- **Article II (BDD)** : ✅ scénarios Gherkin documentaires pour
  les flows OIDC login / token refresh / biometric unlock /
  attestation, dans `.forge/changes/b4-mobile-only/specs.md`.
  Templates `*.feature` fournis sous `integration_test/` du
  scaffold (cucumber-flutter, conformément à Article II).
- **Article III (Specs Before Code)** : ✅ pipeline complet.
- **Article III.4 (Anti-hallucination)** :
  - **3 questions ouvertes** identifiées (cf. fin de proposal),
    à trancher par l'utilisateur avant `/forge:specify` ou en
    début de specify.
  - Aucune décision deviniée.
- **Article IV (Delta-based)** : ✅ ADDED uniquement (nouveau
  namespace `FR-MO-*`). Modifications légères de
  `dispatch-table.yml` (ajout d'une entrée), `index.yml` (ajout
  trigger), `forge-ci.yml` (ajout étape harness),
  `docs/ARCHETYPES.md` (ajout ligne matrice).
- **Article V (Process Gates)** : ✅ pipeline complet. Le change
  passera par tous les gates avant archive.
- **Article VI (Flutter)** :
  - State management = `flutter_bloc` (Article VI.4) — exigence
    immuable, B.4 livre un exemple `auth_bloc.dart` aligné.
  - Architecture = clean architecture / hexagonale (Article VI.6)
    — `lib/` segmenté en `domain/`, `data/`, `presentation/`,
    `infrastructure/`.
  - BDD via cucumber-flutter (Article VI.7) — `integration_test/`
    contient au moins un `.feature`.
- **Article VII (Rust)** : NA (mobile-only, no Rust).
- **Article VIII (Infra)** : NA (no infra component).
- **Article IX (Observability)** : ✅ — l'archétype livre un module
  `observability/` avec OpenTelemetry SDK (`opentelemetry_api` +
  `opentelemetry_sdk` Flutter) configuré pour exporter vers
  un OTLP endpoint configurable. Pas de SigNoz local (pas
  d'infra), mais le contract observability d'Article IX est
  respecté côté client.
- **Article X (Quality)** : ✅ — `analysis_options.yaml`
  pinné, golden tests scaffoldés, lints stricts, coverage
  threshold dans CI template.
- **Article XI (AI-First)** : NA pour B.4 (pas d'AI dans le
  template de base ; un adopter peut ajouter Prometheus
  bloc côté lib s'il en a besoin, mais ce n'est pas scope).
- **Article XII (Governance)** : ✅ premier change ratifié sous
  v1.1.0, `constitution_version: "1.1.0"` dans le `.forge.yaml`.

---

## Effort estimé et stratégie d'exécution

**Effort `XL`** (cohérent avec la roadmap). Significativement plus
gros que les changes précédents (M-L). Comparaisons :

| Change       | Lignes commit  | Files added/modified | Sessions |
| ------------ | -------------- | -------------------- | -------- |
| `d5-governance` | +1767/-15  | 16                   | 1        |
| `b5-1-init-wizard` | ~+3500 | ~25                  | 2        |
| `a7-forge-upgrade` | ~+5500 | ~30                  | 2        |
| `b1-foundations` + `b1-scaffolder` + `b1-workflow` + `b1-delivery` | ~+20000 | ~100 | 4 changes |
| **`b4-mobile-only`** estimé | **~+8000-15000** | **~80-150**    | **probablement 2-3 sessions** |

**Stratégie recommandée** : single-change (un seul `b4-mobile-only/`),
mais découpé en **3 phases d'implémentation**, avec un **commit par
phase** :

- **Phase A** : Schéma + structure de templates (Flutter + iOS +
  Android natifs + dispatch-table entry + wrapper bash). Snapshot
  tarball construit.
- **Phase B** : OIDC + secure storage + biometric + attestation
  (modules avec abstractions + fakes + tests Flutter scaffoldés).
  Standards `flutter-mobile.md` rédigé.
- **Phase C** : Fastlane + CI workflow + harness `b4.test.sh` +
  archive (consolidation specs + roadmap + CHANGELOG).

Chaque phase est commit-able indépendamment et revue par étapes.
La guard-rail T2 P2 sera levée à la fin de Phase C.

---

## Décisions ouvertes (à trancher par utilisateur avant `/forge:specify`)

1. **Compose iOS Deployment Target + Android minSdkVersion** :
   - iOS : recommandation `15.0` (App Attest requires iOS 14+ ;
     Flutter 3.x default = 12.0 ; bump à 15.0 pour aligner sur
     plate-formes encore vivantes)
   - Android : recommandation `minSdkVersion = 26` (Android 8 ;
     Play Integrity requires API 21+ ; biometric library
     local_auth requires 23+ ; 26 = StrongBox enclave + adoption
     ≥ 92 % en 2026)
   - **Si tu veux du plus large**, je descends à 13.0 / 23 sans
     attestation.

2. **OIDC provider exemple** :
   - **Recommandation** : pas d'exemple câblé sur un provider
     spécifique. L'archétype livre `auth/oidc_config.dart`
     vide (avec commentaires pointant vers Auth0 / Keycloak /
     Okta / Cognito), et un README explique comment câbler.
     Plus neutre, plus générique.
   - **Alternative** : câbler Keycloak en exemple (open source,
     auto-hostable, le plus reproductible). Plus pédagogique
     mais oriente l'adopter.

3. **Snapshot tarball pré-build** :
   - **Recommandation** : OUI — créer
     `.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz` à
     l'archive (cohérent avec full-stack-monorepo). Permet
     `forge upgrade` opérationnel dès J+1.
   - **Alternative** : différer (l'archétype 1.0.0 = release ;
     adopters précoces n'ont pas besoin de snapshot car ils sont
     sur la version stable). Risque : pas d'upgrade possible
     avant 1.1.0.

---

## Décisions ouvertes — résolues 2026-04-30

1. **Plateformes minimum** → **iOS 15.0** + **Android `minSdkVersion 26`**
   (App Attest + Play Integrity + biometric StrongBox enclave, ≥ 92 %
   adoption en 2026).
2. **OIDC provider exemple** → **neutre** : `auth/oidc_config.dart` livré
   vide avec commentaires/README pointant Auth0, Keycloak, Okta,
   Cognito. Pas de câblage spécifique à un provider.
3. **Snapshot tarball pré-build** → **OUI** : création de
   `.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz` à l'archive
   pour permettre `forge upgrade` opérationnel J+1 (cohérent avec
   `full-stack-monorepo`).

---

**Note sur le nom** : `b4-mobile-only` (court, scannable, aligné
avec la convention `b<n>-<archetype-key>` posée par
`b5-1-init-wizard`). Cohérent avec la roadmap.
