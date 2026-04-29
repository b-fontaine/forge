# Proposal: b1-delivery
<!-- Created: 2026-04-29 -->
<!-- Schema: default -->
<!-- Parent audit module: B.1 (full-stack-monorepo archetype) -->
<!-- Parent audit items: B.1.9, B.1.12, B.1.14 -->
<!-- Depends on: b1-foundations + b1-scaffolder + b1-workflow (all archived) -->
<!-- Closes: B.1 — promotes schema candidate / 1.0.0-rc.1 → stable / 1.0.0 -->

## Problem

The `full-stack-monorepo` archetype now ships with a complete static
form (foundations), a generator (scaffolder), and a multi-layer
lifecycle (workflow + Janus). What's still missing is the **runtime
delivery surface** — the parts that turn a freshly scaffolded tree
into a project that can be **built, deployed, and observed** the
moment it is generated. Three concrete gaps remain :

1. **No CI of reference.** Scaffolded projects get an empty
   `.github/workflows/` directory. There is no pipeline that runs
   `verify.sh` and `constitution-linter.sh` on PRs, no per-layer
   filtering, no integration job. Adopters have to write CI from
   scratch — and without it, the multi-root linter introduced by
   `b1-workflow` is never enforced. Constitutional gates exist on
   disk but never block a merge. *(B.1.9 — also covers G.1 in the
   audit roadmap : the reference workflow Forge itself should expose.)*

2. **No deployment overlays.** `infra/k8s/` exists in the scaffolded
   tree (per the schema's `infra` layer specification), but it
   contains only the empty `base/` and `overlays/` directories. There
   are no canonical Kustomize overlays for `dev`, `staging`, `prod`,
   no namespace conventions, no ConfigMap/Secret patterns, no
   replica/resource scaling per environment. Adopters must invent
   their own three-environment pattern, defeating the "premium
   archetype" promise. *(B.1.12.)*

3. **No local observability.** The constitution's Article IX requires
   observability to be a first-class concern, and the audit roadmap
   commits to "OTel collector + SigNoz prêt à l'emploi pour dev".
   `docker-compose.dev.yml` currently spins up only the application
   stack ; traces and metrics emitted by `backend/` and `frontend/`
   have nowhere to land. Developers either run blind or add their
   own observability stack ad-hoc. *(B.1.14.)*

These three gaps share a property : each is a **template-shaped
deliverable that ships under `.forge/templates/archetypes/full-stack-monorepo/`** and is
inert until a project is scaffolded. None require new agents, no new
schema fields, no new lifecycle phase. Scoping them as a single
change keeps the surface area tight and makes the dependency on
`b1-foundations` + `b1-scaffolder` + `b1-workflow` straightforward :
this change is the **last B.1 brick** before the archetype schema is
promoted from `candidate / 1.0.0-rc.1` to `stable / 1.0.0`.

## Solution

Three coordinated template families, each shipped under the existing
archetype overlay tree and consumed unchanged by the scaffolder
(zero scaffolder code change required — only new template files in
the same fixture path the scaffolder already walks).

1. **Reference CI workflows** (B.1.9) — four GitHub Actions templates
   under `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/` :
    - `forge-backend.yml.tmpl` — triggers on `paths: ['backend/**',
      'shared/protos/**']`. Steps : `cargo fmt --check`, `cargo clippy
      -- -D warnings`, `cargo test --workspace`, then the Forge gates
      (`bash .forge/scripts/verify.sh` and
      `bash .forge/scripts/constitution-linter.sh`). Uses
      `dorny/paths-filter@v3` to skip the job entirely when the touched
      paths fall outside its scope.
    - `forge-frontend.yml.tmpl` — triggers on `paths: ['frontend/**',
      'shared/protos/**']`. Steps : `flutter pub get`, `flutter
      analyze`, `flutter test`, integration tests on a headless
      android emulator, then the Forge gates.
    - `forge-infra.yml.tmpl` — triggers on `paths: ['infra/**']`.
      Steps : `kustomize build infra/k8s/overlays/dev`, same for
      `staging` and `prod` (must produce valid YAML), `kubeval` on
      the rendered manifests, `kubeconform` for stricter schema
      checks, then the Forge gates.
    - `forge-integration.yml.tmpl` — triggers on `push: main` and
      `schedule: nightly`. Boots `docker compose -f
      docker-compose.dev.yml up -d`, waits for the backend
      healthcheck, runs `cargo test --features integration` against
      the live stack, runs Patrol end-to-end tests against an Android
      emulator pointed at the local backend, then tears down.
   The four files are templates (extension `.tmpl`) so the scaffolder
   substitutes the project name and remote URL before writing them.

2. **Kustomize overlays** (B.1.12) — three overlay templates under
   `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/overlays/{dev,staging,prod}/` :
    - Each overlay declares its own namespace, image tag policy
      (dev : `:latest` from local registry ; staging : SHA-pinned
      from main ; prod : tag-pinned from release), replicas (dev : 1,
      staging : 2, prod : 3 with HPA template), resource limits, and
      ConfigMap generators for environment-specific settings.
    - A canonical `base/` template sets the shared Deployment +
      Service + Ingress + ServiceAccount. Per-overlay
      `kustomization.yaml` patches what diverges (replicas, env, image,
      ingress host).
    - Documentation under `infra/k8s/README.md.tmpl` that explains
      the three-environment promotion model and how it ties to the
      Forge change lifecycle (proposed/specified/implemented don't
      ship to staging ; archived ships to prod).

3. **Local observability stack** (B.1.14) — additions to
   `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl` plus three
   companion config files under `infra/observability/` :
    - New compose services : `otel-collector` (otel/opentelemetry-collector-contrib),
      `signoz-clickhouse` (storage backend), `signoz-query-service`,
      `signoz-frontend`. Networking through the existing
      `forge-dev` bridge.
    - `infra/observability/otel-collector-config.yaml.tmpl` defines
      OTLP receivers (gRPC 4317 + HTTP 4318), the SigNoz exporter,
      and a debug exporter for local inspection.
    - `infra/observability/signoz-config.yaml.tmpl` configures the
      SigNoz query service (auth disabled in dev, auth required in
      staging/prod overlay).
    - `frontend/.env.dev.tmpl` and `backend/.env.dev.tmpl` ship
      `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317`
      defaults so the apps trace to the local stack with zero
      additional setup.
    - `Taskfile.yml.tmpl` gains a `task observe` target that opens
      the SigNoz UI at `http://localhost:3301` in the default browser.

The promotion gate at the end of this change : once archived, the
schema header at `.forge/schemas/full-stack-monorepo/schema.yaml`
moves from `status: candidate` + `version: 1.0.0-rc.1` to
`status: stable` + `version: 1.0.0`, and the spec
`.forge/specs/full-stack-monorepo.md` records the promotion in its
revision history.

## Scope In

- Four GitHub Actions workflow templates with `dorny/paths-filter`
  per-layer triggering and one cross-layer integration workflow.
- Three Kustomize overlays (`dev`, `staging`, `prod`) and a shared
  `base/` under the archetype's `infra/k8s/` template tree.
- OTel collector + SigNoz services added to the archetype's
  `docker-compose.dev.yml.tmpl`, plus their config templates and
  the `.env.dev` defaults pointing the apps at the local collector.
- New standard `.forge/standards/infra/ci-workflows.md` documenting
  the per-layer + integration pattern and the gate ordering.
- New standard `.forge/standards/infra/k8s-overlays.md` documenting
  the dev/staging/prod promotion model.
- New standard `.forge/standards/infra/observability-local.md`
  documenting the OTel + SigNoz local stack pattern.
- Schema promotion : header bump from `candidate / 1.0.0-rc.1` to
  `stable / 1.0.0` in `.forge/schemas/full-stack-monorepo/schema.yaml`,
  with a corresponding entry in the spec revision history.
- Multi-root linter test : a new fixture under
  `.forge/scripts/tests/` that spins up a fully-scaffolded sample,
  runs the four workflows in `act` (or equivalent), and asserts
  exit codes per layer.

## Scope Out (Explicit Exclusions)

- **No GitHub App** (G.3 in the audit roadmap) — that's a separate
  module and does not block schema promotion.
- **No Helm chart equivalent** of the Kustomize overlays. Helm is
  documented in B.1 as an alternative but Kustomize is the canonical
  choice for v1.0.0. A future change can add Helm parity if demand
  emerges.
- **No production observability stack.** This change ships the
  *local dev* OTel + SigNoz only. Production observability (managed
  collector, retention policy, alerting, RBAC) is intentionally
  out of scope — Article IX is satisfied at the dev-loop level
  here, and a follow-up change can extend it.
- **No release workflow.** Cutting versioned releases of the
  *scaffolded project* (separate from Forge itself) is out of scope.
  Adopters use whatever release tooling they prefer ; Forge does not
  prescribe one for downstream projects.
- **No frontend deployment overlays for web.** B.4 (mobile-only) and
  B.2 (flutter-firebase) are separate archetypes ; this change only
  covers the `full-stack-monorepo` server-side deployment surface.
- **No SigNoz cloud / SaaS integration.** Local Docker stack only.
- **No update of existing scaffolded projects in the wild.** This
  change adds new templates ; the path forward for already-scaffolded
  projects is the upcoming `forge upgrade` (A.7) — out of scope here.

## Impact

- **Users affected** : every adopter of the `full-stack-monorepo`
  archetype from v1.0.0 onward. Existing scaffolded projects (none
  yet, since the archetype is still `candidate`) are unaffected.
- **Technical impact** : medium. No new agents, no new commands, no
  new lifecycle phases. Only new template files under existing
  archetype directories, three new standards, and one schema header
  bump. The scaffolder code itself is unchanged — it walks the
  archetype tree and copies whatever it finds, so adding new files
  Just Works.
- **Dependencies** : `b1-foundations` (schema), `b1-scaffolder`
  (template walker), `b1-workflow` (multi-root linter expected by
  the `forge-infra.yml` workflow). All three already archived.
- **Risk level** : Low. Templates are inert until a project is
  scaffolded. The schema promotion is a header bump, mechanically
  trivial. The riskiest piece is the integration workflow which
  depends on docker-compose stability in CI — mitigated by running
  it on `main` and nightly only, never as a per-PR blocker.

## Constitution Compliance

### Article I — TDD

The deliverables are templates and YAML manifests, not application
code, but they still get the RED → GREEN → REFACTOR cycle :

- **Workflows** : test fixtures under `.forge/scripts/tests/` that
  parse each YAML with `yq`, assert the trigger paths, the job
  ordering, and that the Forge gates run after the language-specific
  steps. RED first : a fixture asserting the file exists and has
  the expected trigger fails before the workflow is written.
- **Overlays** : a test that runs `kustomize build` on each overlay
  and pipes through `kubeconform` ; RED before the manifests exist.
- **OTel/SigNoz** : a test that runs `docker compose config` to
  validate the merged compose file is well-formed and that the
  expected services are declared.
- **Schema promotion** : a test that asserts the schema file has
  `status: stable` and `version: 1.0.0` before the bump is committed
  fails RED.

### Article II — BDD

User-facing surface in this change : the developer-experience flow
of "scaffold project → push PR → CI gates pass". One BDD scenario
file under `.forge/changes/b1-delivery/features/` covers the happy
path (scaffold → push backend-only change → only `forge-backend.yml`
runs, gates pass, PR mergeable) and the cross-layer path (push a
change that touches both `backend/` and `shared/protos/` → both
backend and frontend workflows run because both filters match).

### Article III — Specs Before Code

Confirmed. No template files, no YAML, no schema bump until
`/forge:specify b1-delivery` produces `specs.md` with all FRs and
NFRs and `/forge:design b1-delivery` produces a single `design.md`
(this is a single-layer infra change — no per-layer designs needed).

### Article IV — Semantic Deltas

The eventual archive will append a delta to
`.forge/specs/full-stack-monorepo.md` :
`## ADDED` for the new templates and standards,
`## MODIFIED` for the schema header (status + version),
no `## REMOVED`. The schema promotion itself is a
`MODIFIED FR-GL-NNN` rather than a new FR.

### Article V — Conformance Gate

The new `forge-infra.yml` workflow runs `verify.sh` +
`constitution-linter.sh` on every infra-touching PR — making this
change the first to **enforce its own gates in CI** rather than
relying on developer discipline.

### Article VIII — Infrastructure

This change *is* an Article VIII deliverable. Atlas (infra agent) is
the lead writer for `design.md` and the standards. Concerns covered :
declarative deployment (Kustomize), per-environment configuration
isolation, immutable image references in staging/prod, local
parity with production topology (compose mirrors the K8s service
graph in dev).

### Article IX — Observability

The OTel + SigNoz stack directly satisfies Article IX at the dev
loop : every scaffolded project has working trace + metric pipelines
out of the box, with no manual setup. Argus (observability agent)
co-authors `design.md` and the
`standards/infra/observability-local.md` standard.

### Article X — Quality

CI workflows enforce zero-warning compilation (`cargo clippy -D
warnings`, `flutter analyze`), test passing, and the Forge gates on
every PR. Quality becomes structural rather than aspirational.

### Article XI — AI-First

Not directly relevant. No AI feature ships in this change.
