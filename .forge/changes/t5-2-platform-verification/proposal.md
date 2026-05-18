# Proposal: t5-2-platform-verification
<!-- Created: 2026-05-17 -->
<!-- Schema: default -->
<!-- Audit: T5.2 (docs/new-archetypes-plan.md §0.2) -->

## Problem

The `t5-otel-dart-api-realign` change (archived 2026-05-12, PR #8)
ratified the Flutter OpenTelemetry standard against the real
Workiva `opentelemetry: 0.18.11` package on pub.dev. The
ratification verified two axes :

1. **Existence** — package resolvable on pub.dev with the pinned
   version.
2. **API surface** — published symbols match the prose in
   `flutter/opentelemetry.md` (9 fabricated symbols removed, 7
   verified symbols added).

Four days later, `task validate` on a freshly scaffolded
flagship project (2026-05-16, the day `cli-trust-harness`
landed) surfaced **Q-006** : the Workiva package is **web-only**
on pub.dev. Flutter mobile (iOS + Android) — the first-class
target of `full-stack-monorepo` and `mobile-only` — is
**structurally unsupported** by the pinned dependency.

The ratification process omitted a third axis :

3. **Platform target compatibility** — the package's declared
   support matrix (pub.dev `Platforms` chip, Cargo
   `[package.metadata.docs.rs] targets`, npm `os`/`cpu` fields,
   etc.) includes every target the consuming archetype claims.

This is not a one-off mistake : the same procedure produced :

- The `opentelemetry_sdk` phantom package in
  `b4-mobile-only / pubspec.yaml.tmpl` (does not exist on
  pub.dev at all — discovered during `cli-trust-harness`
  Option B validation 2026-05-16).
- The Workiva web-only mismatch propagated into `t5-otel-app`
  (flagship frontend Flutter) and `b4-mobile-only` (mobile
  template), now requiring the full `t5-otel-dartastic-realign`
  (T5.3, XL effort, target v0.4.0-rc.1).

Three concrete gaps make a repeat likely without a process change :

1. **No canonical 3-axis checklist** exists in the
   `document-specialist` ratification procedure. Existence and
   API surface are routinely verified ; platform compatibility
   is not.
2. **No re-verification cadence** in
   `standards-lifecycle.md` v1.0.0 ties the existing 12-month
   review window to a platform-targets re-check. A standard
   pinning a web-only library survives a 12-month review
   unchanged today, even if its consuming archetype adds a
   mobile target meanwhile.
3. **No structural enforcement** : there is no harness that
   asserts the checklist is present in the ratification
   pipeline, so a future contributor can skip the platform axis
   silently.

This change closes the three gaps **before** `t5-otel-dartastic-realign`
(T5.3) ratifies Dartastic — so T5.3 becomes the first consumer of
the new checklist instead of a retroactive fix.

## Solution

A **process change**, not a code change. Three artefacts, one
documentation pass, one harness :

1. **3-axis ratification checklist** added to the
   `document-specialist` ratification procedure as a new H2
   section **« Platform Verification Checklist (3-axis) »**.
   Each ratification of an external dependency-pinning standard
   MUST tick the three axes (existence / API surface / platform
   compatibility) before flipping its status to "verified". If
   any target platform is missing from the package's declared
   support matrix, the checklist mandates a
   `[PLATFORM MISMATCH:]` marker and an escalation path to an
   ADR.
2. **Re-verification cadence** added by bumping
   `.forge/standards/global/standards-lifecycle.md` from
   v1.0.0 → **v1.1.0** (additive, no breaking change ; REVIEW.md
   ledger entry per Article XII). A new H2 documents that any
   standard pinning an external dependency :
   - SHOULD re-run the 3-axis checklist at each 12-month review.
   - MUST re-run the checklist when the consuming archetype
     **adds a target platform** (e.g. `mobile-pwa-first` adding
     PWA Qwik in T8, or any archetype declaring a new tier).
3. **Harness `t5-2.test.sh`** asserts the checklist exists in
   `document-specialist`, `standards-lifecycle.md` v1.1.0 is
   shipped with the new section, and the REVIEW ledger has an
   entry dated 2026-05-XX.
4. **Documentation pass** updates `docs/CONTRIBUTING.md
   § Adding a Standard` and `docs/LINTING.md` to surface the
   checklist for adopters and contributors.

The change ships **no new agent**, **no new linter rule**, **no
new toolchain dependency**. It is a deliberately small
methodological inflection point sized to land before T5.3 begins.

## Scope In

- New H2 « Platform Verification Checklist (3-axis) » added to
  the Forge-local `document-specialist` agent file (see Q-001
  for the override-vs-extend decision).
- Bump `.forge/standards/global/standards-lifecycle.md`
  v1.0.0 → v1.1.0 with a "Platform compatibility re-verification"
  H2 (additive).
- `.forge/standards/REVIEW.md` append-only ledger entry
  documenting the v1.1.0 bump (Article XII).
- Harness `.forge/scripts/tests/t5-2.test.sh` with ≥ 6 L1 grep
  assertions + 1 L2 opt-in (`FORGE_T52_LIVE=1`) exercising the
  checklist on a public pub.dev package as a sanity check on the
  Context7 / WebFetch tooling.
- Registration of the new harness in `forge-ci.yml`.
- `docs/CONTRIBUTING.md § Adding a Standard` updated with the
  3-axis checklist verbatim.
- `docs/LINTING.md` mentions the ratification rule (informative,
  not enforcing).
- `CHANGELOG.md` entry under the next patch line.

## Scope Out (Explicit Exclusions)

- **No code change** to `bin/forge-*.sh` or `cli/src/**`. T5.2
  is methodological.
- **No new `.forge/standards/*.yaml`** — the checklist is
  procedural ; the only standard touched is the existing
  `standards-lifecycle.md`, bumped additively.
- **No linter enforcement** of the checklist. Enforcement
  requires parsing per-change `proposal.md` and is deferred
  until T5.2 adoption produces enough signal to design a
  meaningful rule. T5.2 ships the convention ; enforcement is
  future work.
- **No retroactive re-ratification** of the six already-shipped
  YAML standards (`transport`, `state-management`,
  `observability`, `orchestration`, `identity`, `persistence`)
  or the four shipped `global/*.md` standards (`open-questions`,
  `standards-lifecycle`, `compliance-tiers`,
  `compliance-artefacts-bundle`, `data-stewardship-rules`,
  `forbidden-components-rules`, `forge-compliance-workflow`,
  `janus-orchestration-rules`, `sbom-policy`). None of them
  pin a platform-sensitive external dependency that was not
  already audited (most are pure prose contracts).
- **No update to `flutter/opentelemetry.md`**. That is T5.3's
  scope (XL change, target v0.4.0-rc.1). T5.2 ships the
  checklist ; T5.3 ticks it inline as its first consumer.
- **No new Forge agent** — the checklist lives inside an
  existing agent persona, not as a new persona file.
- **No Themis territory** (NIS2 / DORA / CRA / AI Act regulatory
  artefacts). Those are K.5 + T7+.

## Impact

- **Users affected** : Forge contributors writing new standards
  that pin external dependencies (today : Flutter and Rust
  package authors). End-user adopters are unaffected — the
  change is internal to the ratification pipeline.
- **Technical impact** :
  - One agent file edited (Forge-local override or fresh copy ;
    cf. Q-001).
  - One standard file bumped additively.
  - One new harness file.
  - Two documentation files updated.
  - One CHANGELOG entry.
  - One CI matrix entry in `forge-ci.yml`.
- **Dependencies** :
  - **Hard prerequisite** : none. T5.1 is closed (`@sdd-forge/cli@0.3.3`
    released 2026-05-16) and unblocks the working tree.
  - **Downstream consumer** : `t5-otel-dartastic-realign` (T5.3) will
    be the first standard to tick the new checklist inline.
- **Risk** : minimal. Additive process change with a harness
  that proves the docs are in place. Worst case : adopters
  ignore the checklist, in which case T5.2 buys nothing — but it
  takes nothing away either.
- **Release target** : **v0.3.4** (patch). The change is
  documentation + one additive standard bump ; it does not
  affect any user-facing CLI surface, so semver patch is
  appropriate per `docs/VERSIONING.md`. T5.3 stays on its own
  v0.4.0-rc.1 trajectory and is unblocked, not held back, by
  this change.

## Constitution Compliance

- **Article I (TDD)** : the harness `t5-2.test.sh` is written
  RED first (assertions fail against an empty stub) then GREEN
  after the deliverable files exist. Standard L1 grep pattern.
- **Article II (BDD)** : no user-facing feature, no
  Given/When/Then scenarios needed. Process change only.
- **Article III (Specs Before Code)** : this proposal is the
  spec entry point. `/forge:specify` will derive FRs from the
  three deliverables (checklist + cadence + harness) ; no
  implementation begins before `/forge:plan` archives `tasks.md`.
- **Article V (Audit Trail)** : ratified as a `.forge/changes/`
  entry. REVIEW.md append-only entry for the `standards-lifecycle.md`
  bump. No silent edits to existing artefacts.
- **Article VI / VII** : neither Flutter-specific nor
  Rust-specific. Process layer.
- **Article III.4 (Ambiguity Protocol — anti-hallucination)** : T5.2 **is** the procedural
  reinforcement of Article III.4 — it codifies the prevention of
  one specific class of hallucination (platform incompatibility
  silently ratified). The change is self-consistent with the
  article it strengthens.
- **Article XII (Standards Lifecycle)** : strictly additive bump
  v1.0.0 → v1.1.0 with REVIEW.md ledger entry. Frontmatter
  preserved. No breaking change.

## Open Questions

Two open questions are recorded in `open-questions.md` and MUST
be resolved before `/forge:plan` per the Open Questions Gate
(Article III.4 / `global/open-questions.md`) :

- **Q-001** — override-vs-extend strategy for the OMC
  `document-specialist` agent (the file is in
  `~/.claude/plugins/.../omc/agents/`, not in Forge's repo).
- **Q-002** — scope of the L2 opt-in sanity-check live-run.

---

> **Mentor note** : T5.2 is deliberately a *small* change. The
> temptation is to fold T5.3 (Workiva → Dartastic) into the same
> branch since both came out of the same Q-006 discovery. Resist :
> T5.2 is process, T5.3 is breaking standard rewrite, they have
> different release vehicles (patch vs minor-rc) and very
> different blast radii. Land T5.2 first so T5.3 ticks its
> checklist inline rather than retrofitting.

— *Proposal authored 2026-05-17. Ready for `/forge:specify`
once Q-001 + Q-002 are resolved.*
