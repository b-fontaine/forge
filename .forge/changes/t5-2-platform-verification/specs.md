# Specifications: t5-2-platform-verification
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-T52-*` / `NFR-T52-*`. **Constitution** :
v1.1.0. No amendment required — T5.2 reinforces Article III.4
(anti-hallucination) by codifying a procedural axis that already
exists in spirit, not by amending the constitution itself.

## Source Documents

| Field                  | Value                                                                                                                                                                              |
|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**           | `docs/new-archetypes-plan.md` §0.2 lines 731-829 (T5.2 — Anti-Hallucination Platform Verification)                                                                                  |
| **Trigger incident**   | Q-006 — Workiva `opentelemetry 0.18.11` ratified 2026-05-12 (`t5-otel-dart-api-realign`) ; discovered web-only 2026-05-16 via `task validate` after `cli-trust-harness` Option B    |
| **Predecessor incident** | Q-004 — 9 fabricated symbols in `flutter/opentelemetry.md` v1.0.0 (resolved 2026-05-12) ; same root cause class : standard ratification without full external evidence            |
| **Standard frame**     | `global/standards-lifecycle.md` v1.0.0 (T.4 — 12-month review cycle, REVIEW.md append-only ledger) — bumped additively to v1.1.0 by this change                                    |
| **Pattern reuse**      | `global/open-questions.md` (F.1) ; `global/data-stewardship-rules.md` (K.3) ; `global/janus-orchestration-rules.md` (J.8) — standard layout precedents                             |
| **Agent precedent**    | `.claude/agents/demeter.md` (K.3) — Forge-local persona file, not an OMC plugin asset                                                                                              |
| **Harness pattern**    | `j7-validate-standards-yaml.test.sh` ; `k3.test.sh` ; `i2.test.sh` ; `i5.test.sh` — L1 grep + optional L2 opt-in via env-var                                                       |
| **Open questions**     | `open-questions.md` Q-001 (override-vs-extend OMC document-specialist) + Q-002 (L2 live-run scope)                                                                                  |
| **Downstream**         | `t5-otel-dartastic-realign` (T5.3 ; first consumer of the checklist)                                                                                                                |
| **Release target**     | `@sdd-forge/cli@0.3.4` (patch) — additive process change, no CLI surface impact                                                                                                     |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Forge-local `document-specialist` agent file (FR-T52-A-001 → 015)

> Q-001 likely resolution : Option A — ship a Forge-local agent
> file at `.claude/agents/document-specialist.md`. Final
> resolution arrives in `/forge:design` via ADR-T52-001.

##### FR-T52-A-001 — File presence

A new file `.claude/agents/document-specialist.md` MUST exist at
that path in the Forge repository. Content type Markdown.

##### FR-T52-A-002 — File ownership comment

The file MUST carry an HTML comment within the first 5 lines
identifying it as a Forge-local override of the OMC
`document-specialist` persona, e.g.
`<!-- Forge-local override of OMC document-specialist — adds T5.2 platform verification checklist -->`.

##### FR-T52-A-003 — H2 section anchor

The file MUST contain an H2 heading whose text is exactly
`## Platform Verification Checklist (3-axis)`. Case- and
whitespace-sensitive ; harness greps this string verbatim.

##### FR-T52-A-004 — Axis 1 named

The H2 section MUST name axis 1 as `Existence` (case-insensitive
match), defining it as "package resolvable on the registry
(pub.dev / crates.io / npm / Maven / etc.) with the pinned
version".

##### FR-T52-A-005 — Axis 2 named

The H2 section MUST name axis 2 as `API surface`
(case-insensitive match), defining it as "documented symbols
match those exposed by the actual package (verified via Context7
or direct inspection)".

##### FR-T52-A-006 — Axis 3 named

The H2 section MUST name axis 3 as `Platform compatibility`
(case-insensitive match), defining it as "every target platform
declared by the consuming archetype or standard is listed in the
package's declared support matrix".

##### FR-T52-A-007 — MUST tick-all clause

The H2 section MUST contain a clause stating that each axis MUST
be ticked **before** flipping the standard's status to "verified"
or equivalent ratification state.

##### FR-T52-A-008 — `[PLATFORM MISMATCH:]` marker

The H2 section MUST instruct that if any consuming-archetype
target platform is missing from the package's declared support
matrix, the ratification MUST emit a `[PLATFORM MISMATCH: …]`
marker and escalate to an ADR. The marker syntax MUST mirror the
existing `[NEEDS CLARIFICATION: …]` Article III.4 convention.

##### FR-T52-A-009 — Worked example

The H2 section MUST carry one worked example referencing Q-006
(Workiva web-only) as the trigger incident. The example MUST cite
the package name `opentelemetry`, the version `0.18.11`, the
consuming archetype `mobile-only` or `full-stack-monorepo`, and
the missing platforms (iOS, Android).

##### FR-T52-A-010 — Format of the per-dependency checklist

The H2 section MUST prescribe that each ratified external
dependency appears in the change's `proposal.md` § "Source
Documents" as a row dedicated to that dependency, listing the
three axes as ticked checkboxes (`[x]` / `[ ]` Markdown task-list
syntax). Format suggested verbatim in the section.

##### FR-T52-A-011 — Cross-reference to `standards-lifecycle.md`

The H2 section MUST cross-reference
`.forge/standards/global/standards-lifecycle.md` v1.1.0 § "Platform
compatibility re-verification" (the section that FR-T52-B
introduces). The cross-reference MUST point readers to the
re-verification cadence rules.

##### FR-T52-A-012 — Cross-reference to Article III.4

The H2 section MUST cross-reference Constitution Article III.4
(`anti-hallucination`) as the constitutional basis for the
checklist.

##### FR-T52-A-013 — Scope clarification

The H2 section MUST clarify scope : the checklist applies to
ratification of **external dependency-pinning standards** (e.g.
`flutter/opentelemetry.md`) ; it does NOT apply to pure prose
contracts (`global/open-questions.md`, `global/standards-lifecycle.md`,
`global/janus-orchestration-rules.md`) whose content is
self-contained and does not pin an external package.

##### FR-T52-A-014 — No new OMC primitive

The file MUST NOT introduce a new MCP tool, OMC slash-command, or
agent subprotocol. The override extends the existing
`document-specialist` persona's procedure ; it does not redefine
how the agent is invoked.

##### FR-T52-A-015 — Forge-local override convention

The file SHOULD follow the same H1 + H2 layout convention as
existing Forge-local agents (`.claude/agents/demeter.md`,
`.claude/agents/spec-writer.md`, `.claude/agents/forge-master.md`)
for consistency with the existing persona corpus.

#### Cluster 2 — `standards-lifecycle.md` v1.1.0 bump (FR-T52-B-001 → 010)

##### FR-T52-B-001 — Version bump in frontmatter

The frontmatter of `.forge/standards/global/standards-lifecycle.md`
MUST be bumped from `version: 1.0.0` to `version: 1.1.0`.

##### FR-T52-B-002 — `last_reviewed` bump

The frontmatter `last_reviewed:` field MUST be set to the ISO-8601
date on which T5.2 archives (target: 2026-05-17 or the actual
archive date, whichever is later).

##### FR-T52-B-003 — `breaking_change: false`

The frontmatter MUST carry `breaking_change: false` (additive
bump per Article XII).

##### FR-T52-B-004 — Audit pointer

The file MUST carry a `<!-- Audit: T.4 + T5.2 (additive bump 2026-05-17) -->`
audit comment, preserving the existing T.4 pointer and appending
T5.2.

##### FR-T52-B-005 — New H2 section anchor

The file MUST add a new H2 heading whose text is exactly
`## Platform compatibility re-verification`. The H2 MUST be
appended at the end of the file (before any trailing footer if
present) so existing H2 anchors do not shift.

##### FR-T52-B-006 — SHOULD re-run at 12-month review

The new H2 MUST contain a clause stating that any standard which
pins an external dependency SHOULD re-execute the 3-axis checklist
(per `.claude/agents/document-specialist.md` § "Platform
Verification Checklist (3-axis)") during each 12-month review.

##### FR-T52-B-007 — MUST re-run on platform addition

The new H2 MUST contain a clause stating that any standard which
pins an external dependency MUST re-execute the 3-axis checklist
**immediately** when the consuming archetype declares a **new
target platform** (e.g. `mobile-pwa-first` adding PWA Qwik in T8
relative to `mobile-only` v1.0.0, or any archetype declaring a new
compliance tier with different platform constraints).

##### FR-T52-B-008 — MUST pre-ratify a new standard

The new H2 MUST contain a clause stating that the checklist MUST
be executed **before** any new external dependency-pinning
standard is ratified (i.e. the first ratification, not only
subsequent reviews).

##### FR-T52-B-009 — Cross-reference to checklist

The new H2 MUST cross-reference the `Platform Verification
Checklist (3-axis)` H2 in `.claude/agents/document-specialist.md`
by its exact title, so the two surfaces are bidirectionally
discoverable.

##### FR-T52-B-010 — Q-006 worked example mention

The new H2 MUST mention Q-006 (Workiva web-only platform
mismatch) by name as the incident that motivated the
re-verification cadence. One sentence is sufficient.

#### Cluster 3 — `REVIEW.md` ledger entry (FR-T52-C-001 → 003)

##### FR-T52-C-001 — Ledger entry presence

`.forge/standards/REVIEW.md` MUST gain an append-only H2 entry of
the form `## 2026-05-17 — standards-lifecycle.md v1.0.0 → v1.1.0`
(or the actual archive date in place of 2026-05-17), placed at the
chronological tail of the ledger (per Article XII append-only
rule).

##### FR-T52-C-002 — Entry body content

The H2 entry body MUST cite (a) the change name
`t5-2-platform-verification`, (b) the trigger incident `Q-006`,
(c) the new H2 anchor `Platform compatibility re-verification`,
and (d) `breaking_change: false`.

##### FR-T52-C-003 — No edits to prior ledger entries

Existing H2 entries in `REVIEW.md` MUST NOT be modified, deleted,
or re-ordered (Article XII immutability).

#### Cluster 4 — Harness `t5-2.test.sh` L1 grep assertions (FR-T52-D-001 → 010)

##### FR-T52-D-001 — File presence

A new file `.forge/scripts/tests/t5-2.test.sh` MUST exist and be
executable (`chmod +x`). The script MUST follow the conventional
sourcing pattern of sibling harnesses (`set -euo pipefail`,
`source` of the shared test helpers if any).

##### FR-T52-D-002 — Test name namespace

Each test function in the harness MUST be named
`_test_t52_l1_NNN_<description>` (or `_test_t52_l2_NNN_<description>`
for L2-opt-in tests), mirroring the existing convention
(`_test_i5_l1_001_*`, `_test_k3_l1_001_*`, etc.).

##### FR-T52-D-003 — L1.001 — agent file presence

Test `_test_t52_l1_001_agent_file_present` MUST assert that
`.claude/agents/document-specialist.md` exists and is non-empty.

##### FR-T52-D-004 — L1.002 — checklist H2 present

Test `_test_t52_l1_002_checklist_h2` MUST assert that
`.claude/agents/document-specialist.md` contains the exact string
`## Platform Verification Checklist (3-axis)` (FR-T52-A-003).

##### FR-T52-D-005 — L1.003 — three axes named

Test `_test_t52_l1_003_three_axes_named` MUST assert that the
agent file contains the three axis labels `Existence`,
`API surface`, and `Platform compatibility` within the H2 section
(FR-T52-A-004 / 005 / 006).

##### FR-T52-D-006 — L1.004 — `[PLATFORM MISMATCH:]` token

Test `_test_t52_l1_004_platform_mismatch_token` MUST assert that
the agent file contains the literal token `[PLATFORM MISMATCH:`
(FR-T52-A-008).

##### FR-T52-D-007 — L1.005 — standards-lifecycle v1.1.0

Test `_test_t52_l1_005_lifecycle_v110` MUST assert that
`.forge/standards/global/standards-lifecycle.md` frontmatter
declares `version: 1.1.0` (FR-T52-B-001).

##### FR-T52-D-008 — L1.006 — re-verification H2

Test `_test_t52_l1_006_re_verification_h2` MUST assert that
`.forge/standards/global/standards-lifecycle.md` contains the
exact string `## Platform compatibility re-verification`
(FR-T52-B-005).

##### FR-T52-D-009 — L1.007 — REVIEW ledger entry

Test `_test_t52_l1_007_review_ledger_entry` MUST assert that
`.forge/standards/REVIEW.md` contains a H2 line matching the
pattern `^## 20[0-9]{2}-[0-9]{2}-[0-9]{2} — standards-lifecycle.md v1.0.0 → v1.1.0$`
(FR-T52-C-001).

##### FR-T52-D-010 — L1.008 — Article III.4 cross-reference

Test `_test_t52_l1_008_article_iii4_xref` MUST assert that the
agent file contains a reference to `Article III.4` (FR-T52-A-012).

#### Cluster 5 — Harness L2 opt-in live-run (FR-T52-E-001 → 004)

> Q-002 likely resolution : Option A — pub.dev tooling smoke on a
> stable package. Final resolution arrives in `/forge:design` via
> ADR-T52-002.

##### FR-T52-E-001 — L2 gate env-var

The harness MUST treat the L2 test as **opt-in via
`FORGE_T52_LIVE=1`**. When unset or set to any other value, the
L2 test MUST skip-pass (printing a skip marker conforming to the
existing harness skip-pass convention).

##### FR-T52-E-002 — L2.001 — tooling smoke

Test `_test_t52_l2_001_pubdev_tooling_smoke` (gated by
FR-T52-E-001) MUST attempt to fetch the public pub.dev page for
a well-known stable package (default candidate :
`flutter_bloc`, which is the ratified state-management dependency
per `.forge/standards/state-management.yaml`). The test MUST
assert that the fetched HTML contains the substring `Platforms`
(the chip label on pub.dev) and at least one of the platform
tokens (`Android`, `iOS`, `Linux`, `macOS`, `Web`, `Windows`).

##### FR-T52-E-003 — Skip-pass on network unreachability

The L2 test MUST skip-pass (not fail) if the network is
unreachable or pub.dev returns a non-2xx status. The skip marker
MUST explain the transport failure. Pattern mirrors
`t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1` skip-pass behaviour.

##### FR-T52-E-004 — Wall-clock budget for L2

The L2 test MUST complete in ≤ 10 s wall-clock on a typical CI
runner (Ubuntu latest, single core). The harness MUST enforce a
20 s hard timeout and convert overruns to skip-pass with an
explicit timeout marker.

#### Cluster 6 — `docs/CONTRIBUTING.md` update (FR-T52-F-001 → 003)

##### FR-T52-F-001 — Section presence

`docs/CONTRIBUTING.md` MUST contain a section whose H2 or H3
heading mentions "Adding a Standard" (the existing or to-be-added
section ; T5.2 may augment a pre-existing section rather than
create a new one).

##### FR-T52-F-002 — Checklist verbatim or cross-reference

The "Adding a Standard" section MUST either (a) carry the 3-axis
checklist verbatim, or (b) cross-reference
`.claude/agents/document-specialist.md` § "Platform Verification
Checklist (3-axis)" by its exact H2 title. Option (b) is preferred
to avoid drift between the two surfaces.

##### FR-T52-F-003 — Q-006 mention

The section MUST mention Q-006 (Workiva web-only) by name as the
incident that motivated the checklist, with at most one
sentence of context.

#### Cluster 7 — `docs/LINTING.md` update (FR-T52-G-001 → 002)

##### FR-T52-G-001 — Informative entry

`docs/LINTING.md` MUST gain a paragraph or bullet under an
"Informative rules" or "Process rules" section noting that the
3-axis platform-verification checklist exists. The paragraph
MUST clarify that the checklist is **procedural**, not enforced
by `constitution-linter.sh` (T5.2 ships the convention ;
enforcement is future work, possibly T6+).

##### FR-T52-G-002 — Pointer

The entry MUST link or cross-reference
`.claude/agents/document-specialist.md` § "Platform Verification
Checklist (3-axis)" by its exact title.

#### Cluster 8 — `CHANGELOG.md` + CI matrix (FR-T52-H-001 → 003)

##### FR-T52-H-001 — CHANGELOG entry

`CHANGELOG.md` MUST gain an entry under the next patch-line
heading (target: `v0.3.4` or the actual release vehicle) of the
form `- T5.2: Anti-hallucination platform-verification checklist
(3-axis) added to document-specialist agent + standards-lifecycle.md
v1.1.0`. The entry MUST cite the change name verbatim.

##### FR-T52-H-002 — CI matrix registration

`.github/workflows/forge-ci.yml` MUST register the new harness
`t5-2.test.sh` in the `harness` matrix job, mirroring the
registration of sibling harnesses (`j7-validate-standards-yaml.test.sh`,
`k3.test.sh`, `i5.test.sh`).

##### FR-T52-H-003 — Forge-questions surface

`bin/forge-questions.sh` MUST surface the change
`t5-2-platform-verification` when invoked without `--change`
filter, until the change is archived. No code change is needed
in the script itself ; this requirement asserts that the
`.forge/changes/t5-2-platform-verification/open-questions.md`
file conforms to the F.1 open-questions convention.

### Non-Functional Requirements

##### NFR-T52-001 — Zero new external dependency

The change MUST NOT add any new external dependency to `cli/`,
to the Forge bundle, or to the harness toolchain. The L2 live-run
relies on `curl` (already required by sibling harnesses) and the
standard POSIX shell environment. No new npm package, cargo crate,
or pub.dev package is introduced.

##### NFR-T52-002 — Harness wall-clock budget

The full `t5-2.test.sh` run MUST complete in ≤ 5 s wall-clock at
`--level 1` (L1 grep only) on a typical CI runner. The L2 layer
adds at most 10 s (FR-T52-E-004), capping the total at ≤ 15 s
with `--level 1,2` AND `FORGE_T52_LIVE=1`.

##### NFR-T52-003 — Auditability via REVIEW ledger

The `standards-lifecycle.md` v1.1.0 bump MUST appear in
`REVIEW.md` (FR-T52-C-001) so a future auditor can reconstruct
the sequence of standard versions without reading git history
(Article XII requirement).

##### NFR-T52-004 — Backward compatibility

The change MUST NOT break any existing harness, any existing CI
matrix entry, any existing standard's frontmatter validation
(J.7), or any existing archived change. Specifically, the
`standards-lifecycle.md` bump v1.0.0 → v1.1.0 MUST preserve all
existing H2 sections verbatim (additive bump).

##### NFR-T52-005 — No behavioural change to existing standards

The change MUST NOT modify the content of any existing
`.forge/standards/**/*.yaml` or `.forge/standards/**/*.md` file
other than `standards-lifecycle.md`. In particular, the six
ratified YAML standards (`transport`, `state-management`,
`observability`, `orchestration`, `identity`, `persistence`)
MUST remain byte-identical.

##### NFR-T52-006 — No CLI surface impact

The change MUST NOT add, remove, or modify any flag, subcommand,
positional argument, exit code, stderr/stdout pattern, or
environment variable of the `forge` CLI binary published as
`@sdd-forge/cli`. The change is internal to the
ratification process and the documentation corpus.

##### NFR-T52-007 — Test failure mode

When the harness fails an L1 assertion, the failure message MUST
identify the failing FR-T52-* identifier (or at minimum the
cluster letter A/B/C/D/F/G/H). This eases triage during PR
review.

##### NFR-T52-008 — Article XII compliance

The change MUST comply with Article XII (Standards Lifecycle).
Specifically : the `standards-lifecycle.md` bump MUST be
additive (`breaking_change: false`), the REVIEW.md entry MUST
be append-only, and the existing standard's `expires_at:` field
(or lack thereof for a self-referential standard) MUST be
preserved.

##### NFR-T52-009 — Article III.4 reinforcement

The change MUST be self-consistent with Article III.4
(anti-hallucination) which it reinforces. In particular, the
checklist MUST itself be auditable : every claim it makes
(e.g. "pub.dev exposes a `Platforms` chip") MUST be verifiable
by an adopter following the linked references.

##### NFR-T52-010 — Documentation drift prevention

The cross-references between
`.claude/agents/document-specialist.md`,
`.forge/standards/global/standards-lifecycle.md`,
`docs/CONTRIBUTING.md`, and `docs/LINTING.md` MUST use **exact**
H2 titles (verbatim quoting) rather than paraphrased titles, so a
future rename in any one surface is immediately caught by the
harness L1 grep assertions.

---

## BDD Acceptance Criteria

The change has no user-facing CLI behaviour, so most FRs are not
BDD-shaped. The two scenarios below cover the cases where an
adopter or contributor interacts with the new artefacts.

### BDD-T52-001 — Contributor adds a new dependency-pinning standard

```gherkin
Given a contributor has authored a new draft standard
  `.forge/standards/<lang>/<dep>.md` that pins an external
  package (e.g. `dartastic_opentelemetry_api`)
And the contributor opens a Forge change to ratify the standard
When the contributor reads
  `.claude/agents/document-specialist.md` to follow the
  ratification procedure
Then the contributor MUST find the H2 section
  `## Platform Verification Checklist (3-axis)`
And the section MUST instruct them to verify
  existence + API surface + platform compatibility
And the section MUST tell them to emit
  `[PLATFORM MISMATCH: ...]` and escalate to an ADR if any
  consuming-archetype target platform is missing from the
  package's declared support matrix.
```

### BDD-T52-002 — Reviewer audits a ratified standard one year later

```gherkin
Given a reviewer audits a standard one year after its
  ratification (Article XII 12-month review window)
And the standard pins an external dependency
When the reviewer opens
  `.forge/standards/global/standards-lifecycle.md`
Then the reviewer MUST find an H2 section
  `## Platform compatibility re-verification`
And the section MUST instruct them to re-run the 3-axis
  checklist
And the section MUST cite Q-006 as the incident motivating the
  cadence
And the REVIEW.md ledger MUST carry the v1.1.0 entry as evidence
  of when the cadence was added.
```

---

## Anti-Hallucination Pass

Every FR in this spec has been audited against the four guards :

| FR cluster | Testable ?                                     | Ambiguous ?                                          | Constitution-compliant ? | External-dependency claim ?              |
|------------|------------------------------------------------|------------------------------------------------------|--------------------------|------------------------------------------|
| A (agent)  | YES — grep + file presence                     | No `[NEEDS CLARIFICATION]` raised                    | Article III.4 reinforced  | None — Forge-local file only             |
| B (lifecycle) | YES — frontmatter + H2 grep                 | No `[NEEDS CLARIFICATION]` raised                    | Article XII additive     | None — existing Forge standard           |
| C (REVIEW) | YES — pattern grep                             | No                                                   | Article XII append-only  | None                                     |
| D (harness L1) | YES — each test maps to one FR             | No                                                   | Article I (TDD)          | None                                     |
| E (harness L2) | YES — opt-in via env-var ; skip-pass       | pub.dev as canonical target — verifiable             | Article I (TDD)          | pub.dev exists ; verified via Q-006 prior |
| F (CONTRIBUTING) | YES — section grep                        | No                                                   | Article III              | None                                     |
| G (LINTING)  | YES — section grep                           | No                                                   | Article III              | None                                     |
| H (CHANGELOG / CI) | YES — entry grep + workflow registration | No                                                   | Article V                | None                                     |

No FR currently carries a `[NEEDS CLARIFICATION:]` marker. Two
open questions (Q-001, Q-002) are recorded in
`open-questions.md` and MUST be resolved before `/forge:plan`
runs.

---

## Out of Scope (asserted negatively)

- No new `.forge/standards/*.yaml` file. (NFR-T52-005)
- No retroactive re-ratification of the existing six YAML
  standards or the seven existing `global/*.md` standards.
- No `constitution-linter.sh` enforcement rule for the checklist
  (FR-T52-G-001 makes this explicit).
- No upstream PR to OMC (deferred per Q-001 option C).
- No update to `flutter/opentelemetry.md` — that is T5.3's scope.
- No new Forge agent persona.
- No new CLI flag, subcommand, or behaviour change to
  `@sdd-forge/cli` (NFR-T52-006).

---

> **Next step** : `/forge:design t5-2-platform-verification`
> which produces two ADRs (ADR-T52-001 resolving Q-001 — Forge
> override strategy ; ADR-T52-002 resolving Q-002 — L2 live-run
> scope) plus the architecture-level decisions for the harness
> structure and the checklist phrasing.
