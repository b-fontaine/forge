# Design: t5-cargo-pin-refresh
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (docs/new-archetypes-plan.md §0.1 extension — Option B) -->

> Read alongside `specs.md` (FR-T5CPR-* / NFR-T5CPR-*) and
> `open-questions.md` (Q-001 / Q-002 / Q-003). This document locks
> the implementation strategy and resolves Q-001..Q-003 via
> ADR-T5CPR-001..003.

## Architecture Decisions

### ADR-T5CPR-001 — Pin `buffa = "=0.3.0"` (minimum edit) ; do NOT bump to 0.4+ (resolves Q-001)

**Context** : Q-001 weighed three pin strategies for the corrected
`buffa` / `buffa-types` declarations :

- **Option A** — Pin `buffa = "=0.3.0"` (the only resolvable
  version of the 0.3 series).
- **Option B** — Modernise the whole stack : bump
  `connectrpc = "=0.4.2"` + `buffa = "=0.6.0"` (or matching latest).
- **Option C** — Relax to `buffa = "^0.3"` (let Cargo pick).

**Decision** : **Option A — `buffa = "=0.3.0"`**.

**Rationale** :

1. **Minimum-edit principle** : the proposal is chartered to fix
   a dead pin, not to modernise the Connect stack. Bumping
   `connectrpc` from 0.3.3 to 0.4.x is a separate decision with
   its own risk surface (API churn between 0.3 and 0.4 series).
   That decision belongs to **B.8 (T6)** where the entire Connect
   story is re-evaluated alongside Kong → Envoy migration.
2. **Constraint satisfaction** : `connectrpc 0.3.3` declares
   `buffa = "^0.3"` (caret) in its dependency manifest (verified
   via the crates.io API 2026-05-16). `=0.3.0` is the only
   resolvable version that satisfies this constraint exactly — by
   construction, the published `buffa` versions skip from 0.3.0
   directly to 0.4.0.
3. **Preserve ADR-T5-002 intent** : the original
   `t5-connect-codegen` ADR-T5-002 chose `=` (exact) pins over
   `^` (caret) pins to enforce reproducible builds + manual
   upgrade decisions. That intent is preserved by `=0.3.0`. Option
   C (`^0.3`) would relax it gratuitously.
4. **Lower risk** : Option A changes 2 lines in templates +
   2 lines in `transport.yaml` ; Option B would touch the entire
   `connectrpc` family (4 pins) + cascade through Cargo lock files
   + likely require code changes in templates (build.rs, etc.)
   wherever the connectrpc 0.4.x API differs from 0.3.x.

**Consequences** :

- ✅ The minimum surgical fix lands in T5.1 timeframe.
- ✅ `transport.yaml` v1.1.0 → v1.2.0 stays additive (no
  `breaking_change: true`).
- ✅ Adopters who haven't yet scaffolded see the fix immediately.
- ⚠️ The `connectrpc` family at 0.3.x is now pinned for longer than
  initially planned. Acceptable — B.8 (T6) will re-evaluate.

**Constitution Compliance** : Article III.4 (anti-hallucination
— the decision is verified against crates.io REST API, not
guessed) ; Article XII (governance — the bump uses the canonical
re-revue procedure).

---

### ADR-T5CPR-002 — `transport.yaml` v1.1.0 → v1.2.0 (additive correction) (resolves Q-002)

**Context** : Q-002 weighed three bump strategies for
`transport.yaml` after correcting the pins :

- **Option A** — Bump v1.1.0 → v1.2.0 (additive minor correction).
- **Option B** — Edit in place without bumping (keep version at
  1.1.0).
- **Option C** — Bump v1.1.0 → v2.0.0 (breaking : declare the
  pin change a contractual break).

**Decision** : **Option A — `v1.2.0`**.

**Rationale** :

1. **Standards-lifecycle invariant** : `global/standards-lifecycle.md`
   v1.0.0 mandates that **every observable change** to a published
   standard receives a version bump. Editing in place (Option B)
   would violate the published-contract semantics and break the
   ledger trail.
2. **Not a breaking change** : adopters who had `=0.3.3` in their
   tree had a **non-resolvable** Cargo manifest — they could not
   have built successfully. Correcting `=0.3.3` to `=0.3.0`
   restores resolvability ; it does not break a previously-working
   resolution. The semantic distance to adopters is "build was
   broken, is now fixed" — which is corrective, not breaking. By
   convention, that is a SemVer **minor** (additive) bump, not a
   **major** bump.
3. **Future-proof** : keeping v1.2.0 (vs v2.0.0) leaves room for
   the eventual `connectrpc 0.4.x` modernisation (Option B of
   ADR-T5CPR-001 deferred to B.8) to use the next minor or major.

**Consequences** :

- ✅ Standards re-revue trail preserved (REVIEW.md ledger gains an
  Updated entry).
- ✅ Standards YAML validator (`bin/validate-standards-yaml.sh`,
  J.7) continues to PASS — the additive nature respects the
  frontmatter contract.
- ✅ `breaking_change: true` is NOT set ; downstream automation
  doesn't trigger spurious breaking-change pipelines.

**Constitution Compliance** : Article XII (governance — bump
follows the canonical re-revue procedure exactly).

---

### ADR-T5CPR-003 — Rewrite the WAIVER comment block (resolves Q-003)

**Context** : `transport.yaml` lines 55-63 (the multi-line
`# WAIVER 2026-05-05 : …` comment block) justify the original
`=0.3.3` pin for the entire `connectrpc` family with three
pedigree-style arguments :

> (1) ConnectRPC conformance suite (6 558 tests) passing satisfies
>     the regression-filter intent of the 30-day rule.
> (2) Anthropic OSS pedigree (`anthropics/connect-rust`).
> (3) Exact `=0.3.3` pin keeps upgrades manual.

The first two arguments are still valid for `connectrpc` and
`connectrpc-build` (still pinned at `=0.3.3` after this change).
The third argument is **not** what allowed `buffa = "=0.3.3"` to
land — that pin was an error of fact, not a pedigree-justified
exception.

Q-003 weighed two phrasings for the post-fix comment :

- **Option A** — Append the 2026-05-16 amendment correction note
  to the existing block (additive).
- **Option B** — Rewrite the block entirely, separating the
  `connectrpc` family (still WAIVER) from the `buffa` family
  (NOT a WAIVER ; an error correction).

**Decision** : **Option B — full rewrite, separated phrasings**.

**Rationale** :

- Conflating "pedigree-justified WAIVER" with "correction of an
  unpublished-version error" muddles the audit trail. Future
  re-reviewers seeing a single block must be able to distinguish
  "we accepted a young package on pedigree grounds" from "we
  pinned a version that didn't exist and corrected it".
- The pedigree justification continues to hold for `connectrpc`
  and `connectrpc-build` (both at `=0.3.3`, both real versions,
  both subject to the 30-day rule WAIVER).
- The `buffa` / `buffa-types` pins at `=0.3.0` are **not** a
  WAIVER — `=0.3.0` is the canonical resolvable version of the
  series that `connectrpc 0.3.3` requires. No 30-day exception
  applies.

**Replacement comment block** (drafted, final wording at
implementation time) :

```yaml
  versions:
    # WAIVER 2026-05-05 (preserved) : connectrpc / connectrpc-build
    # pinned at =0.3.3 (13-day crate age vs 30-day rule of
    # ADR-T5-002 in design.md of t5-connect-codegen). Justification :
    #   (1) ConnectRPC conformance suite (6 558 tests) passing.
    #   (2) Anthropic OSS pedigree (`anthropics/connect-rust`).
    #   (3) Exact `=0.3.3` pin keeps upgrades manual.
    # Pre-1.0 — monitor upstream releases ; B.8 (T6) re-evaluates.
    #
    # Amend 2026-05-16 (t5-cargo-pin-refresh, T5.1.E) :
    # buffa / buffa-types were pinned `=0.3.3` by t5-connect-codegen
    # but those versions were never published on crates.io
    # (series 0.3.x stops at 0.3.0). connectrpc 0.3.3 declares
    # `buffa = "^0.3"` — `=0.3.0` is the unique resolvable exact
    # pin satisfying that constraint. Correction is NOT a WAIVER ;
    # it is an error-of-fact fix. ADR-T5CPR-003 (this change).
```

**Consequences** :

- ✅ Audit trail distinguishes WAIVER from CORRECTION cleanly.
- ✅ Future re-reviewers in B.8 see exactly which pins they need
  to revisit (the `=0.3.3` WAIVER block is unchanged in spirit ;
  the `=0.3.0` correction is documented separately).
- ✅ The amendment is dated and references this change — Article V
  audit-trail compliance.

**Constitution Compliance** : Article V (audit trail — the
correction is dated and signed by change ID) ; Article XII
(governance — the WAIVER policy itself is unchanged).

---

## Technical Design

### Edit summary by file

```
.forge/
├── standards/
│   ├── transport.yaml                    # bump 1.1.0 → 1.2.0 ; pins ; WAIVER rewrite
│   └── REVIEW.md                         # Updated entry append
├── templates/
│   └── archetypes/
│       └── full-stack-monorepo/
│           └── backend/
│               └── crates/
│                   └── grpc-api/
│                       └── Cargo.toml.tmpl    # lines 27-28
├── scaffold-snapshots/
│   └── full-stack-monorepo/
│       └── 1.0.0.tar.gz                  # regenerate after template fix
└── scripts/
    └── tests/
        └── t5-cargo.test.sh              # NEW harness ≥ 8 L1 + 1 L2

cli/assets/.forge/                        # mirrors via npm run bundle
├── standards/transport.yaml              # mirror (auto-bundled)
├── templates/.../Cargo.toml.tmpl         # mirror (auto-bundled)
└── scaffold-snapshots/.../1.0.0.tar.gz   # mirror (auto-bundled)

.github/workflows/forge-ci.yml             # +1 step for t5-cargo.test.sh
CHANGELOG.md                                # [Unreleased] section append
docs/new-archetypes-plan.md                 # §0.1 + §1.4 + §11 + inventory
.forge/product/roadmap.md                   # T5.1 row flip + inventory
```

### Harness L1 anchor list (FR-T5CPR-073)

| ID                                              | Assertion mechanism                                                  |
|-------------------------------------------------|----------------------------------------------------------------------|
| `_test_t5c_l1_001_source_template`              | `grep -F 'buffa = "=0.3.0"' $TEMPLATE && grep -F 'buffa-types = "=0.3.0"' $TEMPLATE` |
| `_test_t5c_l1_002_source_no_dead_pin`           | `! grep -F 'buffa = "=0.3.3"' $TEMPLATE && ! grep -F 'buffa-types = "=0.3.3"' $TEMPLATE` |
| `_test_t5c_l1_003_mirror_template`              | `diff -q $TEMPLATE $MIRROR` exit 0                                   |
| `_test_t5c_l1_004_standard_version`             | `grep -E '^version: "1\.2\.0"' transport.yaml`                       |
| `_test_t5c_l1_005_standard_pins`                | `grep -F 'buffa: "=0.3.0"' transport.yaml && grep -F 'buffa-types: "=0.3.0"' transport.yaml` |
| `_test_t5c_l1_006_standard_waiver_rewritten`    | `grep -F 'Amend 2026-05-16 (t5-cargo-pin-refresh' transport.yaml`     |
| `_test_t5c_l1_007_review_ledger`                | `grep -F 't5-cargo-pin-refresh' REVIEW.md && grep -F '1.1.0 → 1.2.0' REVIEW.md` |
| `_test_t5c_l1_008_snapshot_content`             | `tar -xzOf $SNAPSHOT '*Cargo.toml.tmpl' \| grep -F 'buffa = "=0.3.0"'` |
| `_test_t5c_l1_009_snapshot_mirror_identity`     | `shasum -a 256 $SNAPSHOT $SNAPSHOT_MIRROR \| awk '{print $1}' \| uniq \| wc -l` equals 1 |
| `_test_t5c_l1_010_changelog_entry`              | `awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} f' CHANGELOG.md \| grep -F 't5-cargo-pin-refresh'` |

10 anchors — meets the ≥ 8 floor.

### L2 fixture (FR-T5CPR-074)

```bash
_test_t5c_l2_resolve_against_crates_io() {
  if [ "${FORGE_T5C_LIVE:-0}" != "1" ]; then
    echo "    skipped (FORGE_T5C_LIVE unset)" >&2; return 0
  fi
  # Three assertions :
  #   1. buffa 0.3.0 exists, non-yanked.
  #   2. buffa-types 0.3.0 exists, non-yanked.
  #   3. connectrpc 0.3.3 declares `buffa = "^0.3"`.
  # All via crates.io REST API + python3 -c json.load(sys.stdin).
  # Uses curl with a User-Agent header (crates.io requires it).
}
```

### CI matrix entry

```yaml
- name: t5-cargo.test.sh
  # T5.1.E Cargo pin refresh harness. L1-only by default ; L2
  # (live crates.io resolution check) is opt-in via FORGE_T5C_LIVE=1.
  run: bash .forge/scripts/tests/t5-cargo.test.sh --level 1
```

Inserted immediately after `t5-1.test.sh`. Workflow grows by ~5
lines → 297 lines total, still ≤ 300 (NFR-CI-002 / NFR-T5CPR-003).

---

## Snapshot regeneration mechanism

The snapshot tarball `full-stack-monorepo/1.0.0.tar.gz` is
produced by packaging the **post-fix** template tree. Mechanism :

1. After edits to `.forge/templates/.../Cargo.toml.tmpl` land
   (Phase 2 of `tasks.md`).
2. `tar -czf .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
    -C .forge/templates/archetypes/full-stack-monorepo .` (or use
   the existing snapshot helper script if one exists at
   `bin/forge-snapshot.sh`).
3. `cd cli && npm run bundle` to refresh `cli/assets/...` mirrors
   (the bundle copies the entire `.forge/` tree under
   `cli/assets/.forge/`).
4. Verify byte-identity : `diff -q .forge/scaffold-snapshots/.../1.0.0.tar.gz
    cli/assets/.forge/scaffold-snapshots/.../1.0.0.tar.gz`.

If a helper script exists at `bin/forge-snapshot.sh` (b1-scaffolder
or A.7 may have shipped one), prefer it for determinism. Phase 3 of
`tasks.md` investigates and uses whichever is shipped.

---

## Migration / rollout

- **Pre-fix adopters** : their existing scaffolds have a
  non-resolvable Cargo manifest. They get the fix by running
  `forge upgrade --target .` in their adopter tree, which 3-way
  merges the corrected template via A.7.
- **Fresh adopters** : their `forge init …` after this change lands
  produces a buildable scaffold.
- **Maintainer** : after merge of this change + `cli-trust-harness`,
  bump VERSION 0.3.2 → 0.3.3 + seal CHANGELOG `[Unreleased]` →
  `## [0.3.3] — 2026-05-XX` + run `scripts/release.sh --version
  0.3.3 --otp <…>`. The `prepublishOnly` gate (T5.1.C) will
  exercise the smoke on the very tarball being published.

---

## Risks + mitigations

| Risk                                                              | Probability | Impact | Mitigation                                                                            |
|-------------------------------------------------------------------|-------------|--------|---------------------------------------------------------------------------------------|
| `=0.3.0` itself gets yanked later                                 | Very low    | Medium | L2 opt-in `FORGE_T5C_LIVE=1` queries crates.io ; CI cron could enable it periodically |
| `connectrpc 0.3.3` itself gets yanked                              | Low         | Medium | Same — L2 opt-in detects                                                              |
| Snapshot regeneration breaks A.7 `forge upgrade` BASE recovery    | Low         | High   | Run `a7.test.sh --level 1,2` post-regen ; existing 29/29 GREEN must hold              |
| `cargo check` still fails on fresh scaffold for some other reason | Low         | Medium | `task smoke-with-toolchains` is the regression filter — must GREEN before archive     |

---

## ADR summary table

| ADR ID         | Question                                       | Decision                                                                              |
|----------------|------------------------------------------------|---------------------------------------------------------------------------------------|
| ADR-T5CPR-001  | Q-001 — pin target for buffa / buffa-types     | `=0.3.0` (minimum edit) ; do NOT modernise to 0.4+ in this change                     |
| ADR-T5CPR-002  | Q-002 — transport.yaml version bump strategy    | v1.1.0 → v1.2.0 (additive correction, not breaking)                                   |
| ADR-T5CPR-003  | Q-003 — WAIVER comment block re-phrasing       | Full rewrite separating WAIVER (connectrpc family) from CORRECTION (buffa family)     |
