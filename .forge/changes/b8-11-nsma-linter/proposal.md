# Proposal: b8-11-nsma-linter

<!-- Created: 2026-06-03 -->
<!-- Schema: default -->
<!-- Audit: B.8.11 (docs/new-archetypes-plan.md §4.2 lines 2330-2332 — NSMA linter activation; ratified by ADR-006 ARCHITECTURE-TARGET.md:376-397) -->

## Problem

The Forge Constitution Article VI.3 mandates `flutter_bloc` **exclusively**
and forbids Provider/Riverpod/GetX/MobX "without explicit constitutional
amendment". ADR-006 ratifies the same: alternatives are "bloqué par linter
CI". The `no-state-management-alternatives` (NSMA) linter rule that enforces
this is **already implemented** (`constitution-linter.sh:665-731`) — but it
runs **WARN-only**, because `state-management.yaml::enforcement.ci_blocking`
is `false`:

```yaml
# .forge/standards/state-management.yaml (live, L10-14)
linter_rule: no-state-management-alternatives
enforcement:
  ci_blocking: false              # Q-001 Option A — warn-only at v0.4.0-rc.1
  pre_commit_hook: false
  activation_planned: "B.8 (T6)"  # planned warn → error transition
```

The warn→error transition was deliberately deferred to "B.8 (T6)" at
v0.4.0-rc.1. **B.8.11 is that scheduled activation**: flip the rule from
WARN to a CI-blocking FAIL.

### GROUND-TRUTH FINDINGS (Article III.4)

**Ground truth (re-read 2026-06-03):**

- **The rule already exists and runs — no new bash needed.**
  `constitution-linter.sh:665-731` parses the `forbidden:` list + reads
  `ci_blocking`, scans adopter `pubspec.yaml` files, and branches
  `fail` vs `warn` at L715-719 keyed entirely on the `ci_blocking:` flag.
  B.8.11 is a **data flip** in `state-management.yaml`
  (`ci_blocking: false → true`), not a code change. The bash already
  honours the flag.
- **The flip enforces an EXISTING constitutional SHALL.** Article VI.3
  ("State management SHALL use `flutter_bloc` exclusively … No other …
  permitted without explicit constitutional amendment") + ADR-006 +
  the ARCHITECTURE-TARGET.md `state-management.yaml` spec block (which
  prescribes `ci_blocking: true`) already mandate the blocking gate. The
  WARN-only state was an explicitly-temporary `activation_planned: "B.8
  (T6)"` deferral. So this is the **planned activation of a
  ratified-blocking rule**, NOT a net-new rule.
- **F.4 §1 amendment tension — flagged for the reviewer (Q-001).**
  `global/linting-rules.md` §"Adding a new rule" (L173-190) says a rule
  "MUST NOT be tightened … without … Constitution amendment + F.x change +
  backward-compat audit + update of this standard." A warn→fail flip is
  literally a tightening. **However**, the Constitution already mandates
  blocking (VI.3 SHALL + ADR-006), the rule was ratified with
  `ci_blocking: true` as its target, and the deferral was a temporary
  Q-001 Option A — so the §1 "Constitution amendment" precondition is
  arguably already satisfied (no new amendment), and B.8.11 is the F.x
  change executing §2-4. This adjudication is reserved for the independent
  reviewer (Q-001) — surfaced, not papered over.
- **Backward-compat (F.4 §3) holds by construction.** The NSMA scan
  `find`s `pubspec.yaml` excluding `/.forge/` + `/examples/` +
  `/.dart_tool/` — so it never scans template `.tmpl` files. The flagship
  `frontend/` ships NO `pubspec.yaml.tmpl` (flat skeleton); `mobile-only`
  `pubspec.yaml.tmpl` pins only `flutter_bloc ^8.1.6` (clean, and under
  `.forge/` so excluded anyway). The live tree must stay GREEN post-flip —
  verified at implement (no scannable forbidden dep exists).
- **No pre-commit runner ships.** The only hook spec is G.2's commit-msg
  scope hook (`git-workflow.md` — a different concern, not dependency
  linting); no `pre-commit`/`hooks/` artifact exists repo-wide. Flipping
  `pre_commit_hook: true` would be a flag without a runner → a hallucinated
  gate. Decision reserved (Q-002): lean keep `pre_commit_hook: false`
  with a documented "runner is G.2 territory" note, flip only `ci_blocking`.
- **J.7 validator coupling.** `bin/validate-standards-yaml.sh` FR-J7-023:
  a bumped `version` MUST appear as a REVIEW.md table row. So bumping
  `state-management.yaml` forces a REVIEW.md row. The structural-exception
  pair (`expires_at: never` ⇔ `exception_constitutional: true`,
  FR-J7-020 bidirectional) MUST stay intact across the bump.
- **I.3 interlock preserved.** The I.3 generic forbidden walk hard-excludes
  `state-management.yaml` (`EXCLUDE_STANDARDS`, NFR-I3-T3F-001) so NSMA and
  T3-Forbidden never double-fire — B.8.11 must NOT disturb that exclusion.

## Solution

When built, the B.8.11 brick MUST:

1. Flip `state-management.yaml` `enforcement.ci_blocking: false → true`
   and resolve `activation_planned` (mark the activation done / remove the
   now-satisfied planned marker, keeping an audit trail comment citing
   B.8.11).
2. Bump `state-management.yaml` `version: 1.0.0 → 1.1.0` with an in-file
   version-history comment (mirror b8-7 identity.yaml style); keep
   `expires_at: never` + `exception_constitutional: true` pair intact
   (structural exception); add a REVIEW.md `Updated` ledger row (J.7
   FR-J7-023 coupling) → `bin/validate-standards-yaml.sh` PASS.
3. Decide `pre_commit_hook` (Q-002): lean keep `false` + a documented note
   that the pre-commit runner is G.2 territory (no runner ships); flip
   only the CI gate that actually works today.
4. Append a NSMA rule section + the `FORGE_LINTER_SKIP_NSMA` opt-out row to
   `global/linting-rules.md` (F.4 §4 "update this standard"); record the
   warn→fail activation + backward-compat note.
5. Backward-compat audit (F.4 §3): assert the live tree linter stays
   OVERALL PASS post-flip (no scannable forbidden dep) — captured as a
   harness assertion + an evidence note.
6. Ship harness `.forge/scripts/tests/b8-11.test.sh` (~10-12 L1 hermetic
   + L2 opt-in, mirror i3.test.sh): L1 asserts `state-management.yaml`
   `ci_blocking: true` + `version: 1.1.0` + REVIEW.md row + linting-rules.md
   NSMA section/opt-out row + CHANGELOG anchored `b8-11-nsma-linter` +
   forge-ci registration + b8-3/i3 coupling guard; **L2 fixture**
   (`FORGE_LINTER_FIXTURE_ROOT`): a `pubspec.yaml` with a forbidden pkg
   (e.g. `riverpod`) → the NSMA section now emits **FAIL** (not WARN);
   a clean `flutter_bloc`-only pubspec → PASS.
7. Register `b8-11.test.sh` in `forge-ci.yml`; CHANGELOG `[Unreleased]`
   entry.
8. Run the full ~50-harness suite + gates before push; gates re-run
   POST-flip; independent review at design and pre-archive — **the
   reviewer adjudicates Q-001 (F.4 §1 amendment necessity)**.

Decisions reserved for `/forge:design` (ADRs), leanings stated:

- **ADR-B811-001 (Q-001) — F.4 §1 amendment necessity.** **Lean:** no new
  Constitution amendment — VI.3 + ADR-006 already mandate blocking; B.8.11
  is the scheduled activation (the F.x change executing F.4 §2-4), not a
  net-new rule. Independent reviewer ratifies.
- **ADR-B811-002 (Q-002) — pre_commit_hook.** **Lean:** keep `false`; the
  runner is G.2; document the intent. Do not claim a gate that has no
  runner.
- **ADR-B811-003 — version bump magnitude.** **Lean:** additive minor
  1.0.0 → 1.1.0 (enforcement activation, no `forbidden:`/`flutter:` change;
  structural-exception pair intact). REVIEW.md `KEEP-WITH-CHANGES` row.
- **ADR-B811-004 — activation_planned resolution.** **Lean:** replace the
  `activation_planned: "B.8 (T6)"` marker with an `activated_by: B.8.11`
  (or comment) audit trail rather than silently deleting it.

Release vehicle: **v0.4.0-rc.13**.

## Scope In

- `state-management.yaml` `ci_blocking: false → true` + version 1.0.0 →
  1.1.0 + `activation_planned` resolution + REVIEW.md ledger row.
- `global/linting-rules.md` NSMA section + `FORGE_LINTER_SKIP_NSMA` opt-out
  row.
- Harness `b8-11.test.sh` (L1 + L2 fixture asserting FAIL-on-forbidden) +
  forge-ci.yml + CHANGELOG.

## Scope Out (Explicit Exclusions)

- **New linter bash** — the NSMA rule already exists
  (`constitution-linter.sh:665-731`); B.8.11 flips its data flag, adds no
  new scan logic.
- **A working pre-commit hook runner** — G.2 territory; no runner ships
  (Q-002 lean: flag stays false).
- **The I.3 T3-Forbidden generic rule** — separate rule; its
  `state-management.yaml` exclusion stays untouched.
- **`forbidden:` / `flutter:` list changes** — the list is ADR-006-final;
  B.8.11 only flips enforcement.
- **Constitution amendment** — VI.3 already mandates the gate (Q-001 lean:
  no amendment); if the reviewer rules otherwise, B.8.11 stops and routes
  to the Article XII process.
- **Any 1.0.0 template / schema / snapshot mutation** — none touched.

## Impact

- **Users affected**: adopter projects that (against the Constitution)
  declared a forbidden state-mgmt dep now FAIL CI instead of WARN — the
  intended enforcement. Compliant projects (flutter_bloc only) see no
  change. Forge's own tree stays GREEN (no scannable forbidden dep).
- **Technical impact**: 1 standard flag flip + version bump, 1 governance-doc
  section, 1 REVIEW.md row, 1 new harness. No new bash, no production code,
  no template mutation.
- **Dependencies**: T.4 (state-management.yaml + ADR-006), F.4 (linter
  framework + linting-rules.md governance), I.3 (NSMA section + i3.test.sh
  harness pattern + the interlock exclusion).

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: proposal precedes specs.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: re-read confirmed the
  rule already exists (data flip, not new code); the F.4 §1 amendment
  tension is surfaced (Q-001) not papered over; the missing pre-commit
  runner is flagged (Q-002) rather than claiming a phantom gate;
  backward-compat is asserted, not assumed.
- **Article IV (Delta-based)**: standard bump additive + REVIEW.md ledger;
  linting-rules.md gets an appended section.
- **Article V (Compliance gate)**: harness + gates before flip; full suite
  before push; POST-flip re-run.
- **Article VI.3 (flutter_bloc SHALL — ENFORCED)**: B.8.11 activates the
  CI gate that makes VI.3 binding; this is the article being enforced, not
  violated.
- **Article XII (Governance)**: F.4 §1 adjudication (Q-001) determines
  whether the amendment process is invoked; lean is no (VI.3 already
  mandates blocking). Reviewer ratifies.

## Open Questions (seed)

- **Q-001** — F.4 §1: does the warn→fail flip require a fresh Article XII
  Constitution amendment, or is it the already-planned activation of a
  rule the Constitution (VI.3 + ADR-006) already mandates as blocking?
  (→ ADR-B811-001; open, lean no-amendment; **reviewer adjudicates**.)
- **Q-002** — pre_commit_hook: flip to `true` (declared contract, no runner
  yet) vs keep `false` (no phantom gate; runner is G.2) (→ ADR-B811-002;
  open, lean keep false).
- **Q-003** — version bump: 1.0.0 → 1.1.0 minor (enforcement activation) vs
  a larger bump; REVIEW.md decision verb (→ ADR-B811-003; open, lean 1.1.0
  KEEP-WITH-CHANGES).
- **Q-004** — `activation_planned` resolution: replace with `activated_by:
  B.8.11` audit field vs comment vs delete (→ ADR-B811-004; open, lean
  audit-trail field/comment, not silent delete).
