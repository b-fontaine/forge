# Specs — `b9-11-promotion-gate`

**Namespace** : `FR-B911-*`, `NFR-B911-*`, `ADR-B911-*`.

---

## Functional Requirements

### FR-B911-001 — the promotion gate exists

`.forge/scripts/tests/b9.test.sh`, a promotion-gate suite of **≥ 25 L1 tests** plus L2
fixture cells, registered in `.github/workflows/forge-ci.yml`. It asserts the
**promoted** state of `mobile-pwa-first / 2.0.0` across every surface the flip touches,
so a later regression on any one of them is caught by the harness that owns the
promotion rather than by a distant sibling.

### FR-B911-002 — the schema is promoted

`.forge/schemas/mobile-pwa-first/2.0.0.yaml`: `stage: candidate` → `stable`,
`scaffoldable: false` → `true`. The header block that documents candidate semantics and
names B.9.11 as the promoter MUST be rewritten to record the promotion, not left
describing a state that no longer holds.

### FR-B911-003 — the dispatch status is flipped in the same change

`.forge/scaffolding/dispatch-table.yml`: `status: candidate` → `stable`.

Not optional and not deferrable. `cli/test/e2e/archetypes-smoke.test.ts` partitions off
that field — `scaffoldable = status !== "candidate"`, `candidates = status ===
"candidate"` — and the second partition asserts an exit-3 refusal the promoted schema
no longer produces. **There is no green state that keeps `status: candidate`**
(`d21dda1`, the `b7-6` cascade commit).

### FR-B911-004 — the CLI trust fixture

**NEW** `cli/test/e2e/archetype-fixtures/mobile-pwa-first.yml`, required by
`FR-T51-055` for every archetype the dispatch table reports as scaffoldable. Modelled
on `mobile-only.yml` and extended with the `web-pwa/` surface, since a migrated tree is
byte-identical to a native render of this archetype (`b9-9`).

### FR-B911-005 — every held guard is inverted, never deleted

| harness | test | becomes |
|---|---|---|
| `b9-1` | T-003 `stage == candidate` | `stage == stable`, `scaffoldable == true` |
| `b9-1` | T-006 header documents candidate semantics | header documents the promotion |
| `b9-2` | T-011 wrapper refuses exit 3 | wrapper scaffolds, no `FORGE_MPF_FORCE_SCAFFOLD` needed |
| `b9-2` | T-022 schema still candidate | schema promoted |
| `b9-2` | T-L2-001 `forge init` exits 3 | `forge init` renders |
| `b9-3` | T-023 schema **and** dispatch still candidate | both promoted |

Deleting a guard because it now fails would lose the assertion entirely. Inverting it
keeps the property under test and moves which side of it is correct — the `b7-6`
precedent (`149919a`, *"invert b7-7-example's candidate held-guards post-promotion"*).

### FR-B911-006 — the two planted tripwires are discharged

- `docs/ARCHETYPES.md` gains the `mobile-pwa-first` row. `b5.test.sh`'s FR-IW-009
  guard, rewritten by `b9-4` to derive from `dispatch-table.yml` excluding candidates,
  demands it the moment `FR-B911-003` lands.
- `docs/MIGRATION-PATHS.md`'s Status paragraph stops saying the schema is `candidate`
  and `forge init` exits 3. `T-028`'s needle battery in `b9-2.test.sh` pins the old
  wording, so its `candidate` / `B.9.11` / `exit 3` rows MUST be updated in the same
  change and the anti-vacuity count adjusted (`b9-10` Q-003).

### FR-B911-007 — the wrapper is not edited

`bin/forge-init-mobile-pwa-first.sh` reads `stage` and `scaffoldable` from the schema.
The flip makes it scaffold with no source change; `FORGE_MPF_FORCE_SCAFFOLD` becomes
inert. A test MUST prove the wrapper now scaffolds **without** the override.

### FR-B911-008 — CI registration inside the line budget

One entry in `forge-ci.yml`'s `harnesses=(...)` array. The file is 419 lines against
the 420 cap of NFR-CI-002 (asserted in `c1.test.sh:746`, `t5-1.test.sh:406`,
`b6-8.test.sh:73`), so the registration lands at exactly **420/420** and no budget bump
is required.

### FR-B911-009 — CHANGELOG and resync

`[Unreleased]` entry; plan §0.14 / §5.2 / §11 and `.forge/product/roadmap.md` — B.9
**11/11, COMPLETE**.

---

## Non-Functional Requirements

### NFR-B911-001 — the flip is atomic

Schema, dispatch status, fixture and every inverted guard land in one commit. No
intermediate state is green, so none may be pushed.

### NFR-B911-002 — CI is reproduced faithfully, `cli` included

The regression MUST run the full 80-entry harness matrix **and** `cd cli && npm test`.
The `b7-6` promotion shipped red because a shell-only repro missed the Vitest job; that
is the single most expensive mistake available in this brick and it is already
documented.

### NFR-B911-003 — no content change

Zero edits under `.forge/templates/`, `.forge/scaffold-snapshots/`,
`.forge/scaffolding/*.yaml` other than the dispatch status, and no `bin/` source
change. The archetype's content was finished by B.9.5; this brick promotes it.

### NFR-B911-004 — guards mutation-proven

Every new assertion in `b9.test.sh` MUST be shown to fail when the property it names is
broken. Needles anchored to the claim and unique in their region — the lesson four
bricks in this series have now each paid for.

---

## ADRs

### ADR-B911-001 — invert held guards, never delete them

**Context.** Six sibling tests assert a state the promotion inverts. The cheapest path
is deleting them.

**Decision.** Each is rewritten to assert the promoted state.

**Rationale.** The property under test — "the schema's stage and the dispatch status
agree, and the wrapper behaves accordingly" — is exactly as worth protecting after the
flip as before. Deleting converts a caught regression into a silent one. `b7-6` took
the same decision for `b7-7`'s held guards.

**Consequence.** `b9-1`, `b9-2` and `b9-3` keep their test counts and change their
meaning. A future demotion would turn them red, which is correct.

### ADR-B911-002 — `b9.test.sh` asserts the promoted state, not the promotion event

**Context.** A gate harness could assert "the flip happened" (diffing against a
recorded prior state) or "the promoted state holds".

**Decision.** The latter.

**Rationale.** A harness that asserts an event is green exactly once and meaningless
afterwards. One that asserts the state is a standing invariant: it catches a
half-reverted schema, a dispatch status that drifts back, a fixture deleted in a
cleanup, a matrix row lost to a doc edit.

**Consequence.** `b9.test.sh` overlaps `b9-1`/`b9-2`/`b9-3` on a few properties. That
is deliberate: those harnesses own their own brick's deliverables, this one owns the
coherence of the promoted whole, and the overlap is what makes either of them
individually removable without losing the invariant.
