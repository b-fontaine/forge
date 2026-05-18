# Contributing to Forge

---

## Contribution Philosophy

Forge develops itself according to its own principles. This is not irony — it
is a necessity. A framework that mandates specs and TDD but accepts
unspecified, untested contributions would be incoherent.

Every contribution MUST:
- Go through the Forge pipeline (Proposal → Specs → Design → Tasks → TDD)
- Comply with the Constitution (twelve articles, no exceptions)
- Include tests — even for Markdown, in the form of documented and
  executed validation scenarios

If you contribute to Forge, you use Forge to contribute to Forge. That is
the best integration test possible.

---

## Adding a Standard

A standard is a technical rule injected dynamically into the appropriate
agent's context at the right moment.

### The 5 steps

1. **Create the file** — `.forge/standards/<domain>/<name>.md`, following
   the required format (see below).

2. **Register in the catalog** — Add an entry to
   `.forge/standards/index.yml`:
   ```yaml
   - id: <domain>/<name>
     path: standards/<domain>/<name>.md
     triggers:
       - <keyword-1>
       - <keyword-2>
     scope: <implementation|design|review|all>
     priority: <high|medium|low>
   ```

3. **Pick precise triggers** — Triggers must be specific. `flutter` is too
   broad. `riverpod`, `provider`, `bloc` are precise. Triggers that are too
   general pollute the context with non-relevant standards.

4. **Test it** — Write a test scenario: run `/forge:implement` in a context
   that should fire the standard, and verify the standard is injected and
   the agent complies.

5. **Document it** — Explain in the standard file: why the rule exists, in
   which context it applies, and what happens if it is violated.

### When the standard pins an external dependency — 3-axis verification

If the standard pins an external package (pub.dev / crates.io / npm /
Maven / etc.), you MUST also run the **Platform Verification Checklist
(3-axis)** before flipping the standard's status to `verified`. The
checklist body lives in
[`.claude/agents/document-specialist.md`](../.claude/agents/document-specialist.md)
§ `Platform Verification Checklist (3-axis)`. Cadence rules for
re-verification live in
[`.forge/standards/global/standards-lifecycle.md`](../.forge/standards/global/standards-lifecycle.md)
§ `Platform compatibility re-verification`.

The checklist was introduced by **T5.2** (`t5-2-platform-verification`,
2026-05-18) following **Q-006** — the Workiva `opentelemetry 0.18.11`
ratification (`t5-otel-dart-api-realign`) that survived Axis 1 + Axis 2
verification but was structurally web-only, breaking the consuming
`mobile-only` and `full-stack-monorepo` archetypes on iOS + Android.

### Required format for a standard

```markdown
# Standard: [Name]

## Scope
[What this standard applies to — domain, context, situations]

## Rules
[Rules with concrete code or behavior examples]

## Anti-patterns
[What NOT to do — with examples and an explanation of the problem]
```

The "Anti-patterns" section is strongly recommended. An LLM that sees "do
not do X" is less likely to do X than an LLM that only sees "do Y".

---

## Adding an Agent

An agent is a persistent persona with a specific expertise, communication
style, and behavior rules.

### The 4 steps

1. **Create the file** — `.claude/agents/<team>/<name>.md`.

2. **Required sections**:
   - `## Persona` — Name (mythological), Role (title), Style (how they
     communicate)
   - `## Purpose` — One sentence describing why this agent exists
   - `## Expertise` — Areas of competence
   - `## Workflow` — How they approach tasks (steps)
   - `## Rules` — Non-negotiable rules (forbidden behaviors, mandatory
     behaviors)

3. **Reference from the orchestrator** — The agent must be invocable:
   - Flutter team → reference from `hera.md`
   - Rust team → reference from `vulcan.md`
   - Cross-cutting → reference from `forge-master.md`

4. **Naming convention**:
   - Flutter team → Greek mythology (Hera, Athena, Spartan, Apollo,
     Hephaestus...)
   - Rust team → Latin/Roman (Vulcan, Ferris, Centurion, Tribune,
     Terminal...)
   - Cross-cutting → Greek or Latin (Forge, Clio, Oracle, Atlas, Aegis,
     Panoptes...)

---

## Adding a Command

A slash command is a Markdown file in `.claude/commands/forge/` that Claude
Code surfaces via `/forge:<name>`.

### The 3 steps

1. **Create the file** — `.claude/commands/forge/<name>.md`.

   Required format:
   ```markdown
   # /forge:<name> — Short description

   ## Purpose
   [Why this command exists]

   ## Process
   1. [First step]
   2. [Second step]
   ...

   ## Output
   [What the command produces]
   ```

2. **Wire into state detection** — If the command is part of the main
   cycle, update the routing logic in `forge-master.md` so `/forge` can
   dispatch to it automatically.

3. **Document it** — Update:
   - `README.md` — command table
   - `docs/GUIDE.md` — commands section and/or development cycle
   - `docs/ARCHITECTURE.md` — annotated structure if a new file is added

---

## Adding a Schema

A schema (also called an *archetype* in the dispatch table) defines a
custom phase pipeline for a project type. Forge currently ships seven
schemas: `default`, `full-stack-monorepo`, `mobile-only`, `tdd-flutter`,
`tdd-rust`, `ai-first`, and `rapid`.

### The 2 steps

1. **Create the file** — `.forge/schemas/<name>/schema.yaml`:
   ```yaml
   name: <name>
   description: <description>
   phases:
     - id: vision
       command: /forge:vision
       required: true
     - id: explore
       command: /forge:explore
       required: false
     # ... other phases
   gates:
     constitution: strict      # Never relax
     tdd: mandatory            # Never make optional
   tools:
     # Schema-specific configurations (golden tests, clippy, etc.)
   ```

   The schema MUST validate against `.forge/schemas/change.schema.json`
   (JSON Schema Draft 2020-12, enforced by `verify.sh` via the
   `f2-yaml-schema` gate).

2. **Test with a real project** — Create a test project from scratch,
   apply the schema, and walk the entire pipeline. Document the results in
   the PR.

**Hard constraint**: A schema cannot make TDD optional. `tdd: optional` is
a Constitution violation — the PR will be rejected.

---

## Modifying the Constitution

The Constitution is the supreme law of Forge. It contains twelve articles
that define the framework's non-negotiable rules. Modifying it is a
serious act.

### Amendment process

The full amendment workflow is defined in **`GOVERNANCE.md` § Amendment
Process** (formalized in change `d5-governance`, ratified 2026-04-30).
Summary:

1. **Documented justification** — Open a Forge change proposal: which
   article is affected, why the current rule is problematic, what
   modification is proposed, and the impact on existing projects.

2. **Maintainer approval** — The BDFL (or co-maintainer in the BDFL's
   absence) must explicitly approve. No automated merges, no agent voting.

3. **Discussion window** — A minimum 7-day public discussion period
   before ratification (Article XII).

4. **Append to the amendment registry** — Record the amendment in the
   table at the bottom of `constitution.md` with date, author, and a
   summary justification. Bump `constitution_version` (semver).

5. **Impact review** — Audit every existing spec under `.forge/specs/`
   for violations induced by the change.

Do not amend the Constitution lightly. Constitution stability is a
feature, not an arbitrary constraint.

---

## Conventions

### Agent naming

| Team           | Pantheon      | Examples |
|----------------|---------------|----------|
| Flutter        | Greek         | Hera, Athena, Spartan, Apollo, Hephaestus, Hermes, Iris, Argus, Prometheus, Nemesis |
| Rust           | Latin/Roman   | Vulcan, Ferris, Centurion, Tribune, Terminal, Sentinel |
| Cross-cutting  | Greek or Latin | Forge, Clio, Oracle, Socrates, Atlas, Panoptes, Aegis, Heracles, Janus |

### Standard format

- "Scope" section is mandatory — without it, triggers cannot be calibrated.
- Concrete code examples — abstract rules are less effective.
- "Anti-patterns" section is recommended — counter-examples anchor rules.
- No TODOs in shipped standards — an incomplete standard is worse than no
  standard at all.

### Command format

- Title `# /forge:<name> — Description` is mandatory.
- Sections: Purpose, Process (numbered steps), Output.
- Always number the Process steps — LLMs follow ordered steps better than
  unordered ones.

---

## Framework Tests

Before submitting a contribution, run the five validation scenarios below
and document the results in the PR.

### Scenario 1 — Empty Flutter project

1. Create an empty directory.
2. Copy Forge into it.
3. Run `/forge:init`.
4. Run `/forge:vision`.
5. Run `/forge:new feature-test`.
6. **Verify**: the Constitution is respected at each step, and the
   appropriate files are created under `.forge/changes/feature-test/`.

### Scenario 2 — Existing Rust project

1. Use an existing Rust project with code.
2. Copy Forge.
3. Run `/forge:init`.
4. Run `/forge:discover`.
5. **Verify**: existing conventions are captured in `.forge/standards/`,
   and `index.yml` is updated.

### Scenario 3 — Full TDD cycle

1. Start from a state with a task plan (`tasks.md` exists).
2. Run `/forge:implement <name>`.
3. **Verify**: the agent enforces RED (failing test written first) before
   GREEN, REFACTOR is offered after GREEN, and no step is skipped.

### Scenario 4 — Constitution violation

1. Manually create a `design.md` that violates an article (e.g., a design
   without planned tests).
2. Run `/forge:review <name>`.
3. **Verify**: the gate explicitly BLOCKS, the agent cites the violated
   article, and refuses to continue without correction.

### Scenario 5 — Delta-spec archive

1. Start from a state with a passed review.
2. Run `/forge:archive <name>`.
3. **Verify**: delta specs are merged into `.forge/specs/`, the change
   directory is marked DONE, and a summary appears in the project journal.

---

## Local pre-push validation

<!-- Audit: T5.1 (cli-trust-harness) — local pre-push helper -->

A `Taskfile.yml` at the repo root drives the full validation gauntlet
locally before you push. Requires [go-task](https://taskfile.dev/) v3.x.
Adopters never see this file — it lives at the framework repo root only.

### Quick reference

```bash
task validate          # full pre-push gauntlet (~3-6 min)
task --list-all        # all available tasks
```

### What `task validate` runs

In sequence, abort at first FAIL :

1. **`build`** — `tsc → cli/dist/` (prerequisite for everything that
   invokes the binary).
2. **`gates`** — `verify.sh` (~230 checks) + `constitution-linter.sh`
   (~35 checks). Same gates as CI.
3. **`harness`** — `.forge/scripts/tests/t5-1.test.sh --level 1` (17 L1
   grep checks ; ~50 ms).
4. **`vitest`** — full CLI vitest suite (72 tests today). Includes the
   help-snapshots golden diff, the dispatch-table cross-reference, and
   the per-archetype smoke (skip-pass `cargo`/`flutter` when absent).
5. **`smoke-with-toolchains`** — re-runs the smoke with
   `FORGE_E2E_TOOLCHAINS=1` so `cargo check --workspace` and
   `flutter analyze` actually execute (per-archetype, gated by the
   fixture's `has_rust_backend` / `has_flutter_frontend` flags).
6. **`dev-up-matrix`** — for each archetype in `vars.ACTIVE_ARCHETYPES` :
   scaffold into a tmpdir, parse the rendered `Taskfile.yml`
   (`task --list-all`), boot the dev stack via `task dev:up`, run
   `docker compose ps`, tear down. **Requires Docker daemon.** Cleanup
   is automatic via bash `trap EXIT INT TERM` — Ctrl+C will not leak
   containers.

### Granular tasks (run individually during iterative work)

| Task                          | Use when                                            | Approx. cost |
|-------------------------------|-----------------------------------------------------|--------------|
| `task harness`                | Sanity-check before commit                          | ~50 ms       |
| `task vitest`                 | After CLI source edits                              | ~5 s         |
| `task smoke-with-toolchains`  | After scaffold or fixture edits                     | ~30–60 s     |
| `task dev-up-matrix`          | After `Taskfile.yml.tmpl` or docker-compose edits   | ~1–2 min per archetype |
| `task pack-smoke`             | Pre-release tarball validation (mirrors `prepublishOnly`) | ~20 s |
| `task gates`                  | Same gates as CI without the CLI build              | ~5 s         |
| `task harness-l2`             | T5.1 L2 opt-in (`FORGE_T51_LIVE` + `FORGE_T51_PACK`) | ~30 s       |
| `task help-snapshots-update`  | After intentional `forge --help` change             | ~1 s         |
| `task clean-leaked`           | Recover after Ctrl+C during `dev-up-matrix`         | ~5 s         |

### Adding an archetype to the matrix

Append the archetype name (space-separated) to `vars.ACTIVE_ARCHETYPES`
in the root `Taskfile.yml`. The matrix iteration is fully automatic
from there :

- A fixture file at `cli/test/e2e/archetype-fixtures/<name>.yml`
  is required (the cross-reference test fails the PR if it is missing —
  per FR-T51-055).
- `task dev-up-matrix` auto-skips with `[INFO]` when the archetype ships
  no `Taskfile.yml` (e.g. `mobile-only`) or no `dev:up` task.
- `task dev-up-matrix` FAILS the run if `task --list-all` itself exits
  non-zero on the scaffolded project — that catches the entire class of
  Taskfile parse bugs that motivated T5.1 in the first place.

### Recommended cadence

- **Before each commit** : `task harness && task vitest` (~5 s ;
  catches surface drift + structural issues).
- **Before each PR / push** : `task validate` (full gauntlet ; same
  fidelity as CI plus the live `task dev:up` boot that CI does not
  run).
- **Before each release** : `task validate && task pack-smoke` (adds
  the actual `npm pack` + isolated `npm install --global --prefix`
  round-trip on top — same code path the `prepublishOnly` hook
  exercises right before `npm publish`).

---

## Continuous Integration

<!-- Audit: G.1 (g1-forge-ci, FR-CI-011) -->

Forge runs its own gates in CI on every PR and every push to `main` via
`.github/workflows/forge-ci.yml`. The workflow declares six jobs
(`harness`, `gates`, `cli`, `lint`, `example`, `summary`) and aggregates
the five worker jobs into a single status check **`forge-ci / summary`**
that branch protection requires.

### Branch protection (maintainer-only setup)

The `main` branch protection rule MUST require **`forge-ci / summary`** to
pass before merge. This rule is **configured manually by the maintainer**
via the GitHub UI — it is **not automated** by Forge (principle of least
privilege; the workflow does not have write access to repository
settings).

Setup steps (one-time, by repo owner):

1. Repository → **Settings** → **Branches** → **Branch protection rules**
   → **Add rule** for `main`.
2. Enable **Require status checks to pass before merging**.
3. Search for and select **`forge-ci / summary`** as the required check.
4. Recommended additional protections (NOT mandates — at maintainer
   discretion):
   - **Require linear history** (clean audit trail).
   - **Require signed commits** (supply-chain hygiene).
   - **Dismiss stale pull request approvals when new commits are pushed**.

Full standard: `.forge/standards/global/forge-self-ci.md`.

---

## Framework Roadmap

The authoritative product roadmap lives at
`.forge/product/roadmap.md` — refer to it for the current set of phases,
shipped tiers (T0/T1/T2/T3), and outstanding audit items. Highlights of
what is on the table, in roughly increasing time horizons:

- **Short term** — i18n ADR templates; default observability runbooks
  (SigNoz, ELK, Prometheus); finishing the `mobile-only` archetype
  (Firebase, no custom backend) and the `flutter-firebase` archetype.
- **Medium term** — `microservices` schema with inter-service contract
  management; a `DataEngineer` agent for ingestion/transformation/quality
  pipelines; bidirectional Linear/Jira traceability between Forge tasks
  and tickets.
- **Long term** — velocity metrics (cycle time per phase, bottleneck
  identification); project health dashboard (test coverage, technical
  debt, spec age); spec export to standard formats (OpenAPI for REST,
  AsyncAPI for events); multi-LLM support (different agents on different
  models, matched to their respective strengths).
