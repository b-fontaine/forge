# Specifications: b7-2a-dispatch-register

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.7.2 (docs/new-archetypes-plan.md §6.2 — ai-native-rag dispatch registration slice) -->

**Namespace** : `FR-B7-2A-*` / `NFR-B7-2A-*` / `ADR-B7-2A-*`.
**Constitution** : v2.0.0, unchanged. Additive. Resolves `b7-1-schema` Q-005.
**Governing articles** : III.1/III.2 (specs before code), III.4 (anti-hallucination),
IV (delta/additive), I (TDD — harness RED before the entry/wrapper).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §6.2 B.7.2 (scaffolder); this is its first additive slice (dispatch registration only) |
| **Q-005 (origin)** | `.forge/changes/b7-1-schema/open-questions.md` + `.forge/specs/ai-native-rag.md` — `forge init` refuses exit 2 (unknown), flip to exit 3 deferred here |
| **Dispatch schema (observed)** | `.forge/scaffolding/dispatch-table.yml` FR-IW-002: name/scaffolder/description/signals/since (+ tolerated `status`); parser `cli/src/domain/dispatch-table.ts` |
| **Unknown-archetype gate (observed)** | `init.ts:210-216` → exit 2 when archetype ∉ dispatchTable.archetypes |
| **Refusal path (observed)** | `init.ts:225-238` → `resolveScaffolder` (`init-archetype.ts:128-154`): metas non-empty + `selectScaffoldableVersion` null ⇒ `{kind:"refuse"}` ⇒ exit 3, scaffolder untouched. `readArchetypeSchemas` (`cli.ts:135-156`) generic over `<assets>/.forge/schemas/<archetype>/*.yaml`. Caveat: empty metas (line 137) ⇒ legacy `kind:"ok"` ⇒ would run the wrapper — so the schema must be bundled. |
| **Scaffolder-exists gate (observed)** | `b5.test.sh::test_dispatch_scaffolders_exist` (142-165): scaffolder must be a real file OR `<built-in>`/`<removed>` OR `status: removed_from_roadmap` |
| **ABI (observed)** | dispatch-table.yml header + `global/scaffolding.md`: entry + `bin/forge-init-<archetype>.sh` wrapper |
| **Framework version (observed)** | 0.4.0 (`cli/package.json`, `cli/VERSION`); `[Unreleased]` is next |
| **Downstream** | B.7.2-full (templates + scaffold-plan + real wrapper body + promotion), B.7.3 (standards) |
| **Release target** | maintainer-set ([Unreleased]) |

---

## ADDED Requirements

### Functional

##### FR-B7-2A-001 — dispatch entry present & well-formed
`.forge/scaffolding/dispatch-table.yml` MUST gain an `ai-native-rag` entry with
`name: ai-native-rag` (== key), `scaffolder: bin/forge-init-ai-native-rag.sh`,
a one-line `description`, `signals: []`, and a `since:` SemVer (Q-001).

##### FR-B7-2A-002 — refusing wrapper exists, executable, ABI-shaped
`bin/forge-init-ai-native-rag.sh` MUST exist, be executable, be `bash`, and
follow the `global/scaffolding.md` wrapper ABI shape. Its body MUST refuse:
print a structured `[REFUSAL: ai-native-rag: not-yet-scaffoldable ...]` to stderr
and exit 3, performing **zero** filesystem writes (ADR-B7-2A-003).

##### FR-B7-2A-003 — CLI refusal flips exit 2 → exit 3
After registration, `forge init <name> --archetype ai-native-rag --org <rd>` MUST
exit **3** (the `resolveScaffolder` no-scaffoldable-version refusal), no longer
exit 2. No scaffold is produced. (Relies on the candidate schema being bundled
into `cli/assets` — NFR-B7-2A-002.)

##### FR-B7-2A-004 — scaffolder-exists gate stays GREEN
`b5.test.sh::test_dispatch_scaffolders_exist` MUST stay GREEN: the new entry's
scaffolder path resolves to the real `bin/forge-init-ai-native-rag.sh` (no
`b5.test.sh` edit required — FR-B7-2A-002 provides the file).

##### FR-B7-2A-005 — b7-1 L2 assertion flipped to exit 3
`.forge/scripts/tests/b7-1.test.sh` `_test_b71_l2_001_init_refuses` MUST assert
exit **3** (updated docstring), reflecting the now-registered, non-scaffoldable
state. The CI-mode skip-pass gating (`FORGE_B7_1_LIVE`) is unchanged.

##### FR-B7-2A-006 — dedicated harness
`.forge/scripts/tests/b7-2a.test.sh` MUST assert: (L1) the dispatch entry is
present & well-formed; the wrapper exists/executable/bash and refuses exit 3 when
invoked directly with zero writes; (L2, opt-in `FORGE_B7_2A_LIVE` + built CLI,
skip-pass otherwise) the CLI refuses ai-native-rag with exit 3. Registered in
`.github/workflows/forge-ci.yml`.

##### FR-B7-2A-007 — CLI e2e couplings kept green (Q-003)
Registering an active archetype couples to the T5.1 CLI e2e suite. This change
MUST keep `cd cli && npm test` green:
- `cli/src/cli.ts` `--archetype` help text MUST name `ai-native-rag`, and the
  `init.snap.txt` help snapshot MUST be regenerated (`help-snapshots.test.ts`
  enumerates active archetypes).
- `cli/test/e2e/archetypes-smoke.test.ts` MUST partition `status === "candidate"`
  out of the fixture/scaffold matrix and assert candidates refuse with **exit 3 +
  no scaffold** (no fixture required). Scaffoldable archetypes keep the exit-0 +
  file-matrix contract.

### Non-Functional

##### NFR-B7-2A-001 — additive / minimal blast radius
No templates/standards/pins/scaffold-plan. No schema/constitution/standard
touched; the schema stays `candidate` / `scaffoldable: false` (no promotion).
Existing-file edits are confined to the dispatch registration and its **tested
couplings** (corrected post-review — the first author pass under-scoped this):
- `.forge/scaffolding/dispatch-table.yml` (append the entry),
- the b7-1 L2 assertion (verified exit-2→3 flip) + the CI matrix (harness reg),
- **`cli/src/cli.ts`** `--archetype` help text + the `init.snap.txt` help snapshot
  — `help-snapshots.test.ts` asserts every non-`removed_from_roadmap` archetype is
  named in `forge init --help`,
- **`cli/test/e2e/archetypes-smoke.test.ts`** — partitions `candidate` (refusing,
  exit 3, no fixture) from scaffoldable archetypes (fixture + scaffold matrix), so
  registering a non-scaffoldable archetype does not break the smoke contract.
Registering an **active** archetype has a hard coupling to these CLI e2e tests
(they enumerate active dispatch-table archetypes); the ground-truth pass must
include them (Article III.4 lesson, Q-003).

##### NFR-B7-2A-002 — runtime flip requires the schema bundled
The exit-3 flip depends on `<assets>/.forge/schemas/ai-native-rag/1.0.0.yaml`
being present so `readArchetypeSchemas` returns a non-empty metas list (else the
legacy `metas.length===0` fallback would try to run the wrapper). `npm run
bundle` copies it (as for every archetype); the L2 fixture documents the
build prerequisite.

##### NFR-B7-2A-003 — no regression
`verify.sh`, `constitution-linter.sh`, `b5.test.sh`, and the full harness suite
stay GREEN after the change.

## ADRs (seeded — resolved at /forge:design)

- **ADR-B7-2A-001** — refusing wrapper (not a `<pending>` sentinel + b5 edit).
- **ADR-B7-2A-002** — refusal exit code 3 (CLI guard + wrapper, consistent).
- **ADR-B7-2A-003** — wrapper: structured stderr refusal, exit 3, zero writes.

## Acceptance Criteria (impl)

1. `ai-native-rag` entry in dispatch-table.yml (name/scaffolder/description/
   signals/since).
2. `bin/forge-init-ai-native-rag.sh` exists, executable; direct invocation → exit 3,
   no writes.
3. `forge init <name> --archetype ai-native-rag --org <rd>` → exit 3 (live).
4. `b5.test.sh` GREEN (scaffolder-exists); `b7-1.test.sh` L2 asserts exit 3.
5. `b7-2a.test.sh` GREEN; registered in forge-ci.yml.
6. `verify.sh` + `constitution-linter.sh` no regression; schema unchanged
   (still candidate/scaffoldable:false).
