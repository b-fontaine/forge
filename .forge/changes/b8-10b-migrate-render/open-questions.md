# Open questions — `b8-10b-migrate-render`

## Q-001 — how is rendering performed, without a second render engine? (BLOCKING design)

NFR-B810B-001 forbids duplicating `overlay.sh`'s substitution semantics. Three ways
to honour it, with real trade-offs:

**(a) Render via `overlay.sh` into a temp dir, then merge from there.**
The migrate script would call `overlay.sh --plan <migration-plan> --target <tmp>
--project-name … --reverse-domain …`, then point the existing `_a7_*` merge at that
rendered tree as RIGHT. One renderer, guaranteed identical to fresh-init.
*Cost:* the 36 files need a plan, and 23 of them are in **no** plan today — so this
requires authoring a migration plan listing all 36, which is new surface to maintain
alongside `scaffold-plan-2.0.0.yaml`.

**(b) Extract the substitution into a shared helper, sourced by both.**
`overlay.sh` does its substitution in embedded Python. Lifting it into a sourced
helper both scripts use keeps one implementation without needing a plan.
*Cost:* touches `overlay.sh`, which `b9-2.test.sh::T-010` asserts is byte-unchanged
and which every archetype wrapper depends on. Highest blast radius of the three.

**(c) Do the substitution in the migrate script, accepting a second implementation.**
Smallest diff; violates NFR-B810B-001 as written.
*Cost:* two renderers that must agree forever, with nothing enforcing it. This is the
option that looks cheapest today and is the one most likely to produce a subtle
divergence later.

**Lean: (a).** It is the only option where "renders exactly like fresh-init" is true
by construction rather than by discipline, and it matches `ADR-B810-001`'s own
reasoning for the merge engine. The plan it requires is also the artefact Q-002
would need, so the cost is partly shared rather than sunk.

**This needs the maintainer**, because (a) creates a durable new artefact and (b)
touches a byte-frozen shared script.

## Q-002 — should the 23 plan-less files be wired into fresh-init too? (OUT, adjacent)

23 of the 36 files in the `2.0.0/` tree (`frontend/web-public` 10, `infra/zitadel` 4,
`infra/postgres` 3, `backend/crates` 4, `shared/protos` 2) are referenced by no
scaffold plan. That is deliberate — `scaffold-plan-2.0.0.yaml`'s header records
pgvector (B.8.5), Zitadel (B.8.7) and Qwik web-public (B.8.9) as "additive overlays …
wiring them into fresh-init is out of this brick's scope".

Consequence, which is the part worth deciding: a *fresh* `forge init` produces a
project **without** the Qwik surface, Zitadel or pgvector, while a *migrated* project
gets all three. Two adopters on 2.0.0 therefore hold materially different trees
depending on how they arrived.

Out of scope here — this brick fixes what migration delivers, not who receives it.
But if Q-001 resolves to (a), the migration plan authored there is most of the input
a fresh-init decision would need.

## Q-003 — what level does the output test run at?

FR-B810B-005 needs a **real** migration, which needs a rendered 1.0.0 project, which
needs `flutter` and `cargo`. Options: L2 opt-in behind a env gate (consistent with
`_test_b810_l2_001`), or an L1 test against a **synthetic** minimal target — a
hand-built directory with a `.forge/scaffold-manifest.yaml` and a couple of files,
no toolchain required.

**Lean: both.** An L1 synthetic test runs everywhere and would have caught this
defect; an L2 real-render test proves the synthetic fixture is faithful. An L2-only
test repeats the mistake that let this through — `b8-10`'s only live test is gated
and, in CI, the `cli` job installs neither flutter nor buf, so toolchain-gated legs
do not run there.

## Q-004 — what do already-migrated adopters do?

Anyone who has already run the migration has 36 stray `.tmpl` files, 9 of them
shadowing real files. Nothing in the repo tells them to delete those.

The fix cannot clean up retroactively — the script is additive by contract and
deleting adopter files is out of the question. So this needs a documented manual
step. Whether that is a `docs/MIGRATIONS.md` note, a CHANGELOG paragraph, or a
`--doctor` flag that lists the strays without removing them, is undecided.
