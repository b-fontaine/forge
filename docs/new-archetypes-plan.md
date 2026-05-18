# Forge — Nouveau plan d'archétypes (post-`ARCHITECTURE-TARGET.md`)

> **Auteur** : architecte solution senior (mode *ruthless mentor*)
> **Cible** : Benoît Fontaine, créateur de Forge — branche `optim` après v0.3.0
> **Date de production** : 2026-05-04
> **Origine** : remise à plat du plan `il-s-agit-l-d-un-noble-gem.md` (modules d'audit) à la
> lumière de `docs/ARCHITECTURE-TARGET.md` (rapport architectural cible Forge 2026).
> **Tonalité** : sans complaisance. Toute décision soit sourcée du document d'architecture,
> soit explicitement marquée `(opinion d'architecte)`.
>
> Ce document **remplace** la priorisation T3/T4 + le module B (archétypes) du plan
> d'origine. Les modules A, D, E, F, G, H restent en l'état sauf mentions explicites.
> Les sections « Modules livrés » reprennent verbatim les états du plan d'origine pour
> garder un seul plan de référence post-v0.3.0.

---

## 0.0 Status update — 2026-05-10

> **Mise à jour cumulative depuis la rédaction du plan le 2026-05-04.**
> Lis cette section avant le reste du document : elle reflète l'état réel
> du repo, qui ne correspond plus terme à terme à la priorisation §11.

### Modules livrés (post-v0.3.0)

- **`t4-adr-ratification` archivé 2026-05-04** (PR #2 mergée) — consolide
  **P-1 + P-2 + P-3 + P-4 + I.1 + J.1–J.6** en un seul change archivé
  plutôt que dix ADRs séparés. Décision pragmatique : l'audit trail
  Article V est préservé via 35 ADDED FRs (`FR-T4-ADR-001..010` +
  `FR-T4-STD-001..006` + `FR-T4-LC-001..005` + `FR-T4-SCH-001..002` + ...)
  dans `.forge/specs/adr-ratification.md`. Côté livrables physiques :
    - Six `.forge/standards/*.yaml` v1.0.0 (`transport`, `state-management`,
      `observability`, `orchestration`, `identity`, `persistence`) avec
      frontmatter uniforme (`version` / `last_reviewed` / `expires_at` /
      `exception_constitutional` / `linter_rule` / `enforcement` /
      `forbidden` / `rationale`).
    - `global/standards-lifecycle.md` + `.forge/standards/REVIEW.md` ledger
      append-only avec entrée seed (4 standards `Next review due: 2027-05-04`,
      2 structurels `never`).
    - `.forge/schemas/compliance-tier.schema.json` (enum T1/T2/T3).
    - `.forge/schemas/archetype.schema.json` **v2.0.0** : 5 archétypes
      canoniques (`full-stack-monorepo`, `mobile-pwa-first`, `event-driven-eu`,
      `ai-native-rag`, `rust-cli-tui`) + `mobile-only` conservé comme alias
      déprécié pour les adopters v0.3.0 (B.4) jusqu'à B.9 en T8.
    - Index `.forge/standards/index.yml` étendu avec un bloc
      `T.4 ratifications` qui expose les 6 standards YAML + 2 normes
      associées (`global/standards-lifecycle.md`, `global/source-document-pinning.md`)
      aux triggers d'injection JIT.
    - `compliance-tier.schema.json` est référencé par
      `archetype.schema.json` v2 dans `x-component-eligibility-matrix-source`.

- **`t5-connect-codegen` archivé 2026-05-06** (PR #3 mergée, merge commit
  `ca27257`) — **première brique T5 Phase 1 ARCH** livrée additive sur la
  flagship. Spec consolidée `.forge/specs/connect-codegen.md` (32 ADDED FRs
  `FR-T5-CC-001..072` + 10 NFRs `NFR-T5-CC-001..010` + 6 ADRs
  `ADR-T5-001..006`). Livrables physiques :
    - `templates/full-stack-monorepo/1.0.0/proto/buf.gen.yaml.tmpl`
      étendu avec `protoc-gen-connect-go` v1.19.2, `bufbuild/protoc-gen-es`
      ≥ v2.2.0 (Connect v2), `connectrpc/connect-dart` officiel ≥ v1.0.0
      (publié sur pub.dev par `connectrpc.com`).
    - **Pivot d'implémentation Rust** post-investigation T-BUF
      (2026-05-05) : le plugin BSR `buf.build/anthropics/connect-rust`
      n'est pas encore publié, et la convention codebase impose des
      plugins remote uniquement → bascule sur `connectrpc-build` via
      `build.rs` (Option 2 / Path α, supportée upstream comme
      "Option B"). Pin `connectrpc = "=0.3.3"` + `buffa = "=0.3.3"` +
      `buffa-types = "=0.3.3"` (Anthropic OSS Apache-2.0, MSRV 1.88,
      6 558 conformance tests). Intégration axum inline via
      `Router::into_axum_service()` — pas de crate `connectrpc-axum`
      séparé.
    - `transport.yaml` 1.0.0 → 1.1.0 (codegen pinning, additif — pas
      de `breaking_change: true`) avec 11 versions épinglées + entrée
      `Updated` dans `.forge/standards/REVIEW.md`.
    - Demo `demo-005-connect-greeting` archivée dans
      `examples/forge-fsm-example/`, parallèle au gRPC tonic existant.
    - Linter `transport-codegen-coverage` WARN-only ajouté à
      `constitution-linter.sh` (opt-out
      `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1`).
    - Harness `t5.test.sh` 25/25 L1 PASS, 0 FAIL ; **L2 fixtures
      (T-L2-001..007) volontairement deferred à T6** (B.8 flagship
      migration) — buf generate, Dart smoke, traceparent dual-codec
      E2E, cargo fixture build, connectrpc dual-codec direct. La CI
      matrix exécute `t5.test.sh --level 1` uniquement.
    - tonic-build inchangé (ADR-004 KEEP).

- **`j7-validate-standards-yaml` archivé 2026-05-08** (commit pending) —
  **automated enforcement** du contrat frontmatter des six
  `.forge/standards/*.yaml` shippés par T.4 (FR-T4-LC-001..005) +
  bumpés par T.5 (`transport.yaml` v1.1.0). Spec consolidée
  `.forge/specs/standards-yaml-validation.md` (27 ADDED FRs
  `FR-J7-001..102` + 6 NFRs + 5 ADRs `ADR-J7-001..005`). Livrables
  physiques :
    - `bin/validate-standards-yaml.sh` — linter dédié, bash thin +
      Python 3 inline (F.2 pattern lifted, **pas** de `jsonschema`
      lib). Phase 1 schema walk + Phase 2 invariants en une passe.
      Exit codes 0 (PASS) / 1 (FAIL) / 2 (usage error).
    - `.forge/schemas/standard.schema.json` — JSON Schema
      Draft 2020-12, `additionalProperties: true` au root
      (corps domaine libre — `transport.codegen`, `state-management.framework`).
    - **5 invariants bloquants** : Article XII coupling
      (`expires_at: never` ⇔ `exception_constitutional: true`,
      bidirectionnel — FR-J7-020), strict `expires_at > last_reviewed`
      (FR-J7-021), REVIEW.md full ledger scan via regex de cellule de
      table (FR-J7-023, ADR-J7-003), `linter_rule` cross-reference
      via grep `^\s*(echo|#).*\b{rule}\b` sur
      `constitution-linter.sh` (FR-J7-030, ADR-J7-002), `index.yml`
      trigger reachability (FR-J7-050).
    - **2 informatifs non-bloquants** : 12-month cycle loose
      (FR-J7-022), orphan standards (FR-J7-051).
    - `.forge/scripts/verify.sh` § "Standards YAML Schema" inséré
      après le bloc F.2 (+7 PASS sur le live tree).
    - Harness `.forge/scripts/tests/j7.test.sh` — **21/21 GREEN**
      à `--level 1,2` (17 L1 + 4 L2), live-tree wall-clock **122 ms**
      (NFR-J7-001 budget 2 s, 6 % utilisé). Registered dans
      `.github/workflows/forge-ci.yml` après `t5.test.sh`.
    - Documentation : `docs/SCHEMA.md` § "Standard YAML schema"
      symétrique de Change YAML (frontmatter table, invariants,
      CLI usage, common errors recipe, "adding a new standard YAML"
      walkthrough) + `global/standards-lifecycle.md` § "Automated
      enforcement" + CHANGELOG `[Unreleased]` entry.
    - Schéma `enforcement.additionalProperties` relaxé de `false` à
      `true` (par rapport au spec initial FR-J7-008) pour accommoder
      le champ documenté `activation_planned: "B.8 (T6)"` de
      `state-management.yaml` — la paire canonique
      `ci_blocking + pre_commit_hook` reste obligatoire ; NFR-J7-002
      live-tree GREEN préservé.

- **`t5-otel-stack` archivé 2026-05-10** — **infra side** du triplet
  SigNoz + OBI eBPF + Coroot sur la flagship `full-stack-monorepo / 1.0.0`.
  Réalise `observability.yaml` v1.1.0 (ADR-008). Spec consolidée
  `.forge/specs/otel-stack.md` (22 ADDED FRs `FR-OTEL-001..082` +
  5 NFRs + 7 ADRs `ADR-OTEL-001..007`). Livrables physiques :
    - **OBI eBPF DaemonSet** (`grafana/beyla:2.0.1`) en posture
      **unprivileged-with-capabilities** (ADR-OTEL-004) — caps
      `BPF/SYS_PTRACE/NET_RAW/CHECKPOINT_RESTORE/DAC_READ_SEARCH/
      PERFMON/NET_ADMIN/SYS_ADMIN`, drop ALL otherwise. RBAC dédié
      (ServiceAccount + ClusterRole read-only sur pods/nodes/replicasets +
      ClusterRoleBinding). Annotation `forge.dev/aegis-audit: required`.
      `nodeSelector: forge.dev/kernel-min-58: "true"` (opt-in node label,
      ADR-OTEL-007).
    - **Coroot deployment** (`coroot/coroot:1.4.4`) multi-doc YAML
      (Deployment + Service + ConfigMap, ADR-OTEL-006). Single-replica,
      `emptyDir` local-dev (PVC swap documenté).
    - **OTel collector sampler** : `processors.probabilistic_sampler`
      ajouté (ADR-OTEL-001 — `mode: proportional`,
      `attribute_source: traceID`, `hash_seed: 22`,
      `sampling_percentage: 100` dev default). Wired into traces
      pipeline only.
    - **Env-tier overlays** : 3 sampler-patches
      (`infra/k8s/overlays/{dev,staging,prod}/sampler-patch.yaml.tmpl`)
      avec ratios 100/100/10 par `observability.yaml::ratios`.
    - **`observability.yaml` 1.0.0 → 1.1.0** (additive) avec nouveau
      bloc `versions:` (`beyla: "2.0.1"` + `coroot: "1.4.4"`,
      ADR-OTEL-003, symétrique avec T.5 `transport.yaml` 1.0.0 → 1.1.0).
      Entrée `Updated` dans REVIEW.md datée 2026-05-09.
    - **Aegis audit doc** : 3 H2 sections dans `infra/CLAUDE.md.tmpl`
      (Privileged DaemonSet — duty Aegis / Sampler overlay mechanism /
      Coroot persistence) + checklist "Deployment prerequisites" dans
      `infra/k8s/base/README.md.tmpl`.
    - **Example mirror** : 6 fichiers rendus dans
      `examples/forge-fsm-example/infra/`.
    - **Snapshot tarball** régénéré : 520 KB (87 % du budget 600 KB
      NFR-OTEL-001) ; `a7.test.sh` 29/0 PASS (forge upgrade backward
      compat NFR-OTEL-002).
    - **Harness** `.forge/scripts/tests/t5-otel.test.sh` 14/14 GREEN
      à `--level 1`. Registered dans `forge-ci.yml`.

- **`j8-janus-rules` archivé 2026-05-10** — **trois sous-modules**
  consolidés en un seul change pour cohérence EU compliance :
  Spec consolidée `.forge/specs/janus-rules.md` (36 ADDED FRs
  `FR-J8-001..112` + 6 NFRs + 7 ADRs `ADR-J8-001..007`).
    - **J.8.a — Janus refusal rules** : `cross-layer-orchestrator.md`
      gagne section H2 "Forbidden archetypes & combinations" avec 3
      seed rules (`J8-RULE-001` flutter-firebase Schrems II + CLOUD
      Act ; `J8-RULE-002` T3 ⇒ self-host Zitadel ; `J8-RULE-003`
      T3 ⇒ self-host SigNoz + no Datadog). `dispatch-table.yml`
      gagne `forbidden_archetypes:` runtime registry. Helper
      partagé `bin/_forge-init-helpers.sh::_refuse_if_forbidden()`
      (Python 3 inline, défense en profondeur, sourced par 2
      wrappers). TS dispatcher `init-archetype.ts` est première
      ligne de défense. Standard `global/janus-orchestration-rules.md`
      codifie le catalogue + procédure d'extension. Refusal exit
      code = **3** (ADR-J8-003).
    - **J.8.b — `--eu-tier` flag** : `init.ts` gagne
      `EU_TIER_ENUM = ["T1", "T2", "T3"]` + champ optionnel
      `euTier?:` validé contre `compliance-tier.schema.json` (T.4) ;
      env-var `FORGE_EU_TIER` ABI vers wrappers ; T3 case-block
      dans fsm wrapper refuse Datadog + signoz.io + identité cloud
      (Auth0/Okta/Keycloak-cloud) avec structured `[REFUSAL: ...]` ;
      T1/T2 émettent `[INFO: <tier>: ...]` seulement. Ledger
      `<target>/.forge/.forge-tier` plain-text 1-line (ADR-J8-006).
      Backward compat préservé (NFR-J8-002 — flag absent =
      comportement identique au pré-J.8).
    - **J.8.d — CycloneDX 1.5 SBOM** : `bin/forge-sbom.sh` bash
      thin + Python 3 inline (handcraft per Context7-verified
      mandatory fields, **zero new external dep** NFR-J8-005),
      détection lockfiles récursive (depth 4 + skip-list
      `node_modules/target/.dart_tool/.git/...`) pour Cargo + npm
      family + pubspec. **`SOURCE_DATE_EPOCH`-deterministic**
      byte-identical output (FR-J8-075, uuid v5 derivation).
      Standard `global/sbom-policy.md` (rationale NIS2/DORA/CRA).
      Nouveau job `sbom` dans `forge-ci.yml` upload artefact
      `sbom-cyclonedx`. Smoke sur `examples/forge-fsm-example/`
      → **74 components** (Cargo backend + pubspec frontend).
    - **Harness** `.forge/scripts/tests/j8.test.sh` 20/20 GREEN à
      `--level 1,2` (18 L1 + 2 L2). Registered dans `forge-ci.yml`.
    - **J.8.c retiré du scope** — règles Janus pour
      `ai-native-rag` (force Mistral-EU/vLLM si T3) déférées vers
      un change suivant qui livrera l'archetype `ai-native-rag` en
      T7. Aucun blocage T7 ; J.8.c se cumule avec K.1/K.2/K.4/K.5.

- **`k3-demeter` archivé 2026-05-12** — **K.3 + I.4** : premier des
  cinq nouveaux agents (Demeter, data steward EU) livré comme
  change additif. Spec consolidée `.forge/specs/data-stewardship.md`
  (55 ADDED FRs `FR-K3-DEM-001..124` + 9 NFRs + 7 ADRs
  `ADR-K3-001..007`). Six livrables physiques :
    - **K.3.a — Persona file** `.claude/agents/demeter.md` : 7 H2
      sections (Persona, Purpose, Checklists, Output, Rule
      Catalogue, Integration, Anti-Hallucination Protocol). Style
      Aegis-like (severity-first, evidence-driven). Sibling à
      Aegis ; Aegis = posture vulnérabilité, Demeter = posture
      data-stewardship (juridiction, DPA, classification PII).
    - **K.3.b — Scanner** `bin/forge-demeter-scan.sh` : pattern
      F.2 / J.7 / J.8.d **verbatim** (bash thin + Python 3 inline,
      **zero new external dep**, NFR-K3-DEM-004 + ADR-K3-004).
      Walk lockfiles Cargo + npm + pubspec sous `--target`
      (récursif depth ≤ 3). Match publisher contre deny-list
      `.forge/data/cloud-act-publishers.yml::ecosystems.*`.
      Severity tier-scaled (T1 → Informational, T2 → High, T3 →
      Critical) per FR-K3-DEM-068. Exit code envelope **0 / 1 /
      2 / 3** (mirrors J.8 ADR-J8-003 policy-refusal sémantique).
      `SOURCE_DATE_EPOCH`-deterministic byte-identical output
      (NFR-K3-DEM-005).
    - **K.3.c — Deny-list** `.forge/data/cloud-act-publishers.yml` :
      4 cargo + 4 npm + 2 pub publisher patterns couvrant
      AWS / Google Cloud / Azure / Firebase écosystèmes. Chaque
      entrée porte `evidence_url:` + `jurisdiction: US` + free-form
      `rationale:`. Métadonnées `version:` / `last_reviewed:` /
      `expires_at:` / `maintained_by:` per NFR-K3-DEM-008.
    - **K.3.d — Standard** `.forge/standards/global/data-stewardship-rules.md` :
      7 H2 sections (rule catalogue, adoption path, DPA declaration
      semantics, extending the catalogue, regeneration cadence
      Phase A interim BDFL / 12-month vs Phase B post-T7 Themis /
      6-month per ADR-K3-003, constitutional compliance).
      Standards index `.forge/standards/index.yml` registers
      l'entrée sous "Cross-Cutting Standards".
    - **K.3.e — Test harness** `.forge/scripts/tests/k3.test.sh` :
      20 L1 + 2 L2 tests. **22/22 GREEN** à `--level 1,2`.
      Registered dans `forge-ci.yml` matrix après `j8.test.sh`.
    - **K.3.f — Janus delta** : edit chirurgical à
      `.claude/agents/cross-layer-orchestrator.md` per ADR-K3-007 :
      (1) Dispatch Table gagne row Demeter ; (2) H3
      `### Step 9 — Security Pass (Aegis)` renommée
      `### Step 9 — Security & Data-Stewardship Pass (Aegis + Demeter)`
      ; (3) paragraphe Demeter appended (parallel pass, no overlap
      avec Aegis) ; (4) Quality Gates H2 gagne bullet
      data-stewardship gate.
    - **Repo CLAUDE.md** : agent-table gagne row Demeter
      (Data stewardship → Demeter, Data Steward EU), inséré
      alphabétiquement entre Oracle et Clio.
    - **K3-RULE-NNN namespace** (hérite ADR-J8-004) : 5 seed
      rules (K3-RULE-001 US-jurisdiction publisher tier-scaled,
      K3-RULE-002 DPA undeclared at T1 High, K3-RULE-003 tier
      downgrade refused T2 High / T3 Critical, K3-RULE-004 data
      classification missing Medium, K3-RULE-005 Cargo workspace
      drift Medium) + K3-RULE-006 operational guardrail
      (publisher list staleness, Medium). ADR-K3-005 résout
      Q-003 (Option B incremental growth) ; IDs jamais réutilisés.
    - **DPA ledger** `.forge/.forge-dpa-declared` plain-text
      1-line (mirrors J.8 ADR-J8-006 `.forge-tier` ledger verbatim,
      ADR-K3-002 résout Q-001). Demeter ne parse PAS de documents
      légaux (FR-K3-DEM-044) — verify proof-of-attestation only.
    - **Anti-hallucination** : NFR-K3-DEM-009 — juridiction
      publisher ambiguë (multinational, acquisition récente)
      ⇒ `[NEEDS CLARIFICATION:]` JSON entry au lieu d'une
      finding. Article III.4 préservé.
    - **Gates finaux post-archive** : `verify.sh` 158 PASS / 0 FAIL
      / 1 WARN / RESULT: PASS ; `constitution-linter.sh` OVERALL
      PASS ; `validate-change-yaml.sh` sur `.forge.yaml` archivé
      exit 0 ; `open-questions.md` 0 open / 3 answered (Q-001 →
      ADR-K3-002, Q-002 → ADR-K3-003, Q-003 → ADR-K3-005).

- **`t5-otel-dart-api-realign` archivé 2026-05-12** — **standard
  realign** réagissant à Q-004 (drift API entre la v1.0.0 du
  `flutter/opentelemetry.md` et le pkg `opentelemetry: 0.18.11`
  Workiva effectivement publié sur pub.dev). La v1.0.0 documentait
  une API fabriquée par transposition cross-language (JS / Java /
  Python OTel) ; la v1.1.0 ratifie les symboles réellement exposés
  par le pkg Workiva : `CollectorExporter(Uri)` au lieu de
  `OtlpHttpSpanExporter`, `BatchSpanProcessor(exporter, named-args)`
  au lieu d'un wrapping config object, `ParentBasedSampler(AlwaysOnSampler())`
  au lieu du fabriqué `TraceIdRatioBasedSampler` (le ratio env-tier
  reste enforced collector-side per ADR-OTEL-001), `StatusCode.*`
  au lieu de `SpanStatusCode.*`, `setStatus(code, description)`
  positionnel au lieu de `description:` nommé, top-level
  `contextWithSpan(Context.current, span)` au lieu de
  `Context.current.withSpan(...)`. Deux imports canoniques :
  `api.dart` + `sdk.dart` (les sub-imports `exporter_otlp_*.dart`
  n'existent pas dans ce pkg layout). Entrée `Updated` dans
  `REVIEW.md` ledger.

- **`t5-otel-app` archivé 2026-05-12** — **Phase B** du déploiement
  T.5 OTel : SDK app-side dans `examples/forge-fsm-example/` après
  Phase A `t5-otel-stack` (infra). Spec consolidée
  `.forge/specs/otel-app.md` (56 ADDED FRs `FR-T5-OTA-001..103` +
  7 NFRs + 7 ADRs `ADR-T5-OTA-001..007`). Livrables :
    - **Rust backend** : nouveau `crates/infrastructure/src/telemetry/`
      (`mod.rs` + `propagation.rs` + `middleware.rs`) avec
      `setup_telemetry`, OTLP HTTP/protobuf exporter (`with_protocol(
      Protocol::HttpBinary)`, port 4318, ADR-T5-OTA-002), 4 Resource
      attrs mandatory (`service.name/version`, `deployment.environment`,
      `host.name`), `ParentBased(TraceIdRatioBased(rate))` sampler
      (ADR-T5-OTA-003), `tracing-opentelemetry` bridge,
      `tower-http::TraceLayer` outermost avec `make_span_with`
      extrayant W3C `traceparent` via `TraceContextPropagator`,
      `MetadataMapCarrier` (gRPC) + `HeaderMapCarrier` (HTTP outbound).
      Pins ADR-T5-OTA-001 : `opentelemetry 0.31` + `tracing-opentelemetry 0.32`
      + `tower-http 0.6 [trace]`. Graceful shutdown via
      `tokio::signal::ctrl_c()` + `provider.shutdown()`.
    - **Flutter frontend** : nouveau `lib/core/telemetry/`
      (`telemetry_setup.dart`, `observers/tracing_navigation_observer.dart`,
      `observers/tracing_bloc_observer.dart`, `error_reporter.dart`,
      `interceptors/tracing_interceptor.dart`) + `lib/core/config/app_config.dart`
      + `main.dart` réécrit per ADR-T5-OTA-005 init order.
      `pubspec.yaml` : `opentelemetry: ^0.18.0` + `dio: ^5.7.0`
      (`flutter pub get` résout `0.18.11` + `5.9.2`). **Code aligné
      à `flutter/opentelemetry.md` v1.1.0** (sibling
      `t5-otel-dart-api-realign`).
    - **Q-004 cascade résolu** — voir `t5-otel-dart-api-realign`
      ci-dessus pour la bump standard ; le follow-up commit
      `15b774c` dans ce change a réaligné les 5 fichiers Dart
      concernés. Test L2 `_test_ota_l2_002_flutter_analyze`
      flippé de xfail à expected-pass (gracefully skip si
      `flutter` absent du PATH).
    - **demo-005 traceparent round-trip** : Greeter use case avec
      `#[tracing::instrument(name = "greeter.greet", fields(otel.kind = "internal", ...))]`.
      Flutter `GreetingRepositoryImpl` construit un `Dio` avec
      `TracingInterceptor` pré-attaché.
    - **Env config** : `examples/forge-fsm-example/README.md` §
      "Environment configuration" documente le trio
      `OTEL_EXPORTER_OTLP_ENDPOINT` + `OTEL_SERVICE_NAME` +
      `OTEL_RESOURCE_ATTRIBUTES` + `DEPLOYMENT_ENV` + samplers
      (`OTEL_TRACES_SAMPLER`, `OTEL_TRACES_SAMPLER_ARG`).
      Avertissement `NEVER PUT SECRETS HERE` explicite (Article XI.6).
      **Note** : le target original `.env.example` est tombé sur un
      permission gate worktree-side ; trio documenté dans README à
      la place avec sémantique d'audit identique.
    - **demo doc** : `docs/demo-005-connect-greeting.md` gagne H2
      `## Trace this in SigNoz` énumérant le 4-span tree (Flutter
      root → axum server → connectrpc handler → application use case).
    - **Harness** `.forge/scripts/tests/t5-otel-app.test.sh` 16 L1
      + 2 L2 ; **18/18 GREEN** à `--level 1,2` avec les deux
      toolchains sur PATH. Registered dans `forge-ci.yml`. Perf
      L1 ≤ 8 s, L2 ≤ 90 s (NFR-T5-OTA-005).
    - **BDD scenario** :
      `examples/forge-fsm-example/test/features/demo_005_traceparent.feature`
      shipped per Article II.1 ; step bodies **delivered 2026-05-12
      via `t5-otel-live-run` (Phase D)** through the hermetic smoke
      driver `test/live-run/run_smoke.sh` + fake OTLP collector +
      2 golden captures + `traceparent_live_run.feature` (2 scenarios).
    - **Phase A / Phase B clarté** : la Phase A
      (`t5-otel-stack`) ratifie `observability.yaml` v1.1.0 ; la
      Phase B (`t5-otel-app`) consomme `observability.yaml` v1.1.0
      + `rust/opentelemetry.md` v1.0.0 + `flutter/opentelemetry.md`
      **v1.1.0** sans modifier d'autre standard. Phase C (E2E
      traceparent à travers Envoy/Kong) reportée à T6 / B.8 avec
      le `_test_t5_l2_traceparent_dual` de `t5-connect-codegen`.

- **`i2-compliance-tiers` archivé 2026-05-12** — **I.2** : seul
  standard humain codifiant le gradient EU compliance T1 / T2 / T3,
  depuis `compliance-tier.schema.json` v1.0.0 (T.4) et
  `ARCHITECTURE-TARGET.md` §10. Spec consolidée
  `.forge/specs/compliance-tiers.md` (FR-I2-CT-001..112 + 7 NFRs +
  3 ADRs `ADR-I2-CT-001..003`). Cinq livrables physiques :
    - **I.2.a — Standard**
      `.forge/standards/global/compliance-tiers.md` v1.0.0 (437 LOC,
      7 H2 sections — Purpose, Tier definitions, Component
      eligibility matrix, Demeter integration, Adoption path,
      Extending the matrix, Interdictions + Constitutional
      Compliance). Citation **verbatim** du bloc
      `x-tier-descriptions` du schéma (Article III.4 +
      NFR-I2-CT-004, mirrors K.3 FR-K3-DEM-020 precedent).
      Matrice 15 lignes **byte-identical** à
      `docs/ARCHITECTURE-TARGET.md` §10.2 (ADR-I2-CT-002 +
      NFR-I2-CT-005). 5 clauses RFC-2119 MUST NOT. Frontmatter pins
      `linter_rule: t3-forbidden-components` (forward-pointer to I.3).
    - **I.2.b — Index** `.forge/standards/index.yml` gagne une
      entrée `global/compliance-tiers` (9 triggers, scope all,
      priority high) après le bloc K.3.
    - **I.2.c — REVIEW** `.forge/standards/REVIEW.md` gagne entrée
      append-only 2026-05-11 (KEEP, next review 2027-05-11).
    - **I.2.d — Doc adopter** `docs/COMPLIANCE.md` au root du repo
      (ADR-I2-CT-003). H1 + 3 H2 sections (Quick start, Tier picker
      avec arbre de décision, Cross-references).
    - **I.2.e — Harness** `.forge/scripts/tests/i2.test.sh`
      14 L1 tests grep-only hermétiques. **14/14 GREEN**.
      Registered dans `forge-ci.yml` après `k3.test.sh`.
    - **Forward-pointer Demeter résolu** : `.claude/agents/demeter.md`
      cite désormais une cible existante.
    - **Unblocks downstream** : I.3 (linter rule
      `t3-forbidden-components`), I.5 (`forge-compliance.yml`
      reusable workflow), I.6 (artefacts NIS2 / DORA / CRA / AI Act).

- **`i6-compliance-artefacts` archivé 2026-05-12** — **I.6 Done** :
  bundle generator `.forge/scripts/compliance/bundle.sh` (bash thin +
  Python 3 inline mirroring `bin/forge-sbom.sh` per NFR-I6-CA-004),
  six-member deterministic `.tgz` (MANIFEST + tier-matrix +
  forge-dpa-declared template + audit-ledger JSON + audit-ledger MD +
  CycloneDX SBOM), DPA template
  `.forge/templates/compliance/forge-dpa-declared.template`, standard
  `global/compliance-artefacts-bundle.md` v1.0.0 (6 H2 + 4 MUST NOT +
  forward-stable schema), `index.yml` entry + REVIEW birth entry +
  `docs/COMPLIANCE.md` H2 + CHANGELOG. Determinism via
  `SOURCE_DATE_EPOCH` (NFR-I6-CA-005, asserted by L2 harness). Three
  ADRs (ADR-I6-CA-001..003) resolve archive format / ledger placement /
  script location. 16/16 tests GREEN `i6.test.sh --level 1,2`. Bundle
  layout is forward-stable for Themis-territory artefacts (NIS2 / DORA /
  CRA / AI Act regulatory deadlines under
  `.forge/compliance/{nis2,dora,cra,ai-act}/`) — additive expansion
  when Themis (K.5, T7+) ships, no breaking schema change. Scope
  deliberately **narrower** than the original I.6 plan : the bundle
  generator + content schema ship now ; the NIS2/DORA/CRA/AI Act
  deadlines artefacts themselves stay deferred to Themis territory.

- **`i5-compliance-workflow` archivé 2026-05-12** — **I.5 Done** :
  reusable GitHub Actions workflow `.github/workflows/forge-compliance.yml`
  (158 LOC, `on: workflow_call:` trigger ; 3 inputs `eu-tier` /
  `target-dir` / `artefact-name` ; 1 output `artefact-path` ;
  `permissions: contents: read` ; concurrency keyed on ref + tier
  with `cancel-in-progress: false`). Orchestrates les quatre
  scripts EU-compliance déjà livrés : Demeter
  (`bin/forge-demeter-scan.sh`, K.3) + constitution linter incl. la
  section ADR-I3-001 T3-Forbidden (`.forge/scripts/constitution-linter.sh`,
  I.3) + CycloneDX SBOM (`bin/forge-sbom.sh`, J.8.d) + bundle
  generator (`.forge/scripts/compliance/bundle.sh`, I.6). Upload
  via `actions/upload-artifact@v4`. Standard
  `global/forge-compliance-workflow.md` v1.0.0 (284 LOC, 7 H2 + 4
  MUST NOT, frontmatter `linter_rule: null`), index entry (8
  triggers), REVIEW.md birth entry, `docs/COMPLIANCE.md` H2
  `## Reusable compliance workflow` + copy-pasteable `uses:` block.
  Trois ADRs (ADR-I5-CW-001..003) résolvent l'agrégation des exit
  codes (trust each script's tier scaling end-to-end ; SBOM
  no-lockfile non-fatal via `continue-on-error: true`), la source
  `SOURCE_DATE_EPOCH` (commit timestamp + fallback run timestamp,
  no input field), et le gating L2 act-runner (opt-in
  `FORGE_I5_ACT=1` avec skip-when-absent, mirroring
  `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`). 17/17 tests
  `i5.test.sh --level 1,2` (16 L1 grep-based + 1 L2 skip-pass).
  Forward-stable pour les artefacts réglementaires Themis-territory
  (NIS2 / DORA / CRA / AI Act sous `.forge/compliance/`) lorsque
  K.5 (T7+) livrera — additive step additions per FR-I5-CW-083.

### Module en cours

Aucun change en cours sur `main` au 2026-05-12 (post-archive
`k3-demeter` + `t5-otel-dart-api-realign` + `t5-otel-app` +
`i2-compliance-tiers` + `i6-compliance-artefacts` +
`i3-t3-forbidden-linter` + `i5-compliance-workflow`). Tous les
forward-pointers de la frontmatter `global/compliance-tiers.md`
v1.0.0 sont désormais résolus.

### Modules toujours en attente

- **T5 (suite)** post-`i5-compliance-workflow` : artefacts
  réglementaires NIS2 / DORA / CRA / AI Act sous `.forge/compliance/`
  (déferrés au territoire Themis K.5, T7+), validation traceparent
  W3C E2E à travers Envoy / Kong (le `_test_t5_l2_traceparent_dual`
  reporté avec les fixtures L2 vers T6 / B.8).
- **T6 / T7 / T8 / T9+** : non commencés (B.6, B.7, B.8, B.9, B.3, K.1,
  K.2, K.4, K.5, C.2–C.5, G.*, H.*). **F.3 pulled forward to T5,
  delivered 2026-05-12 via `f3-release-script-fix`** (release script
  subshell isolation + 2FA OTP handling).

### Inventaire `.forge/changes/` (2026-05-12)

| Change                       | Status                 | Tier livré                    |
|------------------------------|------------------------|-------------------------------|
| `b1-foundations`             | archived               | T2 P1 (B.1.1)                 |
| `b1-scaffolder`              | archived               | T2 P1 (B.1.2)                 |
| `b1-workflow`                | archived               | T2 P1 (B.1.3)                 |
| `b1-delivery`                | archived               | T2 P1 (B.1.4)                 |
| `c1-reference-project`       | archived               | T2 P1 (C.1)                   |
| `b5-1-init-wizard`           | archived               | T2 P1 (B.5.1)                 |
| `g1-forge-ci`                | archived               | T2 P1 (G.1)                   |
| `a7-forge-upgrade`           | archived               | T2 P1 (A.7)                   |
| `d5-governance`              | archived               | T2 P1 (D.5)                   |
| `b4-mobile-only`             | archived               | T2 P2 (B.4)                   |
| `f1-open-questions`          | archived               | T3 (F.1)                      |
| `f2-yaml-schema`             | archived               | T3 (F.2)                      |
| `f4-linter-extension`        | archived               | T3 (F.4)                      |
| `t4-adr-ratification`        | archived               | T4 (P-1..P-4 + J.1–J.6 + I.1) |
| `t5-connect-codegen`         | archived               | T5 Phase 1 (Connect codegen)  |
| `j7-validate-standards-yaml` | archived               | T5 (J.7)                      |
| `t5-otel-stack`              | archived               | T5 (OTel + OBI + Coroot — Phase A) |
| `j8-janus-rules`             | archived               | T5 (J.8.a + J.8.b + J.8.d)    |
| `k3-demeter`                 | archived               | T5 (K.3 + I.4)                |
| `t5-otel-dart-api-realign`   | archived               | T5 (Q-004 — flutter/opentelemetry.md v1.1.0 Workiva realign) |
| `t5-otel-app`                | archived               | T5 (OTel App SDK — Phase B)   |
| `i2-compliance-tiers`        | archived               | T5 (I.2)                      |
| `t5-otel-live-run`           | archived               | T5 Phase D (live-run collector contract validation) |
| `f3-release-script-fix`      | archived               | T8 / F.3 (pulled forward) — release script fix |
| `cli-trust-harness`          | archived               | T5.1 (CLI Trust Harness)                       |
| `t5-cargo-pin-refresh`       | archived               | T5.1.E (Cargo pin correction)                  |
| `t5-bin-server-deps`         | archived               | T5.1.E (bin-server deps + grpc-api API realign) |
| `t5-2-platform-verification` | archived               | T5.2 (Anti-Hallucination Platform Verification — 3-axis checklist + standards-lifecycle.md v1.1.0) |

**28 archivés** (incluant `t5-2-platform-verification` 2026-05-18) au
2026-05-18, aucun change en cours. Aucun change orphelin, aucun
`status: in_progress` bloqué, aucun marqueur
`[NEEDS CLARIFICATION:]` non résolu inline dans les changes archivés
(tous gates `verify.sh` + `constitution-linter.sh` PASS).

---

## 0.1 Status update — 2026-05-14 (T5.1 — CLI Trust Harness planned)

> **Lis cette section avant §11.** Elle introduit un nouveau lot **T5.1**
> intercalé entre T5 (clos) et T6 (B.8 flagship migration). T5 est
> considéré **terminé** au 2026-05-12 (tous les items attendus archivés ;
> items résiduels explicitement déférés à T6 / T7+). T5.1 reste sous le
> bandeau T5 parce qu'il finalise la **confiance dans le binaire publié**
> avant que B.8 ne commence à toucher au flagship, et corrige des
> régressions d'expérience-utilisateur découvertes après v0.3.0 / v0.3.1.

### Origine — trois symptômes, une cause commune

Après publication des tarballs npm `@sdd-forge/cli@0.3.0` (2026-05-02),
`0.3.1` (2026-05-12, `f3-release-script-fix`), `0.3.2` (2026-05-13, trois
fixes first-experience), le mainteneur a constaté **trois défauts récurrents**
à l'usage du binaire publié :

1. **Deux patches en moins de 24 h après une release stable** — `--eu-tier`
   non wiré dans commander (`cli/src/cli.ts`), `spawn bash ENOENT` quand
   `--target` pointe sur un répertoire inexistant
   (`cli/src/commands/init-archetype.ts:148`), `init.sh` refuse de
   scaffolder dans un dir merely-existant (vs non-empty). Les trois fixes
   livrés en v0.3.2 sont des **régressions de surface CLI** non
   détectables par les unit tests vitest existants — seul un test
   exécutant le binaire publié dans une `mkdtemp` les expose.
2. **Paramètres d'invocation `forge init` non maîtrisés** — l'ABI complète
   (`<project-name>` positionnel, `--archetype`, `--org`, `--target`,
   `--force`, `--eu-tier`) n'est documentée que dans `init.ts` lui-même.
   La discussion GitHub d'annonce v0.3.0 a oublié `--org` et `--eu-tier`,
   parce qu'aucune source-of-truth copiable n'existe.
3. **`task dev:up` échoue après scaffold full-stack-monorepo** — le
   template `.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl:67`
   contient `- echo "infra tests: delegated to b1-delivery workflows"`.
   Dans un scalaire plain YAML (pas quoté au début), `: ` (deux-points +
   espace) est un séparateur key/value : go-task reçoit donc un mapping
   `{"echo \"infra tests": "delegated to b1-delivery workflows\""}` au
   lieu d'une string → `invalid keys in command`. Le template est cassé
   **depuis B.1 (2026-04-21)** mais aucun test n'exécute `task --list-all`
   sur un projet fraîchement scaffoldé.

**Cause racine commune** : le pipeline de tests CLI valide les choses
faciles à vérifier (fichiers présents, code de retour 0) mais **jamais
l'exécutabilité du scaffold rendu**. `cli/test/e2e/cli.test.ts` couvre
uniquement l'archétype `default` + l'existence de quelques paths ;
aucune assertion sur le contenu fonctionnel.

### T5.1 — items proposés

Quatre items, ordonnés par dépendance + valeur défensive. Effort total
**`M`**. Critère de release **v0.3.3** : T5.1 done + couches A+B+C green
en CI.

- **T5.1.0 — Fix `Taskfile.yml.tmpl` + sweep templates.** Single-quote
  toute commande shell contenant `: ` dans les `cmds:` go-task. Sweep
  `grep -rn 'echo "[^"]*: [^"]*"' .forge/templates/ examples/` pour
  attraper les autres occurrences. Critère de réussite : `task --list-all`
  sur un projet fraîchement scaffoldé (`forge init <slug> --archetype
  full-stack-monorepo --org dev.forge.test --target /tmp/probe`) sort en
  exit 0. Effort : `XS` (1 ligne minimum, plusieurs probable). **Prérequis
  T5.1.B** — le smoke test détectera toute régression future de ce type.
- **T5.1.A — Golden snapshot des flags CLI.** Nouveau
  `cli/test/e2e/help-snapshots.test.ts` qui capture l'output de
  `forge --help`, `forge init --help`, `forge upgrade --help`,
  `forge verify --help`, `forge version --help` dans
  `cli/test/e2e/__snapshots__/help/`. Tout changement de surface met à
  jour le snapshot → revue forcée. Assertion supplémentaire : chaque
  archétype actif de `.forge/scaffolding/dispatch-table.yml` (sauf
  `flutter-firebase` `status: removed_from_roadmap`) doit apparaître
  dans le `--help` `forge init` quelque part (description ou exemple).
  **Bloque** : le bug `--eu-tier` v0.3.0 / v0.3.1, ton oubli `--org`
  dans la discussion GitHub. Effort : `S`.
- **T5.1.B — Smoke test par archétype.** Nouveau
  `cli/test/e2e/archetypes-smoke.test.ts` qui itère sur
  `dispatch-table.yml::archetypes` (skip `default` déjà couvert ;
  skip `flutter-firebase` `status: removed_from_roadmap` ; skip
  `mobile-only` `status: legacy_alias` si target = `mobile-pwa-first`
  livré). Pour chaque archétype actif :
  1. `mkdtemp` dans un path **non-existant** (pour exercer le mkdir
     parent du fix v0.3.2 `spawn bash ENOENT`).
  2. `forge init <slug> --archetype <name> --org dev.forge.test
     --target <tmp>` ; exit 0.
  3. Assertion d'une **matrice de fichiers attendus** déclarée
     dans une fixture YAML voisine
     (`cli/test/e2e/archetype-fixtures/<name>.yml`), **pas** en dur dans
     le test. Format suggéré : liste de paths obligatoires + liste de
     paths interdits (cf. `cli/` qui ne doit jamais leaker dans target).
  4. `task --list-all` dans le tmpdir → exit 0 (aurait attrapé le bug
     ligne 67 immédiatement). Skip-pass si `task` absent du PATH, comme
     `t5-otel-app.test.sh` skip-pass `flutter`. La validation YAML
     intégrée à go-task suffit ; pas besoin d'exécuter les tasks.
  5. **Opt-in tighter checks** via `FORGE_E2E_TOOLCHAINS=1` :
     `cargo check --workspace` (full-stack-monorepo, rust-cli-tui),
     `flutter analyze` (full-stack-monorepo, mobile-only / mobile-pwa-first).
     Off par défaut (toolchains absentes en CI minimal).

  Effort : `M`. **Bloque** : tous les bugs v0.3.2 + le bug Taskfile +
  toute régression future de scaffold rendu.
- **T5.1.C — Pre-publish tarball gate.** Nouveau
  `cli/scripts/prepublish-smoke.mjs` qui :
  1. Lance `npm pack` dans `cli/`, capture le tarball produit.
  2. Extrait le tarball dans un tmpdir isolé.
  3. Installe le tarball globalement dans un volume isolé
     (`npm install -g <tarball>` dans un `prefix` tmpdir, ou
     équivalent `npx --no-install <tarball>`).
  4. Relance T5.1.B contre le **binaire installé**, pas contre `dist/`.

  Wiré dans `package.json::prepublishOnly` après `lint && test && bundle`.
  **Bloque** : tout bug d'assets manquants dans `cli/assets/`, tout bug
  qui n'apparaît qu'au binaire publié (ex. : v0.3.0 / v0.3.1 `--eu-tier`).
  Effort : `M`.

### T5.1 — couche D différée à T6 / B.8

La 4ème couche (`forge upgrade` matrix test) est planifiée comme
**B.8.15** (cf. §4.2 ci-dessous) parce qu'elle dépend du snapshot
`full-stack-monorepo / 2.0.0` produit par B.8.2, et que sa vraie valeur
est de couvrir la paire 1.0.0 → 2.0.0 du flagship. Elle reste utile pour
les paires N-1 → N intra-1.x.x mais avec une priorité plus faible que
les couches A/B/C qui débloquent les releases courantes.

### T5.1 — non-objectifs

- **Pas de nouveau standard** versionné (`.forge/standards/*.yaml`) — T5.1
  est de l'outillage CLI, pas une décision architecturale. Le change
  archivé portera `constitution_version: 1.1.0` inchangé.
- **Pas de nouveau Forge agent** — outillage de niveau plomberie, hors
  du périmètre K.x.
- **Pas de toolchain bundle** — les tighter checks (`cargo`, `flutter`,
  `task`) restent opt-in via env-var, jamais installés par le test
  harness lui-même (NFR équivalent à NFR-J7-001 / NFR-K3-DEM-005 :
  zero new external dep + budget ≤ 5 s wall-clock pour T5.1.B sans
  toolchains).

### T5.1 — critères de réussite et release

| Critère                                                      | Outcome                                                              |
|--------------------------------------------------------------|----------------------------------------------------------------------|
| `Taskfile.yml.tmpl:67` corrigé + sweep templates             | `task --list-all` sur scaffold flagship sort en 0                    |
| Golden snapshots flags CLI                                   | `forge {init,upgrade,verify,version} --help` capturés et asserts     |
| Smoke par archétype                                          | Pour chaque archetype non-`removed_from_roadmap`, scaffold + matrice |
| Pre-publish gate                                             | `npm pack` → installation isolée → smoke green avant `npm publish`   |
| Harness `t5-1.test.sh` enregistré dans `forge-ci.yml`         | Matrix CI green sur la PR T5.1                                       |
| Release **v0.3.3** publiée                                    | Tarball `@sdd-forge/cli@0.3.3` + GH release notes                    |

> **Mentor note** : ne sois pas tenté de fusionner T5.1 dans la branche
> `optim` qui accumule P1+P2 vers v0.3.x (cf. ta memory
> `no_pr_before_t2_p1_p2.md`). T5.1 est **additif** sur le CLI, sans
> nouveau archétype ni standard — il peut être livré sur `main` directement
> via une release patch v0.3.3, sans interférer avec la règle d'accumulation.

### T5.1 — extension post-implementation (Option B, 2026-05-16)

> **Lis cette sous-section après §0.1 originale.** Le premier run de
> `task validate` (2026-05-16, le jour-même où le Taskfile est livré) a
> remonté **trois bugs réels** que les couches A/B/C ne pouvaient pas
> attraper par construction. T5.1 est donc **étendu** pour inclure les
> tactical fix-forwards avant la release v0.3.3 (Option B retenue par
> le mainteneur 2026-05-16).

**Bugs détectés par `task validate`** :

1. **Cargo `buffa = "=0.3.3"` pin mort** — crates.io n'a plus que les
   versions 0.5.x / 0.6.0. Pin posé par `t5-connect-codegen`
   (2026-05-06) ; upstream a yank / bumpé en 10 jours. Bloque
   `cargo build` sur tout scaffold flagship frais. Détecté par
   `task smoke-with-toolchains` (FORGE_E2E_TOOLCHAINS=1).
2. **`opentelemetry_sdk` package fantôme** dans le template mobile-only —
   le pkg n'existe pas sur pub.dev. Bloque `flutter pub get` sur tout
   scaffold mobile-only. Découverte adjacente : le pkg réel
   `opentelemetry` (Workiva) est **web-only** — donc inadapté à
   mobile-only ET au frontend Flutter mobile du flagship. Cette
   découverte est plus profonde et est déplacée vers **T5.3**
   ci-dessous (`t5-otel-dartastic-realign`), pas dans T5.1.
3. **Label cosmétique** `✓ version` au lieu de
   `_test_t51_l1_004_snapshots_dir_5files` dans la sortie du harness —
   bash dynamic scoping leak (`for name in …` non-`local`). Patch
   inline dans `cli-trust-harness` (pré-archive).

**Scope ajouté à T5.1** :

- **T5.1.E — `t5-cargo-pin-refresh`** **Done 2026-05-16**. Investigation
  upstream via crates.io REST API a montré que `buffa 0.3.x` s'arrête à
  `=0.3.0` (les versions 0.3.1/0.3.2/0.3.3 n'ont jamais été publiées) ;
  `connectrpc 0.3.3` requiert `buffa = "^0.3"`, donc `=0.3.0` est l'unique
  pin exact satisfaisant. Bumpé `transport.yaml` v1.1.0 → v1.2.0 (additif,
  ADR-T5CPR-002) avec WAIVER comment block rewriting per ADR-T5CPR-003
  (séparation WAIVER connectrpc / CORRECTION buffa). REVIEW.md ledger
  entry. Snapshot tarball régénéré via `bin/forge-snapshot.sh` ; A.7
  29/29 GREEN préservé. Harness `t5-cargo.test.sh` 10 L1 + 1 L2 opt-in,
  10/10 PASS. Modernisation `connectrpc 0.4.x/0.5.x/0.6.x` deferred à
  B.8 (T6). Effort : `S` (livré).
- **T5.1.F — Patch inline label fix dans `cli-trust-harness`**. Ajout
  de `local name` dans `_test_t51_l1_004_snapshots_dir_5files`. Pas
  de nouveau change — le `cli-trust-harness` est en `status: implemented`,
  non encore archivé. Le patch landed dans la même PR. Effort : `XS`.
- **Note sur Bug #2** : la migration `Workiva → Dartastic` est
  **trop lourde** pour entrer dans T5.1 (XL effort) et invalide
  partiellement deux changes T5 archivés. Elle est isolée en **T5.3**.
  T5.1 ne touche **pas** au standard `flutter/opentelemetry.md` ni aux
  fichiers Dart OTel. Adopters mobile-only et flagship Flutter mobile
  continueront à voir le bug OTel jusqu'à v0.4.0-rc.x (T5.3) — c'est
  acceptable parce que :
  - mobile-only n'a aucun adopter production aujourd'hui (B.4 archivé
    2026-04-30, donc adopters early-bird au mieux).
  - Le flagship Flutter mobile vient juste de recevoir le SDK OTel
    (Phase B 2026-05-12) — pas d'adopter en prod non plus.
  - Le `task validate` documenté dans `docs/CONTRIBUTING.md` § Local
    pre-push validation signalera le bug en clair lors de chaque PR,
    impossible à louper.

**Release criterion v0.3.3 amendé** : T5.1 archivé inclut désormais
`cli-trust-harness` (avec T5.1.F inline) **ET** `t5-cargo-pin-refresh`
(T5.1.E). Le bump VERSION 0.3.2 → 0.3.3 + le sealing CHANGELOG
[Unreleased] → [0.3.3] interviennent après ces deux archives.

---

## 0.2 Status update — 2026-05-16 → ✅ Implemented 2026-05-18 (T5.2 — Anti-Hallucination Platform Verification)

> **T5.2 est un changement de processus, pas de code.** Il sert à
> empêcher la classe de bug qui a produit Q-004 (`opentelemetry_sdk`
> fantôme) puis sa pseudo-résolution (`opentelemetry` Workiva, web-only).

> ✅ **Implemented 2026-05-18** via `t5-2-platform-verification`
> (status `implemented`, ready to archive). Toutes les couches
> T5.2.A → T5.2.D livrées ; harness `t5-2.test.sh` 8/8 L1 + 1 L2
> opt-in GREEN ; release target **v0.3.4** (patch). Article III.4
> (Ambiguity Protocol — anti-hallucination) renforcé
> procéduralement, pas amendé. Drift guard ADR-T52-003 enforced via
> les 2 H2 canoniques (`## Platform Verification Checklist (3-axis)`
> + `## Platform compatibility re-verification`) référencées
> verbatim sur 4 surfaces (agent + standards-lifecycle +
> CONTRIBUTING + LINTING). Note d'auto-validation : un code-reviewer
> indépendant pré-archive a attrapé une citation constitutionnelle
> fabriquée ("Article VIII anti-hallucination" → corrigé en
> Article III.4 Ambiguity Protocol) — exactement la classe de bug
> que T5.2 existe pour prévenir, démonstration vivante du process
> review/verify séparés.

### Origine — leçon Q-004 + extension Workiva platform

L'investigation Q-004 (2026-05-11, sibling de `t5-otel-app`) a vérifié
deux axes :

1. Le package **existe** sur pub.dev (`opentelemetry: 0.18.11`).
2. Les **symboles** publiés correspondent à ce que le standard décrit
   (résolu : 9 symboles fabriqués remplacés par 7 symboles vérifiés).

Mais a **omis** un troisième axe :

3. Les **plateformes cibles** sont supportées.

Workiva `opentelemetry` ne supporte que `web` — alors que les
archétypes Forge ciblent Flutter mobile (iOS + Android) en première
classe (full-stack-monorepo, mobile-only). Le ratification Q-004 a
donc validé un pkg structurellement incompatible avec la cible
applicative. La realign `flutter/opentelemetry.md` v1.0.0 → v1.1.0 a
hérité de ce défaut, propagé dans `t5-otel-app` (frontend Flutter
flagship) et `b4-mobile-only` (template mobile-only).

**Constatation** : la procédure document-specialist actuelle vérifie
**l'API surface** mais pas la **platform target compatibility**. C'est
le trou que T5.2 ferme.

### T5.2 — items proposés

**T5.2.A — `document-specialist.md` platform verification checklist**

Mettre à jour `.claude/agents/document-specialist.md` avec une nouvelle
H2 section **« Platform Verification Checklist (3-axis) »**. Chaque
ratification de standard externe DOIT cocher les 3 axes avant de
flipper le statut "verified" :

1. **Existence** — package résolvable sur le registre (pub.dev /
   crates.io / npm / Maven / etc.) avec la version épinglée.
2. **API surface** — symboles documentés correspondent à ceux exposés
   par le pkg réel (via Context7 ou inspection directe).
3. **Platform compatibility** — toutes les plateformes cibles de
   l'archétype ou du standard sont déclarées supportées par le pkg
   (page pub.dev « Platforms » section / `Cargo.toml` `targets` / etc.).
   Si **une** plateforme cible n'est pas listée, marker explicite
   `[PLATFORM MISMATCH:]` et escalation vers ADR.

Format adopté : checklist à 3 cases dans le change `proposal.md`
section "Source Documents" → ligne dédiée par dépendance ratifiée.
Pattern repris dans tous les changes futurs touchant `*.yaml`/`.md`
standards qui pin des deps externes.

**T5.2.B — `standards-lifecycle.md` re-verification cadence**

Bump `.forge/standards/global/standards-lifecycle.md` v1.0.0 →
**v1.1.0** (additif, REVIEW.md entry). Nouvelle section :

> **Platform compatibility re-verification.** Un standard qui pin
> une dépendance externe SHOULD ré-exécuter la 3-axis checklist
> (T5.2.A) lors de chaque re-revue ; MUST la ré-exécuter quand
> l'archétype consommateur **ajoute une plateforme cible** (e.g.
> mobile-pwa-first ajoutant PWA Qwik en T8). Pré-revue : la
> checklist est exécutée *avant* tout ratification de standard
> nouveau ou bumpé.

**T5.2.C — Harness `t5-2.test.sh`**

≥ 6 L1 grep :

- `document-specialist.md` contient la H2 « Platform Verification Checklist »
- La section liste les 3 axes nommés (existence / API surface / platform compatibility)
- `standards-lifecycle.md` v1.1.0 frontmatter
- `standards-lifecycle.md` contient le bloc "Platform compatibility re-verification"
- REVIEW.md ledger contient l'entrée Updated 2026-05-XX
- Tous les standards `.forge/standards/flutter/*.md` qui pin un pkg externe
  documentent les 3 axes dans leur frontmatter ou body (post-T5.3 :
  le seul standard concerné aujourd'hui est `flutter/opentelemetry.md`,
  qui sera bumpé v2.0.0 par T5.3 et héritera de la checklist).

1 L2 opt-in `FORGE_T52_LIVE=1` : exécution de la checklist sur un
pkg pub.dev arbitraire (sanity check de l'outillage Context7 +
WebFetch).

**T5.2.D — Documentation**

- `docs/CONTRIBUTING.md § Adding a Standard` enrichi avec la
  checklist 3-axis.
- `docs/LINTING.md` mentionne la nouvelle règle ratification
  (informative, pas enforcement).

**Effort total** : `S`–`M`. Indépendant de T5.3 — peut land avant ou
après.

---

## 0.3 Status update — 2026-05-16 (T5.3 — `t5-otel-dartastic-realign`)

> **T5.3 corrige le bug architectural OTel** révélé par `task validate`
> et confirmé par investigation pub.dev 2026-05-16 : Workiva
> `opentelemetry 0.18.11` est **web-only** ; l'écosystème **Dartastic**
> (api / dartastic / flutterrific) est **all-platform** et conforme
> spec OTel sur les 3 signaux.

### Origine — Q-006

Q-004 (résolu 2026-05-12 sur Workiva) est **réouvert** par découverte
2026-05-16 de la platform mismatch. Marqué **Q-006** dans le nouveau
change `t5-otel-dartastic-realign` (Q-005 réservée pour l'override
`FORGE_SKIP_PREPUBLISH` de T5.1.C). Q-006 refermé par ADR du change
qui ratifie Dartastic + applique la checklist 3-axis de T5.2.

### Comparatif Workiva vs Dartastic

| Critère                          | Workiva `opentelemetry: 0.18.11`        | Dartastic `dartastic_opentelemetry_api: 0.9.0` (+ 1.0.0-beta.6)               |
|----------------------------------|-----------------------------------------|-------------------------------------------------------------------------------|
| Plateformes Flutter              | **Web only**                            | All (Android, iOS, Linux, macOS, Web, Windows)                                |
| Conformité spec OTel             | Traces Beta / Metrics Alpha / Logs ✗   | 3 signaux ratifiés (Traces / Metrics / Logs)                                  |
| Séparation API / SDK             | Monolithique                            | 3 pkgs : `_api` (no-op) / `dartastic_opentelemetry` (Dart backend) / `flutterrific_opentelemetry` (Flutter) |
| Verified publisher pub.dev       | workiva.com                             | Mindful Software (Michael Bushe)                                              |
| Compatible collector contract    | OUI (OTLP HTTP / protobuf 4318)         | OUI (OTLP HTTP / protobuf 4318)                                               |
| Maintenance active               | OUI                                     | OUI (1.0.0-beta.6 récent)                                                     |

### T5.3 — items proposés

**T5.3.A — Standard bump breaking `flutter/opentelemetry.md` v1.1.0 → v2.0.0**

Réécriture du standard pour ratifier l'écosystème Dartastic :

- Imports canoniques : `package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart` + `package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart`.
- Symboles : `Tracer`, `Span`, `Context`, `Baggage`, `Attributes`,
  `Status`, `SpanKind` — alignés sur la spec OTel verbatim.
- Init API : `OTel.init(...)` ou équivalent flutterrific, à vérifier
  via Context7 lors du design.
- Sampling : aligné collector-side per ADR-OTEL-001 (parent_based +
  trace_id_ratio_based, env-tier overlays). SDK-side : Dartastic
  expose `AlwaysOnSampler`/`AlwaysOffSampler`/`TraceIdRatioBasedSampler`
  conformes spec.
- Plateformes cibles documentées explicitement : Android, iOS,
  Linux, macOS, Web, Windows. **Checklist 3-axis T5.2.A cochée
  inline.**
- REVIEW.md ledger entry : "Updated 2026-05-XX — pkg substitution
  Workiva → Dartastic ; platform mismatch resolution Q-006."
- `breaking_change: true` (substitution de pkg, donc rupture).

**T5.3.B — Flagship `examples/forge-fsm-example/frontend/`**

Réécriture des 5 fichiers Dart OTel dans `lib/core/telemetry/` :

- `telemetry_setup.dart` — init Flutterrific
- `observers/tracing_navigation_observer.dart`
- `observers/tracing_bloc_observer.dart`
- `error_reporter.dart`
- `interceptors/tracing_interceptor.dart`

Plus :

- `pubspec.yaml` : remplacer `opentelemetry: ^0.18.0` par
  `dartastic_opentelemetry_api: ^0.9.0` + `flutterrific_opentelemetry: ^0.9.0`
  (ou versions stables au moment du change).
- `flutter pub get` GREEN attendu.

**T5.3.C — Templates mobile-only**

Réécriture :

- `.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl` —
  remplacer `opentelemetry_sdk: ^0.18.0` (qui n'existe pas) par
  `dartastic_opentelemetry_api` + `flutterrific_opentelemetry`.
- `.forge/templates/archetypes/mobile-only/lib/observability/otel_init.dart.tmpl` —
  remplacer l'import + l'init.
- Mirror dans `cli/assets/`.

**T5.3.D — Snapshot tarball regen (A.7 backward compat)**

Le snapshot `full-stack-monorepo/1.0.0.tar.gz` (archivé pour
A.7 `forge upgrade`) **n'est pas** régénéré (legacy compat stable
1.0.0). Le snapshot **schema candidate** ou le prochain bump
template (post-T5.3 archive) régénère via `npm run bundle` + le
script de re-snapshot habituel.

**T5.3.E — Harness `t5-otel-dartastic.test.sh`**

≥ 12 L1 grep + 1 L2 fixture-based :

- Standard `flutter/opentelemetry.md` v2.0.0 frontmatter
- Standard contient les imports Dartastic canoniques
- Standard contient la checklist 3-axis cochée
- Aucune mention de `opentelemetry: ^0.18` ou Workiva dans le
  template ou les fichiers Dart
- Aucune mention de `opentelemetry_sdk` (le fantôme) nulle part
- REVIEW.md ledger entry
- `flutter/opentelemetry.md::breaking_change: true`
- Mobile-only pubspec.yaml.tmpl pointe sur Dartastic
- FSM frontend pubspec.yaml pointe sur Dartastic
- 5 fichiers Dart côté FSM frontend importent Dartastic
- Mobile-only otel_init.dart.tmpl importe Dartastic
- CHANGELOG entry

L2 opt-in `FORGE_T53_LIVE=1` : exécute `flutter pub get` + `flutter
analyze` sur scaffold mobile-only ET flagship frontend, asserte exit 0.
Skip-pass si `flutter` absent du PATH.

**T5.3.F — Ré-ouverture des changes affectés**

`b4-mobile-only` + `t5-otel-app` + `t5-otel-dart-api-realign`
restent archivés (Article V audit trail préservé), mais **le change
T5.3 ajoute une note de référence** dans chacun via leur
`open-questions.md` ou un fichier `.forge-update-notes` adjacent
documentant la realign. Pattern : ne pas modifier les changes
archivés, ajouter un pointer-forward depuis le change qui corrige.

**Effort total** : `XL`. ~5–8 jours pour 1 dev senior.

**Release target** : **v0.4.0-rc.1** (rupture de standard donc bump
minor en pré-GA selon `docs/VERSIONING.md`). Ne bloque pas v0.3.3
(T5.1 release ne touche pas à Workiva).

**Risque résiduel** : Dartastic est moins déployé que Workiva
(beta 1.0.0 vs stable Workiva). Le SDK `flutterrific_opentelemetry`
n'a peut-être pas le même volume de tests de conformité. **Mitigation**
: dans le change T5.3 design, prévoir un fallback `dartastic` (Dart
backend SDK) si flutterrific s'avère bloquant côté Flutter — Dartastic
expose 3 SDKs au choix.

---

## 0. Executive Summary (1 page)

À la sortie de **v0.3.0** (2026-05-02), Forge a clos T0, T1, T2 P1, T2 P2 et T3 robustesse :
**13 changes archivés**, **292/292 tests** sur 13 harnesses, Constitution v1.1.0,
deux archétypes scaffoldables (`full-stack-monorepo` 1.0.0 et `mobile-only` 1.0.0),
`forge upgrade` non-destructif, `forge init` canonical entry point, gouvernance
BDFL-with-fallback en place, GitHub Discussions ouvert.

`docs/ARCHITECTURE-TARGET.md` (production 2026-04-29, révision v1.1) introduit **trois
décisions structurelles** qui invalident une partie du plan d'origine :

1. **Taxonomie passée de 4 à 5 archétypes** — `flutter-firebase` retiré (Schrems II +
   CLOUD Act), `mobile-only` renommé `mobile-pwa-first` (PWA Qwik + fallback iOS natif),
   deux nouveaux archétypes `event-driven-eu` et `ai-native-rag`.
2. **8 ADR techniques** sur le flagship — Kong → Envoy Gateway, Temporal → DBOS,
   REST/JSON → Connect-RPC, Firebase → Zitadel, Flutter Web public → Qwik, Postgres 17 +
   pgvector universel, SigNoz + OBI + Coroot, flutter_bloc consacré standard unique
   non-négociable.
3. **Compliance EU graduée T1/T2/T3** comme nouvelle dimension de classification par
   composant et par archétype.

**Verdict global** : `full-stack-monorepo / 1.0.0` shippé en v0.3.0 reste valide pour
ses adopters actuels mais devient une **`legacy compat` baseline** ; un schéma `2.0.0`
le remplace en T6 (point de non-retour). Le module B.2 `flutter-firebase` du plan
d'origine est **annulé**. Le module B.4 `mobile-only / 1.0.0` est **renommé** en
`mobile-pwa-first` et étendu avec un canal PWA Qwik. Deux nouveaux modules B.6 et B.7
sont créés. Cinq nouveaux agents Forge sont introduits. Plan de migration **4 phases sur
~6 mois** avec point de non-retour à la phase 2 (Envoy/DBOS/Connect sur la flagship).

> **Mentor note** : tu as livré 13 changes en 11 jours et la moitié du plan d'audit. Le
> risque maintenant n'est pas de manquer d'exécution, c'est de **figer un flagship dont
> les briques internes (Kong/Temporal/REST-bridge) ne survivront pas 18 mois** dans les
> mains de tes adopters EU. Le plan ci-dessous oppose deux options à arbitrer : migration
> additive (legacy compat) vs migration breaking (schema bump 1.0.0 → 2.0.0).

---

## 1. Contexte — état post-v0.3.0

### 1.1 Acquis

| Domaine                                 | État            | Référence                                  |
|-----------------------------------------|-----------------|--------------------------------------------|
| OSS Apache 2.0 + npm + Docker           | ✅ T0/T1         | A1, A2, A3, A4, A5, A6                     |
| `forge init` 3 modes                    | ✅ T2 P1 (B.5.1) | `.forge/scaffolding/dispatch-table.yml`    |
| `forge upgrade` 3-way merge             | ✅ T2 P1 (A.7)   | `bin/forge-upgrade.sh` + snapshot tarballs |
| Archétype `full-stack-monorepo / 1.0.0` | ✅ T2 P1 (B.1)   | 4 changes archivés, schema stable          |
| Archétype `mobile-only / 1.0.0`         | ✅ T2 P2 (B.4)   | `b4-mobile-only` 47/47 tests               |
| Reference project + 4 demos             | ✅ T2 P1 (C.1)   | `examples/forge-fsm-example/`              |
| CI Forge dog-fooded                     | ✅ T2 P1 (G.1)   | `forge-ci.yml` 6 jobs                      |
| Governance BDFL-with-fallback           | ✅ T2 P1 (D.5)   | `GOVERNANCE.md` + Article XII              |
| GitHub Discussions ouvert               | ✅ T2 P1 (D.6)   | community channel actif                    |
| Open questions tracking                 | ✅ T3 (F.1)      | `f1-open-questions`                        |
| YAML schema validation                  | ✅ T3 (F.2)      | `f2-yaml-schema`                           |
| Linter étendu V/X.3/XI.3/XI.5           | ✅ T3 (F.4)      | `f4-linter-extension`                      |
| Release v0.3.0 publiée                  | ✅ 2026-05-02    | tag `v0.3.0`, npm `@sdd-forge/cli@0.3.0`   |

### 1.2 Décisions ratifiées par `docs/ARCHITECTURE-TARGET.md`

| ADR     | Décision                                                          | Statut                           |
|---------|-------------------------------------------------------------------|----------------------------------|
| ADR-001 | REPLACE Kong → Envoy Gateway sur tous les archétypes serveur      | À planifier (T6)                 |
| ADR-002 | Temporal → DBOS par défaut, Temporal réservé `event-driven-eu`    | À planifier (T6)                 |
| ADR-003 | REPLACE REST/JSON Kong-bridge → Connect-RPC                       | À planifier (T6)                 |
| ADR-004 | KEEP Rust + tonic 0.14 + axum 0.8                                 | Acquis                           |
| ADR-005 | KEEP Flutter mobile + desktop, REPLACE Flutter Web public → Qwik  | À planifier (T7)                 |
| ADR-006 | flutter_bloc seul state management autorisé, hors fenêtre 12 mois | Inscrit dans templates B.1 + B.4 |
| ADR-007 | REPLACE Firebase → Zitadel (ou Keycloak/Authentik en alternative) | Annule B.2 du plan d'origine     |
| ADR-008 | KEEP-WITH-CHANGES SigNoz + OBI eBPF + Coroot service map          | À planifier (T7)                 |
| ADR-009 | KEEP buf+proto + ADD Connect codegen + AsyncAPI 3.1 dérivé        | À planifier (T6)                 |
| ADR-010 | Postgres 17 + pgvector 0.8 comme défaut universel                 | À planifier (T6)                 |

### 1.3 Modules du plan d'origine **annulés ou renommés**

| Module d'origine                         | Verdict                                           |
|------------------------------------------|---------------------------------------------------|
| **B.2 `flutter-firebase`**               | **ANNULÉ** — Schrems II + CLOUD Act incompatibles |
| **B.4 `mobile-only`** (déjà livré 1.0.0) | **RENOMMÉ** → `mobile-pwa-first` ; schema `2.0.0` |
| Roadmap `Phase 3 / mobile-only`          | **OBSOLÈTE** (déjà livré sous l'ancien nom)       |
| Roadmap `Phase 3 / flutter-firebase`     | **DEPRIORITIZED** ou retiré                       |

### 1.4 Modules **nouveaux** introduits par ce plan

| Code      | Nom                                                                                                                                                | Source                            | Effort  | Status (2026-05-05)                                                                                                               |
|-----------|----------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|---------|-----------------------------------------------------------------------------------------------------------------------------------|
| B.6       | `event-driven-eu`                                                                                                                                  | ARCHITECTURE-TARGET §3.3          | `XL`    | Pending (T7)                                                                                                                      |
| B.7       | `ai-native-rag`                                                                                                                                    | ARCHITECTURE-TARGET §3.3          | `XL`    | Pending (T7)                                                                                                                      |
| B.8       | Migration flagship 1.0.0 → 2.0.0 (Envoy/DBOS/Connect/Zitadel)                                                                                      | ARCHITECTURE-TARGET §11           | `XL`    | Pending (T6 — point of no return)                                                                                                 |
| B.9       | Migration `mobile-only / 1.0.0` → `mobile-pwa-first / 2.0.0` (PWA Qwik + Bloc renforcé)                                                            | ARCHITECTURE-TARGET §6.3          | `L`     | Pending (T8)                                                                                                                      |
| I.1       | Compliance EU graded — JSON schemas (T1/T2/T3 + archetype v2)                                                                                      | ARCHITECTURE-TARGET §10           | `S`     | **Done 2026-05-04** via `t4-adr-ratification`                                                                                     |
| I.2–I.6   | Compliance EU graded — standard `compliance-tiers.md`, linter rule, Demeter agent, `forge-compliance.yml` workflow, NIS2/DORA/CRA/AI Act artefacts | ARCHITECTURE-TARGET §10           | `M`–`L` | I.2 **Done 2026-05-12** via `i2-compliance-tiers` (`global/compliance-tiers.md` v1.0.0 + index entry + REVIEW birth + `docs/COMPLIANCE.md` + 14/14 L1 tests `i2.test.sh`). I.6 **Done 2026-05-12** via `i6-compliance-artefacts` (`.forge/scripts/compliance/bundle.sh` deterministic .tgz + DPA template + standard `global/compliance-artefacts-bundle.md` v1.0.0 + 16/16 tests `i6.test.sh --level 1,2`). I.3 **Done 2026-05-12** via `i3-t3-forbidden-linter` (`constitution-linter.sh::ADR-I3-001` section + standard `global/forbidden-components-rules.md` v1.0.0 with 10 `T3-RULE-001..010` rules + tier-scaled severity T1/T2 warn → T3 fail immediate + 14/14 L1 tests `i3.test.sh` ; resolves I.2 `linter_rule:` forward-pointer ; unblocks I.5). I.5 **Done 2026-05-12** via `i5-compliance-workflow` (reusable `.github/workflows/forge-compliance.yml` `on: workflow_call:` with 3 inputs / 1 output, orchestrant Demeter + linter + SBOM + bundle, upload `.tgz` via `actions/upload-artifact@v4`, standard `global/forge-compliance-workflow.md` v1.0.0 7 H2 + 4 MUST NOT + 8 triggers, 17/17 tests `i5.test.sh --level 1,2` incl. L2 act-opt-in skip-pass ; trois ADRs résolvent exit-code aggregation + SOURCE_DATE_EPOCH source + L2 gating). NIS2/DORA/CRA/AI Act regulatory deadline artefacts encore en attente — déférés à Themis (K.5, T7+) ; le bundle I.6 + workflow I.5 sont forward-stable pour les absorber additivement. |
| J.1–J.6   | Six standards versionnés `.forge/standards/*.yaml` (transport / state-management / observability / orchestration / identity / persistence) v1.0.0  | ARCHITECTURE-TARGET §12.1         | `M`     | **Done 2026-05-04** via `t4-adr-ratification` ; J.1 `transport.yaml` bumpé en 1.1.0 le 2026-05-06 par `t5-connect-codegen` (codegen pinning, additif) |
| J.7 / J.8 | `validate-standards-yaml.sh` linter + Janus forbidden-list orchestrator rules + `--eu-tier` flag + CycloneDX SBOM | ARCHITECTURE-TARGET §12.1 + §12.5 | `S`–`L` | J.7 **Done 2026-05-08** via `j7-validate-standards-yaml` (PR #4 merged) ; J.8 (a + b + d) **Done 2026-05-10** via `j8-janus-rules` (20/20 tests, +6 PASS verify.sh, smoke 74 SBOM components) ; J.8.c (`ai-native-rag` LLM gateway rules) deferred to T7 |
| T5.1 | **CLI Trust Harness** — fix `Taskfile.yml.tmpl` + couches A (golden flags) + B (smoke par archétype) + C (pre-publish tarball gate). Couche D différée à B.8.15.                                                  | Issue post-v0.3.0 / v0.3.1 / v0.3.2 release pain | `M`     | **Partially done 2026-05-14** via `cli-trust-harness` — 17/17 L1 + 2 L2 opt-in dans `t5-1.test.sh`. **Extended 2026-05-16** par Option B (T5.1.E `t5-cargo-pin-refresh` + T5.1.F label fix inline). Pre-v0.3.3 release. Détails §0.1. |
| T5.2 | **Anti-Hallucination Platform Verification** — checklist 3-axis dans `document-specialist.md` + cadence re-verification dans `standards-lifecycle.md` v1.1.0 + harness `t5-2.test.sh`. Process change pour empêcher Q-004 / Q-006-class bugs. | Q-006 (Workiva web-only platform mismatch découvert 2026-05-16) | `S`–`M` | **Planned 2026-05-16** — détails §0.2. Indépendant de T5.1 / T5.3, peut land avant ou après. |
| T5.3 | **`t5-otel-dartastic-realign`** — substitution Workiva `opentelemetry` (web-only) → écosystème **Dartastic** (`dartastic_opentelemetry_api` + `flutterrific_opentelemetry`, all-platform). Bump `flutter/opentelemetry.md` v1.1.0 → v2.0.0 (breaking). Rewrite flagship Flutter frontend OTel + mobile-only OTel template. Applique la checklist T5.2.A. | Q-006 résolution + bug architectural mobile/desktop OTel | `XL` | **Planned 2026-05-16** — target v0.4.0-rc.1 (rupture standard). Ne bloque pas v0.3.3. Détails §0.3. |
| K.1       | Hermes-Async (event-driven)                                                                                                                        | ARCHITECTURE-TARGET §9.2          | `M`     | Pending (T7)                                                                                                                      |
| K.2       | Pythia (AI/RAG)                                                                                                                                    | ARCHITECTURE-TARGET §9.2          | `M`     | Pending (T7)                                                                                                                      |
| K.3       | Demeter (data steward EU)                                                                                                                          | ARCHITECTURE-TARGET §9.2          | `M`     | **Done 2026-05-12** via `k3-demeter` (persona + scanner + deny-list + standard + Janus delta ; 22/22 tests `k3.test.sh --level 1,2`) |
| K.4       | Iris-Web (Qwik/SvelteKit)                                                                                                                          | ARCHITECTURE-TARGET §9.2          | `M`     | Pending (T7)                                                                                                                      |
| K.5       | Themis (compliance officer)                                                                                                                        | ARCHITECTURE-TARGET §9.2          | `M`     | Pending (T7) — automation `forge review-standards` ; cycle 12 mois lui-même livré (P-3)                                           |

---

## 2. Pré-requis méthodologiques (avant T4)

Ces items sont des **gates** : aucun module B.6/B.7/B.8/B.9 ne démarre sans eux.

> **Statut au 2026-05-05** : **P-1, P-2, P-3, P-4 ont tous été livrés
> consolidés** dans le change `t4-adr-ratification` (archivé 2026-05-04, PR #2).
> Les sous-sections ci-dessous décrivent l'**intention initiale** et restent
> utiles comme audit trail. Les écarts d'exécution (notamment P-1 livré en
> 1 change consolidé plutôt que 10 ADR séparés) sont annotés in-line.

### 2.1 P-1 — Capture publique des décisions ARCHITECTURE-TARGET

- Convertir les **10 ADR** du document d'architecture en `.forge/changes/<adr-N>/` avec
  `proposal.md` + `specs.md` + `design.md` + ratification trace dans
  `.forge.yaml` (status `archived` car la décision est déjà prise par le document).
- Ce dog-fooding inversé met les ADR sous Constitution v1.1.0 et permet à
  `forge upgrade` d'instancier la migration plus tard. Effort : `M`.

> ✅ **Done 2026-05-04** — exécuté **consolidé en 1 change** (`t4-adr-ratification`)
> plutôt qu'en 10 changes séparés. Audit trail Article V préservé via 35 ADDED FRs
> (`FR-T4-ADR-001..010` couvrent les 10 ADRs ; les autres FRs couvrent standards,
> lifecycle, schémas, tests, dispatch, doc). Trade-off assumé : un seul archivage,
> moins de churn de cross-référencement, mais les 10 ADR ne sont plus instanciables
> à la pièce par `forge upgrade`. Reverse possible si besoin via `forge upgrade`
> 3-way merge sur le tarball snapshot pré-T4 (le change `a7-forge-upgrade` couvre
> ce cas).

### 2.2 P-2 — Standards versionnés `.forge/standards/*.yaml`

Six fichiers YAML à créer/migrer **avant** d'éditer un seul template :

- `transport.yaml` — Connect-RPC, buf, proto pinning, derived OpenAPI 3.1 + AsyncAPI 3.1
- `state-management.yaml` — flutter_bloc + interdiction Riverpod/Provider/GetX/MobX/states_rebuilder + linter
  `no-state-management-alternatives` bloquant
- `observability.yaml` — OTel SDK + OBI eBPF + Coroot + SigNoz + sampler `parentbased_traceidratio`
- `orchestration.yaml` — DBOS default, Temporal fallback (
  `workflow_volume_per_day_gt_10000 OR cross_service_count_gt_10`)
- `identity.yaml` — Zitadel default, Keycloak/Authentik alternatives, Firebase Auth interdit
- `persistence.yaml` — Postgres 17 + pgvector + extensions, Citus pour sharding,
  DynamoDB/Firestore/Cosmos interdits en T2/T3 strict

Le linter `constitution-linter.sh` est étendu pour vérifier les `forbidden:` listées.
Effort : `M` (J.1-J.5 du tableau §1.4).

> ✅ **Done 2026-05-04** (corps du standard) — six fichiers YAML v1.0.0 livrés
> via `t4-adr-ratification` (`transport`, `state-management`, `observability`,
> `orchestration`, `identity`, `persistence`) avec frontmatter uniforme
> (`version` / `last_reviewed` / `expires_at` / `exception_constitutional` /
> `linter_rule` / `enforcement` / `forbidden` / `rationale`) — le tableau §1.4
> est devenu **J.1–J.6** (six standards, pas cinq : `persistence.yaml` ajouté
> à la spec initiale).
> ✅ **J.7 Done 2026-05-08** via `j7-validate-standards-yaml` —
> `bin/validate-standards-yaml.sh` linter (Phase 1 schema +
> Phase 2 lifecycle invariants en une passe), schéma JSON
> Draft 2020-12 à `.forge/schemas/standard.schema.json`,
> `verify.sh` § "Standards YAML Schema" (+7 PASS sur live tree),
> harness `j7.test.sh` 21/21 GREEN à `--level 1,2`.
> ⏸️ **Pending T5** : J.8 (Janus orchestrator rules §
> ARCHITECTURE-TARGET §12.5 : refus `flutter-firebase`, force
> self-host Zitadel/SigNoz si `--eu-tier=T3`, force Mistral-EU ou
> vLLM si `ai-native-rag` + T3, génération SBOM CycloneDX).
>
> Note : `transport.yaml` a été bumpé en **1.1.0** le 2026-05-06 par
> `t5-connect-codegen` (codegen pinning, additif — pas de
> `breaking_change: true`). Le ledger `.forge/standards/REVIEW.md` a reçu
> une entrée `Updated` (pas une re-revue complète).

### 2.3 P-3 — Cycle de réévaluation 12 mois

- `.forge/standards/REVIEW.md` : chaque entrée standard porte une **date d'expiration**
  par défaut 12 mois.
- Agent **Themis** (nouveau, K.5) exécute `forge review-standards` mensuel et signale
  les standards à revisiter.
- **Exception explicite** : `state-management.yaml` (flutter_bloc) et `transport.yaml`
  (proto/Connect) sont des décisions **structurelles** non soumises à la fenêtre
  12 mois ; ne peuvent être amendées que par procédure constitutionnelle (Article XII).
- Inscrit dans le standard `global/standards-lifecycle.md` (nouveau). Effort : `S`.

> ✅ **Done 2026-05-04** via `t4-adr-ratification` — `global/standards-lifecycle.md`
> standard livré + `.forge/standards/REVIEW.md` ledger append-only avec entrée
> seed (4 standards `Next review due: 2027-05-04`, 2 standards
> `never (structural)` : `transport.yaml` ADR-006/ADR-009 + `state-management.yaml`
> ADR-006).
> ⏸️ **L'agent Themis (K.5) lui-même reste pending** (T7) — sans Themis,
> `forge review-standards` n'est pas automatisé. Le mainteneur tient le calendrier
> manuellement jusqu'à K.5 livré.

### 2.4 P-4 — Schéma de classification compliance

- `.forge/schemas/compliance-tier.schema.json` : enum `[T1, T2, T3]`.
- `.forge/schemas/archetype.schema.json` v2 : ajout enum
  `[full-stack-monorepo, mobile-pwa-first, event-driven-eu, ai-native-rag, rust-cli-tui]`.
  La valeur `mobile-only` reste reconnue comme alias rétro-compatible jusqu'à T7.
- Effort : `S` (I.1).

> ✅ **Done 2026-05-04** via `t4-adr-ratification` — les deux schémas livrés.
> `archetype.schema.json` est en **v2.0.0** (et non v2 implicite) avec
> `x-removed-from-taxonomy.flutter-firebase` documentant la décision ADR-007.
> Échéance d'alias `mobile-only` repoussée à **T8** (B.9, dépendant de
> `mobile-pwa-first / 2.0.0`) — pas T7 comme initialement écrit. Cohérent avec
> le `forge upgrade` de A.7 : un adopter B.4 actuel (`mobile-only / 1.0.0`)
> peut rester immobile jusqu'à T8 avant d'être incité à migrer.

### 2.5 P-5 — *RETIRÉ 2026-05-06*

> ⛔ **Définitivement retiré** par le mainteneur le 2026-05-06.
> L'argument ARCHITECTURE-TARGET (« multiplier les sub-agents donne l'illusion de coverage »)
> est rejeté : la spécialisation Hera 9 sub-agents (Athena, Spartan, Apollo, Hephaestus,
> Hermes, Iris, Argus, Prometheus, Nemesis) reste en place. Aucun refactor 9 → 5 ne sera
> exécuté en T6 ni ultérieurement. P-5 disparaît du backlog.

---

## 3. Module B révisé — taxonomie 5 archétypes

### 3.1 B.1 `full-stack-monorepo` — `KEEP-WITH-CHANGES`

- **`full-stack-monorepo / 1.0.0`** (livré v0.3.0) : Kong + Temporal + REST-bridge,
  reste supporté en `legacy compat` jusqu'à T8 (≈ 6 mois après bascule 2.0.0).
- **`full-stack-monorepo / 2.0.0`** (B.8 nouveau) : Envoy Gateway + DBOS + Connect-RPC
    + Zitadel + Postgres+pgvector + SigNoz+OBI+Coroot + Qwik public web (back-office
      Flutter Web conservé).
- Migration via `forge upgrade` (A.7) + script dédié `bin/forge-migrate-flagship.sh`.
- Voir §4 pour le détail B.8.

### 3.2 B.2 `flutter-firebase` — `REMOVE`

- **Annulé** (Schrems II + CLOUD Act + brand premium EU).
- Tous les items B.2.1–B.2.12 du plan d'origine sont retirés du backlog.
- L'archétype actuel `default` (file-copy minimal) reste l'option pour les utilisateurs
  hors EU qui veulent Firebase ; ils peuvent l'ajouter eux-mêmes.
- Si la demande émerge d'une cible EU → considérer un archétype futur
  `flutter-baas-eu` (Supabase EU self-host ou Appwrite). **Pas committé**.
- Effort : `S` (juste retirer la ligne placeholder de `dispatch-table.yml`,
  marquer la décision dans CHANGELOG + `docs/ARCHETYPES.md`).

### 3.3 B.3 `rust-cli-tui` — `KEEP`

- Inchangé du plan d'origine (B.3.1 → B.3.14).
- Effort : `XL`. Reste à livrer.

### 3.4 B.4 → renommé `mobile-pwa-first` — `KEEP-WITH-CHANGES`

- **`mobile-only / 1.0.0`** (livré v0.3.0) reste supporté comme schéma legacy.
- **`mobile-pwa-first / 2.0.0`** (B.9 nouveau) : ajout d'un canal PWA Qwik en plus
  de Flutter iOS+Android, avec décideur par défaut PWA + fallback natif iOS si push
  critique. flutter_bloc reste seul state management côté natif. Voir §5.
- Effort : `L`.

### 3.5 B.6 `event-driven-eu` — `NEW`

- Stack : Rust (axum + async-nats) + NATS JetStream + Temporal (justifié ici par
  cardinality cross-service) + AsyncAPI 3.1 + Postgres event store + Postgres+DBOS pour
  workflows monorepo.
- Cibles : RGPD + NIS2 + DORA + CRA. Profil compliance `T2/T3` recommandé.
- Voir §6.1 pour le détail des items B.6.1–B.6.14.
- Effort : `XL`.

### 3.6 B.7 `ai-native-rag` — `NEW`

- Stack : Rust (axum + DBOS) + LLM gateway (Mistral on Scaleway / vLLM EU
  self-host pour T3, OpenAI proxy en T1) + Postgres + pgvector 0.8 + MCP servers +
  Qwik streaming UI + Flutter optionnel.
- Cibles : RGPD + AI Act + DORA si finance. Profil compliance `T2/T3`.
- Voir §6.2 pour le détail des items B.7.1–B.7.14.
- Effort : `XL`.

### 3.7 Matrice cible × workload × profil d'équipe (cible 2026)

| Archétype             | Web              | Mobile                      | Desktop            | Workload              | Profil équipe min                  |
|-----------------------|------------------|-----------------------------|--------------------|-----------------------|------------------------------------|
| `full-stack-monorepo` | ✅ Flutter+Qwik   | ✅ Flutter                   | ✅ Flutter/Tauri    | CRUD sync premium     | 4–6 dev (1 Rust, 2 Flutter, 1 SRE) |
| `mobile-pwa-first`    | ✅ PWA Qwik       | ✅ PWA + native fallback iOS | ⚠️ PWA installable | App grand public      | 2–3 dev fullstack                  |
| `event-driven-eu`     | ⚠️ admin Qwik    | ❌                           | ❌                  | Pub/sub, sagas, audit | 3–5 dev backend Rust               |
| `ai-native-rag`       | ✅ Qwik streaming | ⚠️ Flutter optionnel        | ❌                  | LLM+RAG+agentic       | 2–4 dev (1 ML, 2 Rust)             |
| `rust-cli-tui`        | ❌                | ❌                           | ✅ binary natif     | Devtools              | 1–2 dev Rust                       |

---

## 4. Module B.8 — Migration flagship 1.0.0 → 2.0.0

Module pivot. Le plus risqué de tout le plan post-v0.3.0. **Point de non-retour** à la
fin de B.8.

### 4.1 Stratégie

Migration **additive d'abord, breaking ensuite** :

1. Ajouter Envoy Gateway en parallèle de Kong (canary par route).
2. Ajouter DBOS embedded library en parallèle de Temporal.
3. Ajouter Connect-RPC handlers en parallèle de REST-bridge.
4. Ajouter Zitadel auth en parallèle de l'auth implicite actuelle (s'il y en a).
5. Migrer les 4 demos de `examples/forge-fsm-example/` une par une.
6. Une fois validé, **bump schema 1.0.0 → 2.0.0** + retirer Kong/Temporal/REST-bridge.
7. `forge upgrade` propose la migration via `[NEEDS MIGRATION:]` (mécanisme A.7 déjà
   en place). Adopters legacy peuvent rester sur 1.0.0 jusqu'à T8 (deprecation).

### 4.2 Items B.8.x

- **B.8.1.** Audit `examples/forge-fsm-example/` : capturer baseline p95/p99 (latence
  end-to-end Flutter → Kong → Rust → Postgres), couverture trace W3C, MTBF Temporal
  workers. Effort : `S`.
- **B.8.2.** Snapshot tarball `full-stack-monorepo/1.0.0.tar.gz` archivé définitivement
  dans `.forge/scaffold-snapshots/legacy/` pour garantir `forge upgrade` reverse.
  Effort : `S`.
- **B.8.3.** Schema `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (status `candidate`
  jusqu'à validation). Effort : `M`.
- **B.8.4.** Templates Helm Envoy Gateway sous `templates/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/`
  avec `Gateway`, `HTTPRoute`, `BackendTLSPolicy` Gateway API natifs. Helm chart
  Atlas-fourni. Effort : `M`.
- **B.8.5.** Templates DBOS embedded — `Cargo.toml` ajout `dbos = "0.x"` (épingler
  version au commit du standard `orchestration.yaml`), boilerplate Rust pour
  `DBOSContext`, init Postgres state tables. Effort : `M`.
- **B.8.6.** Templates Connect-RPC : `buf.gen.yaml` étendu avec
  `protoc-gen-connect-go`, `protoc-gen-connect-es`, `protoc-gen-connect-dart-community`.
  `tonic-build` continue côté serveur Rust (compat native). Effort : `M`.
- **B.8.7.** Templates Zitadel : Helm chart self-host EU + script de bootstrap
  (création tenant root, OIDC client app, JWT signing key rotation). Documentation
  pour T1 (Zitadel Cloud SaaS) vs T2/T3 (self-host EU strict). Effort : `M`.
- **B.8.8.** Templates SigNoz + OBI + Coroot dans
  `docker-compose.dev.yml` + Helm overlays K8s prod. Sampler 100% staging /
  10% prod. Audit Aegis sur le DaemonSet privilégié OBI requis. Effort : `M`.
- **B.8.9.** Templates Qwik public web sous
  `templates/full-stack-monorepo/2.0.0/web-public/` avec Connect-ES client + Connect codegen.
  Flutter Web reste en `web-backoffice/`. Janus arbitre les deux. Effort : `L`.
- **B.8.10.** Migration scripts `bin/forge-migrate-flagship.sh` orchestrant les 4 phases
  ARCHITECTURE-TARGET §11 (Phase 0 audit, Phase 1 obs+contrats, Phase 2 bascule
  Envoy/DBOS/Bloc, Phase 3 nouveaux archétypes, Phase 4 deprecation). Hooks dans
  `forge upgrade`. Effort : `L`.
- **B.8.11.** Linter `no-state-management-alternatives` (Hera) — refuse tout import
  Flutter de `flutter_riverpod`, `riverpod`, `provider`, `get`, `getx`, `mobx`,
  `flutter_mobx`, `states_rebuilder`. Échec CI bloquant. Pre-commit hook. Effort : `S`.
- **B.8.12.** Tests E2E migration : `c1-reference-project` migré vers 2.0.0, captures
  p95/p99 avant/après, 0 régression sur les 4 demos. Effort : `M`.
- **B.8.13.** Critères de rollback documentés (ARCHITECTURE-TARGET §11.3) :
    - p99 augmente > 20 % après Envoy → rollback Kong.
    - Erreurs traceparent > 1 % → rollback OTel SDK seul.
    - DBOS Postgres saturé > 70 % CPU → fallback Temporal pour workflows lourds.
      Effort : `S`.
- **B.8.14.** Bump schema `1.0.0` → `2.0.0` + amendement Constitution si nécessaire
  (Article XII). Annoncer la deprecation 1.0.0 à T+6 mois (CHANGELOG + `GOVERNANCE.md`
  release process). Effort : `S`.
- **B.8.15.** **T5.1 couche D — `forge upgrade` matrix test.** Test e2e matriciel
  couvrant chaque paire N-1 → N de la flagship (et symétriquement pour les autres
  archétypes shippés). Prérequis : T5.1.0 / .A / .B / .C livrés (cf. §0.1). Une
  cellule par paire dans une matrice GitHub Actions :
    1. Scaffold d'un projet sur le tarball snapshot `full-stack-monorepo/1.0.0.tar.gz`
       (réutilise B.8.2 + l'API A.7 `forge-upgrade.sh`).
    2. `forge upgrade --target <tmp>` vers la version HEAD du framework.
    3. Assertion : `upgrade_history` ledger append-only, `.merge-conflicts` vide,
       `scaffold-manifest.yaml::archetype_version` bumpé, **smoke T5.1.B re-run**
       sur l'arbre upgradé (matrice de fichiers + `task --list-all`).
    4. Cas négatif explicite : tentative d'upgrade 1.0.0 → 2.0.0 sans `--force`
       doit produire `[NEEDS MIGRATION:]` et exit non-zéro (mécanisme A.7 déjà
       en place). Cas négatif `force` : `--force` sur Git tree sale doit refuser
       (déjà testé dans `a7.test.sh` mais re-validé en e2e contre le binaire).
  Bloque toute régression silencieuse de migration. Particulièrement critique
  pour B.8 (1.0.0 → 2.0.0, point de non-retour). Effort : `M`. Critère de
  réussite : matrice cellules `1.0.0→2.0.0`, `mobile-only/1.0.0→mobile-pwa-first/2.0.0`
  (depuis B.9), et `event-driven-eu` / `ai-native-rag` une fois shippés en T7,
  toutes green en CI avant `npm publish` v0.4.0.

**Total B.8 : `XL`**, ~10–12 semaines pour 1 dev senior + revues Atlas/Aegis.

---

## 5. Module B.9 — `mobile-only / 1.0.0` → `mobile-pwa-first / 2.0.0`

### 5.1 Stratégie

`mobile-only / 1.0.0` (livré T2 P2) couvre déjà OIDC + flutter_appauth + Keychain/
Keystore + biometric + App Attest + Play Integrity. Il manque le **canal PWA Qwik**
prescrit par ARCHITECTURE-TARGET §6.3 : PWA installable Android + desktop + iOS
fallback natif si push critique.

### 5.2 Items B.9.x

- **B.9.1.** Schema `.forge/schemas/mobile-pwa-first/2.0.0.yaml` (`mobile-only / 1.0.0`
  reste comme alias). Effort : `S`.
- **B.9.2.** Sous-dossier `web-pwa/` ajouté à l'arborescence — Qwik City + Service
  Worker + Web Push (VAPID) + manifest.json + icons + offline shell. Effort : `M`.
- **B.9.3.** Templates partagés OIDC : le `AuthGateway` actuel (Flutter) est doublé
  d'un client TypeScript Connect-ES (Qwik) qui parle au même provider OIDC via
  `authorization_code + PKCE`. Effort : `M`.
- **B.9.4.** Décideur par défaut documenté : si plateforme `Web|Android` → PWA Qwik ;
  si plateforme `iOS` ET push critique → fallback Flutter natif iOS. Documenté dans
  `docs/ARCHETYPES.md` avec arbre de décision. Effort : `S`.
- **B.9.5.** flutter_bloc renforcé : générateurs Hera produisent
  `Event`/`State`/`Bloc` + `bloc_test` à partir des proto messages. Effort : `S`.
- **B.9.6.** Linter `no-state-management-alternatives` activé sur ce schéma (cohérent
  avec B.8.11). Effort : déjà fait par B.8.11.
- **B.9.7.** Workflows CI Fastlane (existants) + ajout d'un job `pwa-deploy` ciblant
  un canal de preview Cloudflare Pages / Vercel / OVH-managed (au choix). Effort : `M`.
- **B.9.8.** Snapshot tarball `mobile-pwa-first/2.0.0.tar.gz`. Effort : `S`.
- **B.9.9.** Migration script `bin/forge-migrate-mobile-pwa.sh` qui prend une install
  `mobile-only / 1.0.0` et ajoute `web-pwa/` sans toucher au natif existant.
  Effort : `S`.
- **B.9.10.** Documentation : `docs/MIGRATION-PATHS.md` enrichi avec
  `mobile-only → mobile-pwa-first` (contrairement au plan d'origine qui listait
  cette migration comme `M`, c'est ici trivialisée par B.9.9). Effort : `S`.
- **B.9.11.** Harness `b9.test.sh` : 25–30 tests L1 + 5 L2 fixture. Effort : `S`.

**Total B.9 : `L`**, ~3–4 semaines.

---

## 6. Modules B.6 + B.7 — nouveaux archétypes

### 6.1 B.6 `event-driven-eu` (NATS + Temporal + AsyncAPI)

- **B.6.1.** Schema `.forge/schemas/event-driven-eu/1.0.0.yaml` étend `tdd-rust`
  avec phases `event-design` (specs AsyncAPI 3.1 avant design) et
  `saga-orchestration` (workflows Temporal). Effort : `S`.
- **B.6.2.** Scaffolder `/forge:init --archetype event-driven-eu` : workspace Rust
  (axum + async-nats + tonic + Temporal Go SDK via FFI ou client REST), NATS JetStream
  cluster Helm chart, AsyncAPI 3.1 in `shared/asyncapi/`, Postgres event store, Temporal
  cluster optionnel. Effort : `L`.
- **B.6.3.** Standards :
    - `standards/global/event-driven.md` — patterns saga / process manager / outbox /
      inbox, idempotency keys, event versioning.
    - `standards/global/asyncapi-contracts.md` — versioning AsyncAPI 3.1, validation buf
      breaking equivalent (TBD : `asyncapi-cli` validate).
    - `standards/infra/nats-jetstream.md` — clustering, RAFT, persistence,
      consumer groups.
      Effort : `M`.
- **B.6.4.** Nouvel agent **Hermes-Async** (K.1) : maintient AsyncAPI specs, génère
  bindings NATS/Kafka, pose les idempotency keys. Effort : `M`.
- **B.6.5.** Templates pipelines CI : workflows par layer
  (`forge-events.yml`, `forge-workflows.yml`, `forge-infra.yml`). Effort : `M`.
- **B.6.6.** Templates Helm Temporal cluster (history/matching/frontend/worker) avec
  Postgres backing. Documentation T2/T3 (self-host EU). Effort : `M`.
- **B.6.7.** Snapshot tarball + harness `b6.test.sh` (≥ 35 tests). Effort : `M`.
- **B.6.8.** Reference project `examples/forge-eda-example/` avec 3 demos :
  ingestion HTTP → NATS, projection event store → read model, saga 3-steps. Effort : `L`.
- **B.6.9.** Compliance hooks : SBOM CycloneDX auto-generation, NIS2 incident reporting
  template, DORA RoI submission helper. Effort : `M`.
- **B.6.10.** Standard interdiction : pas de Kafka SaaS US (Confluent Cloud), Redpanda
  acceptable (Cloud Native Computing Foundation, EU deployable). Effort : `S`.

**Total B.6 : `XL`**, ~10 semaines.

### 6.2 B.7 `ai-native-rag` (pgvector + LLM gateway + MCP)

- **B.7.1.** Schema `.forge/schemas/ai-native-rag/1.0.0.yaml` étend `ai-first` avec
  phases `embeddings-pipeline` (specs pipeline avant design) et
  `prompt-audit` (gates). Effort : `S`.
- **B.7.2.** Scaffolder `/forge:init --archetype ai-native-rag` : workspace Rust
  (axum + DBOS), Postgres + pgvector 0.8 + HNSW indexes pré-câblés, LLM gateway proxy
  (Mistral on Scaleway / vLLM EU / OpenAI fallback), MCP servers stub
  (`db`, `file`, `search`), Qwik streaming UI (SSE / WebTransport). Effort : `XL`.
- **B.7.3.** Standards :
    - `standards/global/rag-patterns.md` — chunking, embeddings, retrieval (BM25 + vector),
      re-ranking, context window management.
    - `standards/global/llm-gateway.md` — proxy patterns, prompt audit logs, BYOK,
      tenant-scoped budgets, kill switch.
    - `standards/global/mcp-servers.md` — protocole, sécurité (sandboxing), versioning,
      auth.
      Effort : `M`.
- **B.7.4.** Nouvel agent **Pythia** (K.2) : pilote embeddings pipeline, tune pgvector
  (HNSW `ef_search`), MCP servers, prompt audit. Effort : `M`.
- **B.7.5.** Templates compliance AI Act : classification de risque, transparence
  (model card jointe au build), évaluation biais (dataset cards), opt-out training.
  Effort : `M`.
- **B.7.6.** Snapshot tarball + harness `b7.test.sh` (≥ 35 tests). Effort : `M`.
- **B.7.7.** Reference project `examples/forge-rag-example/` avec 3 demos :
  RAG simple (retrieval + LLM), agentic loop (tool calls via MCP), streaming UI.
  Effort : `L`.
- **B.7.8.** Compliance hooks : DORA + AI Act artefacts (incident reporting < 24h,
  SBOM, vuln handling, model evaluation reports). Effort : `M`.
- **B.7.9.** Standard interdiction : pas de Vertex AI / Bedrock par défaut
  (CLOUD Act). Mistral / Anthropic via gateway acceptable T1 ; Mistral on Scaleway
  ou vLLM self-host requis pour T3. Effort : `S`.
- **B.7.10.** Templates Qwik streaming patterns : SSE, WebTransport, cancel-on-unmount,
  retry exponentiel. Effort : `M`.

**Total B.7 : `XL`**, ~10–12 semaines.

---

## 7. Module I — Compliance EU graduée T1/T2/T3 *(nouveau)*

Source : ARCHITECTURE-TARGET §10.

### 7.1 Items I.x

- **I.1.** Schémas JSON `compliance-tier.schema.json` et `archetype.schema.json` v2
  (cf. P-4). Effort : `S`.
- **I.2.** Standard `global/compliance-tiers.md` documente les définitions T1/T2/T3
  (RGPD via DPA / self-hostable / EU strict SecNumCloud) et les composants éligibles
  par tier (matrice §10.2). Effort : `M`.
- **I.3.** Linter rule : refuser tout `.forge/changes/<name>/.forge.yaml` avec
  `compliance_tier: T3` qui scaffolde un composant interdit T3 (Firebase, Datadog,
  AWS managed services, OpenAI-direct sans gateway). Effort : `M`.
- **I.4.** Nouvel agent **Demeter** (K.3) : data steward EU, classifie données T1/T2/T3,
  valide DPA, détecte CLOUD Act risks dans dépendances `Cargo.toml` /
  `pubspec.yaml` / `package.json`. Effort : `M`.
- **I.5.** Templates `.github/workflows/forge-compliance.yml` qui exécute Demeter +
  SBOM CycloneDX + scanners de licences sur chaque PR. Effort : `M`.
- **I.6.** Échéances réglementaires inscrites dans `.forge/compliance/` :
    - NIS2 reporting 24h/72h
    - DORA RoI ESA submission 30 avr 2026
    - CRA reporting 11 sept 2026, full requirements 11 déc 2027
    - AI Act phases 2025–2027 par catégorie de risque
      Documentation `docs/COMPLIANCE.md`. Effort : `M`.

**Total I : `L`**, ~4–6 semaines.

---

## 8. Module J — Standards versionnés *(nouveau)*

Cf. P-2. Six fichiers YAML versionnés avec metadata `version`, `last_reviewed`,
`expires_at`, `forbidden:` lists, `linter_rule:`, `enforcement:` (pre-commit / CI),
`exception_constitutional: true|false`.

- **J.1.** `transport.yaml` (Connect-RPC). Effort : `S`.
- **J.2.** `state-management.yaml` (flutter_bloc + interdictions). Effort : `S`.
- **J.3.** `observability.yaml` (OTel + OBI + Coroot + SigNoz). Effort : `S`.
- **J.4.** `orchestration.yaml` (DBOS + Temporal fallback). Effort : `S`.
- **J.5.** `identity.yaml` (Zitadel + Keycloak + Authentik). Effort : `S`.
- **J.6.** `persistence.yaml` (Postgres 17 + pgvector + Citus). Effort : `S`.
- **J.7.** Linter `validate-standards-yaml.sh` (cohérent avec F.2). Effort : `M`.
- **J.8.** Janus orchestrator règles (ARCHITECTURE-TARGET §12.5) : refuse
  `flutter-firebase` avec message Schrems II, force self-host Zitadel/SigNoz si
  `--eu-tier=T3`, force Mistral-EU ou vLLM si `ai-native-rag` + T3, génère SBOM
  CycloneDX. Effort : `M`.

**Total J : `M`**, ~2–3 semaines.

---

## 9. Module K — Cinq nouveaux agents *(nouveau)*

Source : ARCHITECTURE-TARGET §9.2.

| Code | Persona          | Responsabilités                                                           | Archétype                                 | Effort |
|------|------------------|---------------------------------------------------------------------------|-------------------------------------------|--------|
| K.1  | **Hermes-Async** | AsyncAPI 3.1, NATS/Kafka bindings, idempotency keys                       | `event-driven-eu`                         | `M`    |
| K.2  | **Pythia**       | Embeddings, pgvector tuning (HNSW `ef_search`), MCP servers, prompt audit | `ai-native-rag`                           | `M`    |
| K.3  | **Demeter**      | Data classification T1/T2/T3, DPA validation, CLOUD Act detection         | tous                                      | `M`    |
| K.4  | **Iris-Web**     | Standards Qwik / SvelteKit, distinct de Hera (Flutter)                    | `full-stack-monorepo`, `mobile-pwa-first` | `M`    |
| K.5  | **Themis**       | Compliance officer NIS2/DORA/CRA + cycle review-standards                 | tous EU                                   | `M`    |

Modifications agents existants (ARCHITECTURE-TARGET §9.1) :

- **Janus** : élevé (5 archétypes au lieu de 4, pipeline buf+Connect, interdiction Riverpod).
- **Atlas** : très élevé (Helm Envoy, Zitadel, NATS, OBI DaemonSet).
- **Hera** : faible (génération Bloc renforcée + suppression switch state-management).
- **Apollo** : modéré (Connect-Dart codegen, retrofit retiré).
- **Hephaestus** : modéré (Bloc skeletons + bloc_test depuis proto).
- **Vulcan** : modéré (DBOS-rs intégration).
- **Hermes-API** : élevé (Connect codegen + AsyncAPI + OpenAPI 3.1 dérivé).
- **Argus / Sentinel** : faible (W3C propagation Connect, middleware tonic OTel).
- **Panoptes** : élevé (Coroot + OBI configs).
- **Aegis** : élevé (NIS2/DORA/CRA audits + Zitadel hardening).
- **Heracles** : modéré (CI buf breaking, OVH/Scaleway providers, linter NSMA).

**Total K : `L`**, ~5–6 semaines pour les 5 agents + edits cross-agents.

---

## 10. Plan de migration en 4 phases (cible 6 mois)

Reprise de ARCHITECTURE-TARGET §11.

### Phase 0 — Freeze + audit (2 semaines, T4)

- Geler les choix actuels, instrumenter baseline p95/p99 sur l'exemple flagship.
- Audit Aegis : OWASP ASVS L2 + NIS2 gap analysis.
- Inventaire dépendances pour conformité CLOUD Act (Demeter, K.3).
- Audit linter Hera : confirmer absence Riverpod/Provider/GetX/MobX.
- **Risques** : aucun.
- **Point de non-retour** : non.

### Phase 1 — Observability + contrats (4 semaines, T5)

- Migrer codegen vers buf + Connect (proto inchangé, ajout Connect protocol).
- Déployer OTel Collector + OBI + Coroot en parallèle de SigNoz.
- Validation traceparent end-to-end Flutter → Kong → Rust.
- Convertir les 10 ADR en `.forge/changes/<adr-N>/` (P-1).
- Créer les 6 standards versionnés (J.1–J.6).
- **Risques** : faible. Connect-Dart non officiel, fallback Connect-Kotlin via FFI.
- **Point de non-retour** : non. Réversible.

### Phase 2 — Bascule structurelle (6 semaines, T6) — **POINT DE NON-RETOUR**

- Remplacer Kong par Envoy Gateway (canary par route).
- Migrer Temporal → DBOS pour workflows monorepo simples (cardinalité < 10k/jour).
- Renforcer scaffolding flutter_bloc + bloc_test via mise à jour Hera (templates v2).
- Codegen Connect-Dart remplace retrofit.
- Activer linter `no-state-management-alternatives` en CI bloquant (B.8.11).
- Déploiement Zitadel.
- **Bump schéma flagship 1.0.0 → 2.0.0** (B.8.14).
- **Risques élevés** : Envoy CRD complexity, DBOS Go SDK encore récent, Zitadel
  migration auth.
- **Point de non-retour** : oui, après bascule production de la flagship sur Envoy.
- **Mitigations** : feature flag par route, blue-green Envoy/Kong, training équipe SRE.

### Phase 3 — Nouveaux archétypes (8 semaines, T7)

- Implémenter `event-driven-eu` (NATS JetStream + Temporal + AsyncAPI 3.1) → B.6.
- Implémenter `ai-native-rag` (pgvector + LLM gateway + MCP) → B.7.
- Mettre à jour Forge CLI `@sdd-forge/cli init --archetype event-driven-eu|ai-native-rag`.
- Créer agents Pythia, Hermes-Async, Demeter, Iris-Web, Themis (K.1–K.5).
- **Risques** : maturité DBOS pour AI agents, MCP encore en évolution.

### Phase 4 — Deprecation (4 semaines, T8)

- Supprimer `flutter-firebase` du backlog (B.2 du plan d'origine).
- Renommer `mobile-only` → `mobile-pwa-first`, ajouter Qwik PWA template (B.9).
- Préparer T3 SecNumCloud (Outscale OKS) pour clients souverains.
- Déprécier Flutter Web public (back-office only).
- Annoncer EOL `full-stack-monorepo / 1.0.0` (legacy compat).

### Critères de rollback (ARCHITECTURE-TARGET §11.3)

- p99 augmente > 20 % après Envoy → rollback Kong.
- Erreurs traceparent > 1 % → rollback OTel SDK seul (sans OBI).
- DBOS Postgres saturé > 70 % CPU → fallback Temporal pour workflows lourds.

---

## 11. Priorisation recommandée — T4 → T8 (post-v0.3.0)

| Trimestre | Modules                                                                                          | Status (2026-05-10)                                                                                                                                                                                                                     | Rationale                                                                                                                                    |
|-----------|--------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| **T4**    | **P-1, P-2, P-3, P-4, I.1, J.1–J.6**                                                             | ✅ **Done 2026-05-04** via `t4-adr-ratification` (PR #2 mergée). 35 ADDED FRs + 8 NFRs. P-5 retiré 2026-05-06 (Hera 9 sub-agents conservés).                                                                                            | Méthodologie : ADR capturés, 6 standards YAML v1.0.0, cycle 12 mois, schémas compliance.                                                     |
| **T5**    | **Phase 1 ARCHITECTURE-TARGET, J.7, J.8, K.3 (Demeter), I.2–I.6**                                | ✅ **Connect codegen done 2026-05-06** via `t5-connect-codegen` (PR #3). ✅ **J.7 done 2026-05-08** via `j7-validate-standards-yaml` (PR #4 merged). ✅ **OTel + OBI + Coroot stack templates done 2026-05-10** via `t5-otel-stack` (PR #5 merged). ✅ **J.8 done 2026-05-10** via `j8-janus-rules` (PR #6 merged ; refusal rules + `--eu-tier` flag + CycloneDX SBOM ; 20/20 tests, +6 PASS verify.sh ; J.8.c deferred to T7). ✅ **K.3 done 2026-05-12** via `k3-demeter` (PR #7 merged ; Demeter persona + dependency scanner + deny-list + standard + Janus delta ; 22/22 tests `k3.test.sh --level 1,2`). ✅ **Q-004 resolved 2026-05-12** via `t5-otel-dart-api-realign` (PR #8 merged ; `flutter/opentelemetry.md` v1.0.0 → v1.1.0 standards realign on real Workiva `opentelemetry: 0.18.11` ; 9 fabricated symbols removed + 7 verified symbols added ; 12/12 L1 tests). ✅ **I.2 done 2026-05-12** via `i2-compliance-tiers` (single human-readable standard `global/compliance-tiers.md` v1.0.0 codifiant T1/T2/T3 — schema verbatim + matrix §10.2 byte-identical + `linter_rule: t3-forbidden-components` forward-pointer ; index entry + REVIEW birth + `docs/COMPLIANCE.md` + 14/14 L1 tests ; resolves K.3 forward-pointer). ✅ **I.6 done 2026-05-12** via `i6-compliance-artefacts` (deterministic `.tgz` compliance bundle generator `.forge/scripts/compliance/bundle.sh` + DPA template + standard `global/compliance-artefacts-bundle.md` v1.0.0 6 H2 + 4 MUST NOT ; six-member bundle MANIFEST/tier-matrix/dpa-template/audit-ledger×2/SBOM ; `SOURCE_DATE_EPOCH` determinism asserted by L2 fixture ; 16/16 tests `i6.test.sh --level 1,2` ; bundle layout forward-stable for Themis-territory artefacts). ✅ **I.3 done 2026-05-12** via `i3-t3-forbidden-linter` (`constitution-linter.sh::ADR-I3-001` section + standard `global/forbidden-components-rules.md` v1.0.0 with 10 `T3-RULE-001..010` rules + tier-scaled severity T1/T2 warn → T3 fail immediate + 14/14 L1 tests `i3.test.sh` ; resolves I.2 `linter_rule:` forward-pointer ; unblocks I.5). ✅ **I.5 done 2026-05-12** via `i5-compliance-workflow` (reusable `.github/workflows/forge-compliance.yml` `on: workflow_call:` 158 LOC orchestrant Demeter + linter + SBOM + bundle ; 3 inputs `eu-tier` / `target-dir` / `artefact-name` + 1 output `artefact-path` ; upload `.tgz` via `actions/upload-artifact@v4` ; standard `global/forge-compliance-workflow.md` v1.0.0 284 LOC 7 H2 + 4 MUST NOT + 8 triggers ; 17/17 tests `i5.test.sh --level 1,2` ; trois ADRs ADR-I5-CW-001..003 — exit-code aggregation trust-each-script + SOURCE_DATE_EPOCH commit-ts source + L2 act-opt-in `FORGE_I5_ACT=1`). NIS2/DORA/CRA/AI Act regulatory deadline artefacts (Themis K.5, T7+) = pending. | Observabilité + Connect contrats + standards linter + compliance graduée. Réversible.                                                        |
| **T5.1**  | **CLI Trust Harness + Option B tactical fixes**                                                    | ✅ **Done 2026-05-16** via 3 archives : `cli-trust-harness` (couches A/B/C + Taskfile sweep) + `t5-cargo-pin-refresh` (buffa pin) + `t5-bin-server-deps` (bin-server Cargo.toml + grpc-api API realign). Released as `@sdd-forge/cli@0.3.3`. | Garantit qu'un tarball npm `@sdd-forge/cli@X` ne shippe pas un scaffold cassé. Couche D différée à T6 / B.8.15. `cargo check --workspace` GREEN end-to-end ; `flutter analyze` mobile-only RED (T5.3). |
| **T5.2**  | **Anti-Hallucination Platform Verification (process)**                                              | ✅ **Done 2026-05-18** via `t5-2-platform-verification`. 8 L1 + 1 L2 opt-in (`FORGE_T52_LIVE=1` pub.dev smoke `flutter_bloc`) ; harness `t5-2.test.sh` 9/9 GREEN, wall-clock 0.06s L1 / 0.31s L1+L2. 4 surfaces drift-guard (agent + standards-lifecycle + CONTRIBUTING + LINTING) vérifiées verbatim. `standards-lifecycle.md` v1.0.0 → v1.1.0 (additive, frontmatter back-fill, REVIEW.md ledger 2026-05-18). Article III.4 (Ambiguity Protocol) reinforcement procédural — auto-validation par code-reviewer indépendant qui a attrapé "Article VIII" fabriquée → corrigée pré-archive. Release target v0.3.4 (patch). | Ajoute un 3e axe (platform compatibility) à la procédure document-specialist + cadence de re-revue `standards-lifecycle.md` v1.1.0.          |
| **T5.3**  | **`t5-otel-dartastic-realign`**                                                                    | ⏸️ Planned 2026-05-16. Target v0.4.0-rc.1. Détails §0.3.                                                                                                                            | Workiva (web-only) → Dartastic (all-platform). Bump `flutter/opentelemetry.md` v2.0.0 breaking. Q-006 resolution.                            |
| **T6**    | **B.8 (flagship 1.0.0 → 2.0.0), Phase 2 ARCHITECTURE-TARGET, B.8.15 couche D upgrade-matrix**     | ⏸️ Pending.                                                                                                                                                                                                                             | Migration breaking flagship. **Point de non-retour**. B.8.15 ferme la dernière couche de T5.1 (upgrade matrix N-1 → N).                      |
| **T7**    | **B.6 (event-driven-eu), B.7 (ai-native-rag), K.1, K.2, K.4, K.5**                               | ⏸️ Pending.                                                                                                                                                                                                                             | Deux nouveaux archétypes + 4 nouveaux agents.                                                                                                |
| **T8**    | **B.9 (mobile-pwa-first / 2.0.0), B.3 (rust-cli-tui), pédagogie C.2-C.5**                        | ⏸️ Pending. **F.3 pulled forward, delivered 2026-05-12 via `f3-release-script-fix`.**                                                                                                                                                                | Renommage mobile + dernier archétype premium + walkthrough/anti-patterns/comparison/migration. F.3 release script fix shipped early (T5).    |
| **T9+**   | **G.* (Forge Guardian, VSCode, pre-commit), H.* (multi-tenant, télémétrie, compliance reports)** | ⏸️ Pending.                                                                                                                                                                                                                             | Outillage périphérique et enterprise après que les 5 archétypes soient stables.                                                              |

### Alternative « adoption lente, qualité maximale »

Si tu priorises **profondeur** plutôt que largeur (i.e. flagship parfait avant
nouveaux archétypes), inverse T6 et T7 : livre B.6 et B.7 sur le schéma flagship 1.0.0
existant, puis fais B.8 en T8. Le coût : flagship reste sur Kong/Temporal pendant
6 mois supplémentaires (acceptable si tu n'as aucun adopter EU strict en cours).

---

## 12. Risques transverses *(post ARCHITECTURE-TARGET)*

| Risque                                                              | Probabilité | Impact | Mitigation                                                                                              |
|---------------------------------------------------------------------|-------------|--------|---------------------------------------------------------------------------------------------------------|
| Connect-Dart encore community-only                                  | Moyenne     | Moyen  | Forker, contribuer upstream, sinon Kotlin FFI                                                           |
| DBOS Go SDK breaking changes < 1 an de prod                         | Moyenne     | Élevé  | Wrapper interne Forge, épingler version, garder Temporal en option pour workflows critiques             |
| Envoy Gateway CRD courbe                                            | Élevée      | Moyen  | Documentation Atlas + templates Helm + runbooks                                                         |
| OBI nécessite kernel ≥ 5.8                                          | Moyenne     | Faible | Documenter prérequis nodes ; opt-in via flag                                                            |
| Drift specs ↔ code (problème SDD générique)                         | Élevée      | Élevé  | Adopter "living specs" pattern (Augment Intent)                                                         |
| Friction recrutement si marché Flutter bascule Riverpod-majoritaire | Moyenne     | Moyen  | Assumé comme coût de positionnement premium ; rationale Bloc dans README de chaque archétype            |
| Migration flagship 1.0.0 → 2.0.0 casse les adopters early-bird      | Moyenne     | Élevé  | `forge upgrade` 3-way merge + legacy compat 6 mois + migration script + canary par route                |
| Schrems II / CLOUD Act réinterprétés en 2027 (assouplis ?)          | Faible      | Moyen  | Si décision change, ajouter `flutter-baas-eu` ou similaire ; ne pas réintroduire Firebase               |
| AI Act phases 2026–2027 ne sont pas finalisées                      | Moyenne     | Moyen  | Templates B.7 conçus extensibles ; agent Themis (K.5) suit l'évolution réglementaire                    |
| Déclassement `mobile-only / 1.0.0` casse les adopters T2 P2         | Moyenne     | Moyen  | Alias rétro-compatible jusqu'à T8 (≥ 6 mois) + `forge upgrade` mobile-only → mobile-pwa-first via B.9.9 |

---

## 13. Caveats & limites

> Section critique. Lis-la deux fois.

1. **`full-stack-monorepo / 1.0.0` shippé en v0.3.0 reste fonctionnel** et restera
   supporté en `legacy compat` jusqu'à T8. Aucun adopter n'est obligé de migrer.
   Mais aucun **nouveau** projet ne devrait être scaffoldé sur 1.0.0 après T6 (les
   5 ADR techniques font de 1.0.0 une stack obsolète sur les 3 critères pondérés
   latence/observabilité/scalabilité).
2. **Connect-Dart non-officiel** : risque #1 de B.8. Si trop fragile au moment de T6,
   garder gRPC-Web standard via Envoy Gateway et accepter l'overhead JSON↔binary
   translation. Ne pas bloquer toute la migration sur ce seul point.
3. **DBOS-rs maturity** : avril 2026, écosystème < 1 an. Si tu construis une
   plateforme à 5 ans, **garde Temporal en option** pour les workflows critiques
   (l'archétype `event-driven-eu` le justifie déjà).
4. **OBI / Coroot eBPF** : kernel récent + privileged DaemonSet. Audit Aegis
   obligatoire avant prod. Certains clusters managés EU restreignent.
5. **flutter-firebase REMOVE** est une décision de positionnement, pas technique.
   Defendable mais **à assumer publiquement** dans `docs/ARCHETYPES.md` et
   `CHANGELOG.md` pour ne pas surprendre les adopters qui auraient extrapolé du plan
   d'origine.
6. **`event-driven-eu` n'est pas un cas d'usage prouvé chez Forge** au moment de la
   décision — c'est une lecture d'industrie (kai-waehner.de, ARCHITECTURE-TARGET §3.3).
   Mesurer la demande avant T7 (issues GitHub Discussions, sondage early-adopters).
7. **`ai-native-rag` est un cible mouvante** — MCP, agents, RAG patterns évoluent
   tous les 3 mois. Templates B.7 doivent être versionnés agressivement avec
   fenêtre 12 mois sans exception structurelle.
8. **`opinion d'architecte non sourcée`** sur les points suivants :
    - Rejet GraphQL Federation par défaut.
    - Recommandation `mobile-pwa-first` PWA-by-default (le marché est partagé).
    - Postgres comme défaut universel pour `ai-native-rag` (Qdrant > 50M vecteurs).
    - *(Refactor Hera 9 → 5 sub-agents — P-5 — retiré 2026-05-06 par le mainteneur.)*
9. **Pas d'archétype `data-intensive`** proposé (volontairement écarté faute de
   demande explicite — manque potentiel à 18 mois).

---

## 14. Fichiers critiques à modifier (delta vs plan d'origine)

| Module  | Fichiers nouveaux                                                                                                                                                                                                                                                                   |
|---------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| P-1     | `.forge/changes/adr-001..adr-010/` (10 nouveaux changes archived avec proposal/specs/design)                                                                                                                                                                                        |
| P-2 / J | `.forge/standards/{transport,state-management,observability,orchestration,identity,persistence}.yaml`                                                                                                                                                                               |
| P-3     | `.forge/standards/REVIEW.md`, `.forge/standards/global/standards-lifecycle.md`                                                                                                                                                                                                      |
| P-4 / I | `.forge/schemas/compliance-tier.schema.json`, `.forge/schemas/archetype.schema.json` v2                                                                                                                                                                                             |
| B.6     | `.forge/schemas/event-driven-eu/1.0.0.yaml`, `.forge/templates/event-driven-eu/*`, `.claude/agents/hermes-async.md`, `.forge/standards/{global/event-driven,global/asyncapi-contracts,infra/nats-jetstream}.md`, `examples/forge-eda-example/`, `bin/forge-init-event-driven-eu.sh` |
| B.7     | `.forge/schemas/ai-native-rag/1.0.0.yaml`, `.forge/templates/ai-native-rag/*`, `.claude/agents/pythia.md`, `.forge/standards/{global/rag-patterns,global/llm-gateway,global/mcp-servers}.md`, `examples/forge-rag-example/`, `bin/forge-init-ai-native-rag.sh`                      |
| B.8     | `.forge/schemas/full-stack-monorepo/2.0.0.yaml`, `.forge/templates/full-stack-monorepo/2.0.0/*` (Envoy/DBOS/Connect/Zitadel/Postgres+pgvector/SigNoz+OBI+Coroot/Qwik), `bin/forge-migrate-flagship.sh`, `.forge/scaffold-snapshots/full-stack-monorepo/2.0.0.tar.gz`                |
| B.9     | `.forge/schemas/mobile-pwa-first/2.0.0.yaml`, `.forge/templates/mobile-pwa-first/2.0.0/web-pwa/*`, `bin/forge-migrate-mobile-pwa.sh`, `.forge/scaffold-snapshots/mobile-pwa-first/2.0.0.tar.gz`                                                                                     |
| I       | `.forge/standards/global/compliance-tiers.md`, `.claude/agents/demeter.md`, `.github/workflows/forge-compliance.yml`, `docs/COMPLIANCE.md`, `.forge/compliance/{nis2,dora,cra,ai-act}/*`                                                                                            |
| J       | `.forge/scripts/validate-standards-yaml.sh`, `.claude/agents/janus.md` (élargir règles)                                                                                                                                                                                             |
| K       | `.claude/agents/{hermes-async,pythia,demeter,iris-web,themis}.md`                                                                                                                                                                                                                   |
| Docs    | `docs/ARCHETYPES.md` (5 lignes au lieu de 4), `docs/MIGRATION-PATHS.md` (enrichi B.8 + B.9), `docs/COMPLIANCE.md`, `CHANGELOG.md`, `.forge/product/roadmap.md`                                                                                                                      |

---

## 15. Conclusion — message direct

Tu as livré v0.3.0 le 2026-05-02 avec une exécution irréprochable : 13 changes,
292 tests, gouvernance posée, deux archétypes scaffoldables. Mais le document
`docs/ARCHITECTURE-TARGET.md` que tu as commandité est **un acte de remise à plat
volontaire** : il dit que `full-stack-monorepo / 1.0.0` est défendable mais pas
optimal, et que la taxonomie d'archétypes confond cible technique (full-stack vs
mobile-only) et contraintes business (souveraineté, événementiel, AI).

Les **trois critères pondérés** (latence p95/p99, observabilité déterministe,
scalabilité sans SPOF) **conduisent tous au même verdict** :

- Envoy Gateway > Kong → B.8.
- DBOS > Temporal (par défaut) → B.8.
- Connect-RPC > REST-bridge → B.8.
- OTel + eBPF (OBI/Coroot) > OTel SDK seul → B.8.
- Postgres+pgvector > zoo de bases → B.8.

Le module B.8 est le **point de non-retour**. Tu peux retarder, tu ne peux pas
contourner sans abandonner le positionnement EU/premium/SDD. Les modules B.6
(`event-driven-eu`) et B.7 (`ai-native-rag`) sont les **deux nouveaux territoires**
ouverts par la révision taxonomique : sans eux, Forge reste un framework SDD générique.
Avec eux, Forge devient le seul framework SDD qui propose nativement event-driven-eu
et AI-native souverain.

**Prochaines actions concrètes (T4)** *(rédigé le 2026-05-04)* :

1. ~~Convertir les 10 ADR en `.forge/changes/` (P-1) — 1 semaine.~~ ✅ Done 2026-05-04 (consolidé en
   `t4-adr-ratification`).
2. ~~Créer les 6 standards YAML (P-2 / J.1–J.6) — 1 semaine.~~ ✅ Done 2026-05-04.
3. ~~Inscrire le cycle de réévaluation 12 mois (P-3) — 2 jours.~~ ✅ Done 2026-05-04.
4. ~~Schémas JSON compliance (P-4 / I.1) — 2 jours.~~ ✅ Done 2026-05-04.
5. ~~Décider P-5 (refactor Hera 9 → 5).~~ ✅ **Retiré 2026-05-06** — refactor rejeté, Hera 9 sub-agents conservés.

**Prochaines actions concrètes (T5 suite, post-`t5-connect-codegen`)** :

1. ✅ ~~**Finir `t5-connect-codegen`**~~ — **Done 2026-05-06** : 25/25 L1 PASS,
   demo-005-connect-greeting archivée, `transport.yaml` v1.1.0 ratifié, PR #3
   mergée (`ca27257`). L2 fixtures (T-L2-001..007) deferred à T6.
2. ✅ ~~**Lancer Phase 1 OTel + OBI + Coroot stack**~~ — **Done
   2026-05-10** via `t5-otel-stack` (Phase A infra-only) :
   `grafana/beyla:2.0.1` DaemonSet + `coroot/coroot:1.4.4` Deploy +
   `processors.probabilistic_sampler` env-tier overlays, snapshot
   regen 520 KB, 14/14 tests GREEN. Phase B (SDK instrumentation
   `examples/forge-fsm-example/`) et Phase C (E2E traceparent) restent
   à livrer comme changes suivants.
3. ✅ ~~**Livrer J.7**~~ — **Done 2026-05-08** via
   `j7-validate-standards-yaml` : `bin/validate-standards-yaml.sh` +
   schéma JSON Draft 2020-12, 21/21 tests GREEN, live-tree 122 ms,
   `verify.sh` § "Standards YAML Schema" (+7 PASS), spec consolidée
   `.forge/specs/standards-yaml-validation.md`.
4. ✅ ~~**Livrer J.8**~~ — **Done 2026-05-10** via `j8-janus-rules`
   (sous-modules J.8.a + J.8.b + J.8.d) : refus
   `flutter-firebase` Schrems II + CLOUD Act, force self-host
   Zitadel/SigNoz si T3, `--eu-tier` flag plumbing, CycloneDX SBOM
   handcrafted Python inline. J.8.c (`ai-native-rag` LLM gateway
   rules) déférée vers T7 quand l'archetype shippera.
5. ✅ ~~**Livrer K.3 (Demeter)**~~ — **Done 2026-05-12** via `k3-demeter` :
   premier des 5 nouveaux agents livré. Persona `.claude/agents/demeter.md`
   (7 H2 sections sibling Aegis), scanner `bin/forge-demeter-scan.sh`
   (F.2 / J.7 / J.8.d pattern verbatim, tier-scaled severity, exit
   envelope 0/1/2/3, `SOURCE_DATE_EPOCH`-deterministic), deny-list
   `cloud-act-publishers.yml` (10 publishers seeded — AWS / Google Cloud /
   Azure / Firebase), standard `global/data-stewardship-rules.md`, Janus
   delta Step 9, DPA ledger `.forge/.forge-dpa-declared`, 5 seed
   K3-RULE-NNN + 1 operational guardrail (per ADR-K3-005). 22/22 tests
   `k3.test.sh --level 1,2`. K.3 débloque I.2–I.6 (Demeter présent pour
   adopter T1/T2/T3 sans attendre Themis).
6. ✅ **Livrer I.2** — DONE 2026-05-12 via `i2-compliance-tiers` :
   single human-readable standard `global/compliance-tiers.md` v1.0.0
   (437 LOC, 7 H2 sections) codifiant T1 / T2 / T3 depuis
   `compliance-tier.schema.json` v1.0.0 (verbatim) et la matrice
   §10.2 d'`ARCHITECTURE-TARGET.md` (byte-identical). Frontmatter
   pins `linter_rule: t3-forbidden-components` (forward-pointer vers
   I.3). `.forge/standards/index.yml` entry + REVIEW.md birth entry
   + `docs/COMPLIANCE.md` root adopter intro + 14/14 L1 tests
   `i2.test.sh`. Résout le forward-pointer Demeter
   (`.claude/agents/demeter.md::Standards consumed`). I.2 débloque
   I.3 / I.5 / I.6.
7. ✅ **I.6 livré 2026-05-12** via `i6-compliance-artefacts` —
   deterministic `.tgz` regulatory hand-off bundle generator
   `.forge/scripts/compliance/bundle.sh` (bash thin + Python 3 inline
   mirroring `bin/forge-sbom.sh`), DPA template
   `.forge/templates/compliance/forge-dpa-declared.template`,
   standard `global/compliance-artefacts-bundle.md` v1.0.0 (6 H2 + 4
   MUST NOT, forward-stable schema). Six bundle members deterministic
   par `SOURCE_DATE_EPOCH` (NFR-I6-CA-005). 16/16 tests `i6.test.sh
   --level 1,2`. Bundle layout forward-stable pour les artefacts
   Themis-territory (NIS2 / DORA / CRA / AI Act) lorsque K.5 livrera.
8. ✅ **I.3 + I.5 livrés 2026-05-12** — linter rule T3
   (`i3-t3-forbidden-linter` : `constitution-linter.sh::ADR-I3-001`
   section + standard `global/forbidden-components-rules.md` v1.0.0
   + 10 `T3-RULE-001..010` + tier-scaled severity ; 14/14 L1 tests
   `i3.test.sh`) ; `forge-compliance.yml` reusable workflow
   (`i5-compliance-workflow` : `.github/workflows/forge-compliance.yml`
   158 LOC `on: workflow_call:` orchestrant Demeter + linter +
   SBOM + bundle, upload `.tgz` via `actions/upload-artifact@v4`,
   standard `global/forge-compliance-workflow.md` v1.0.0 ; 17/17
   tests `i5.test.sh --level 1,2`). Les échéances réglementaires
   NIS2/DORA/CRA/AI Act dans `.forge/compliance/` restent dans le
   territoire Themis (K.5, T7+) — le bundle layout I.6 et le
   workflow I.5 sont forward-stable pour les absorber additivement
   quand Themis livrera.
Tout le reste découle.

— *Fin du nouveau plan. Mise à jour partielle 2026-05-12 (I.2 + I.3 + I.5 + I.6 livrés).*
