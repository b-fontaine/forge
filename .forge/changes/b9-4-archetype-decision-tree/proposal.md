# Proposal — `b9-4-archetype-decision-tree`

Document the PWA-vs-native channel decision in `docs/ARCHETYPES.md`, and repair the
rows of that matrix which send a reader to an archetype they cannot use.

## The rule this brick must write down has no technical basis in the repo

The plan states it in one line: *« si plateforme `Web|Android` → PWA Qwik ; si
plateforme `iOS` ET push critique → fallback Flutter natif iOS »*.

Looking for what establishes it: `pwa.yaml::channel_fallback` restates the routing
rule and cites `ARCHITECTURE-TARGET §6.3`; §6.3's C4 diagram conditions the native
container on *« Si push critique sur iOS »*; the schema's `channel-decision` phase
(`ADR-B9-1-003`) forces the choice to be recorded per change. Every one of those
states the **routing consequence**. None states the **platform constraint** it rests
on — no iOS version floor, no home-screen-install precondition, no named Web Push
limitation. The sole source is one external blog URL in a taxonomy verdict table
(`ARCHITECTURE-TARGET.md:142`, accessed 2026-04).

That matters for how the section is written. A decision tree that asserts *"iOS cannot
do Web Push"* would be inventing a technical claim the repository never made — and
one that has been wrong since Safari 16.4. The repo's own most careful sentence is
`pwa.yaml:74-77`: *"iOS support for installed-PWA push is **not assumed**"*. That is
an epistemic statement, not a capability claim, and the tree must inherit its
precision rather than flatten it.

**So: the tree documents a routing rule and says plainly what it is not.** The missing
technical basis is recorded as an open question, not filled in with plausible prose.

## The matrix sends readers to archetypes they cannot use

Auditing the seven rows against the registry, two misdirect the pick this document
exists to support:

**`flutter-firebase` — "Planned (B.2)"**, with a "When to pick" recommendation. It was
removed from the taxonomy on 2026-05-04 (`ADR-007`, Schrems II + CLOUD Act);
`dispatch-table.yml` carries `status: removed_from_roadmap` and
`scaffolder: "<removed>"`. The same document already contradicts the row 63 lines
later, listing `J8-RULE-001` as a live refusal.

Except that refusal **does not fire**. Measured: `parseDispatchTable` returns
`{ archetypes }` and never reads `forbidden_archetypes`, so the guard at
`init-archetype.ts:163` is unreachable. A real run exits **127** with
`bash: cli/assets/<removed>: no such file or directory`. So the row promises a future
archetype, the refusal table promises a clean policy refusal, and the adopter gets a
shell error.

**`mobile-only` — "Active"**, with no disclosure that it is `status: legacy_alias`,
`target: mobile-pwa-first`. "Active" is not false — it still scaffolds — but a decision
matrix whose job is "pick one before running `forge init`" owes the reader the rename.

## What this brick deliberately does not do

**It does not add a `mobile-pwa-first` row.** The archetype is `stage: candidate` /
`scaffoldable: false`; `forge init --archetype mobile-pwa-first` exits 3. No archetype
in this repository has ever held a matrix row while candidate — `ai-native-rag` and
`event-driven-eu` both got theirs after promotion. Advertising it as pickable would be
the same defect as `flutter-firebase`'s row, in the opposite direction. The row is
B.9.11's, in lockstep with the promotion flip; the guard below is written so that
B.9.11 **cannot** forget it.

**It does not fix the `forbidden_archetypes` dead path** — a TypeScript change needing
its own RED-first brick — nor the `backend/crates/grpc-api` row of the "2.0.0
migration-only" table, which is wrong (that crate *is* rendered by fresh init, Connect
transport and `connectrpc =0.3.3` pin included; only the 2.0.0 variant with
`jwt_middleware.rs` is migration-only). Both are recorded with their measurements.

## The guard, and why the existing one is the defect it is meant to catch

`b5.test.sh`'s FR-IW-009 guard loops over five hardcoded names and greps the **whole
document** for each. Measured by deleting one row at a time and re-running CI's own
invocation: **4 of the 7 archetype rows can be deleted with CI green** — including
`full-stack-monorepo`. The two it does pin are `flutter-firebase` and `rust-cli-tui`;
the two live archetypes shipped since April, `ai-native-rag` and `event-driven-eu`,
are unprotected. The incentives are exactly inverted: the correct cleanup turns CI red
and real drift stays green.

This is the `b9-10` T-029 defect one file over — a presence guard that matches a name
anywhere instead of a claim in its region — so the fix is the same shape: derive the
expected set from `dispatch-table.yml`, scope the match to table rows, and floor it
against vacuity.

## Scope

**In:** the decision-tree section; the `flutter-firebase` and `mobile-only` status
cells; the flagship Stack cell's two stale claims (Kong, and the cancelled
Temporal → DBOS swap); a derived guard in `b5.test.sh`; a content guard in
`b9-2.test.sh`; CHANGELOG and resync.

**Out:** any `mobile-pwa-first` table row (B.9.11); `cli/` code; the J.8 refusal table
itself; the `grpc-api` migration-only row; `.forge/specs/` and every template.

## Negative scope

MUST NOT edit the `rust-cli-tui` row — it is required verbatim by `FR-IW-009`
(`b5-1-init-wizard/specs.md:252`) and pinned by the harness. MUST NOT edit
`docs/ARCHITECTURE-TARGET.md`, which is sha256-pinned by T.4. MUST NOT assert any iOS
platform capability the repository does not establish.
