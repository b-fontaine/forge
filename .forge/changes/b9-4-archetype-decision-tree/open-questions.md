# Open questions — `b9-4-archetype-decision-tree`

## Q-001 — `forbidden_archetypes` is dead code, and two documents advertise it

`cli/src/domain/dispatch-table.ts:115` returns `{ archetypes }`. It never reads the
`forbidden_archetypes:` block, so `cli/src/commands/init-archetype.ts:159-171` —
J.8's refusal path, `FR-J8-020` / `ADR-J8-003` — can never fire from the CLI front
door. Measured: `forge init --archetype flutter-firebase` exits **127** with
`bash: cli/assets/<removed>: no such file or directory`.

Two documents state otherwise: `docs/ARCHETYPES.md:103` (the `J8-RULE-001` row of the
"Forbidden combinations" table) and J.8's own spec. The `flutter-firebase` row now
carries the measurement, but **the J8 table itself is left untouched** — it is J.8's
contract, and rewriting another module's documented refusal semantics from inside a
B.9 doc brick is how a decision gets made without its owner.

Two candidate fixes, and they are not equivalent:
- make `parseDispatchTable` return `forbidden_archetypes` — restores the documented
  exit-3 refusal, and is probably what everyone assumed was happening;
- drop the block and the doc rows — accepts that the archetype simply has no
  scaffolder.

The first is almost certainly right, but it is a behavioural change to the CLI's exit
codes with a Trust-Harness snapshot consequence. It needs a brick.

## Q-002 — the iOS constraint is sourced to one blog post

The whole `iOS + push critical → native` route rests on
`ARCHITECTURE-TARGET.md:142` — a single external URL, accessed 2026-04 — and nothing
else. No standard, schema, ADR, spec, test or template states an iOS version floor, a
home-screen-install precondition, or a named Push API limitation.

The section now says so plainly rather than inventing a technical basis. What would
make the rule more than a safe default:

- a stated **iOS floor** (Safari 16.4 is where installed-PWA Web Push arrived), so an
  adopter can check it against their own support matrix;
- the **home-screen-install precondition**, which is the real constraint — a PWA opened
  in Safari, not installed, gets no push at all;
- the capabilities that remain absent regardless of version (no silent push, no
  Background Sync), which are what actually decide "is push critical for us".

That is a `pwa.yaml` amendment with a `last_reviewed` bump, not a doc edit. Until then
`ARCHITECTURE-TARGET` is frozen (T.4 sha256 pin) so the citation cannot move either.

## Q-003 — `backend/crates/grpc-api` is not migration-only

`docs/ARCHETYPES.md`'s "Two surfaces are still migration-only" table claims
`backend/crates/grpc-api` Connect-RPC + JWT middleware is absent from a fresh project.
Measured: `scaffold-plan-2.0.0.yaml:87-102` renders `Cargo.toml`, `build.rs`,
`src/lib.rs` **and** `src/transport_connect.rs`, and the rendered `Cargo.toml` pins
`connectrpc = { version = "=0.3.3", features = ["axum"] }`.

So a fresh 2.0.0 project *does* get the crate and a Connect transport. What is
migration-only is the **2.0.0 variant** — `connectrpc 0.6.1` plus `jwt_middleware.rs`.

Not fixed here: that row belongs to the flagship section, it is B.8 territory, and the
correct replacement has to distinguish two variants of the same crate rather than flip
a yes to a no. `t6-fsm-2-0-0-wiring` Q-001 already tracks the JWT middleware half.

## Q-004 — `b4.test.sh`'s ARCHETYPES guard is still a whole-file grep

`b4.test.sh:586-589` is `grep -qF 'mobile-only' "$ARCHETYPES_MD"` — unbackticked, and
matched anywhere in the file including the new decision-tree section. It survives every
probe for the wrong reason.

Left as is: `b5.test.sh` now enforces the same row properly through the derived set, so
`b4`'s check is redundant rather than wrong, and tightening a B.4 harness from a B.9
brick buys nothing. Worth folding into the next B.4-adjacent change.
