# Proposal — `b9-10-migration-paths`

Document the `mobile-only / 1.0.0 → mobile-pwa-first / 2.0.0` migration in
`docs/MIGRATION-PATHS.md`, and make that document's own claim true.

## The document does not do what its first sentence says

`docs/MIGRATION-PATHS.md` opens with:

> *"This document indexes every supported migration in Forge."*

It indexes **one**: the T.5 Connect-codegen additive. The flagship
`full-stack-monorepo 1.0.0 → 2.0.0` — a shipped migration with a driver script, a
runbook and a rollback procedure — is absent, because B.8.10 wrote its runbook into
`docs/MIGRATIONS.md` and nothing ever linked the two. So a reader who follows the
index gets a partial answer and does not know it.

The plan says as much at §8: *"`docs/MIGRATION-PATHS.md` (enrichi B.8 + B.9)"*. §5.2
names only the B.9 half. Both halves are the same defect, so both are in scope here.

## What this brick actually settles

Two documents claim migration territory and neither states its boundary:

| document | created by | what it holds today |
|---|---|---|
| `docs/MIGRATIONS.md` | B.8.10 | the flagship `1.0.0 → 2.0.0` runbook, in full |
| `docs/MIGRATION-PATHS.md` | T.5 | the T.5 additive, in full ; and a claim to index everything |

`.forge/specs/init-wizard.md:276` already assigned the boundary and it was never
written down in the documents themselves: MIGRATION-PATHS is the *cross-archetype*
guide. B.9.9 produced the first cross-archetype migration in the repository, so the
boundary now has a case to hold.

**The division this brick writes down:** `MIGRATIONS.md` owns same-archetype
version-to-version runbooks. `MIGRATION-PATHS.md` is the index of everything, and owns
the cross-archetype paths in full. One migration, one owning document, one row in the
index either way.

## Why the B.9 section is short, and that is the finding

The plan estimated this brick at `M` and then revised it: *"c'est ici trivialisée par
B.9.9"*. That holds, and for a reason worth stating rather than assuming — the B.9.9
migration adds **26 files and modifies zero**, so the section has no merge semantics,
no conflict ledger and no phase table to describe. Compare `MIGRATIONS.md`'s flagship
section: 4 phases, a canary cutover, a rollback runbook and a latency methodology.

An additive migration's documentation is mostly *what it will refuse to do*.

## One thing the section must say that no prior brick recorded

`.forge/framework-owned-paths.yml` in `mobile-pwa-first / 2.0.0` is **byte-identical**
to `mobile-only`'s (`sha256 a9a7921e…`) and names nothing under `web-pwa/`. So
`forge upgrade` will never 3-way-merge framework-side changes into an adopter's Qwik
surface — for migrated **and** freshly-initialised projects alike.

That is an archetype gap, not a migration defect: the migrated tree is byte-identical
to a native render, so it inherits exactly the native behaviour. It belongs in the
document because an adopter reading "what stays untouched" will otherwise assume the
opposite. It is recorded as an open question, not fixed here — a doc brick that edits
a template is a doc brick that shipped an untested template change.

## Scope

**In:** `docs/MIGRATION-PATHS.md` — the index table, the boundary statement, the new
B.9 cross-archetype section ; one cross-reference line in `docs/MIGRATIONS.md` ;
harness guards in `b9-2.test.sh` ; CHANGELOG.

**Out:** the decision tree in `docs/ARCHETYPES.md` (B.9.4 owns it) ; the promotion of
`mobile-pwa-first / 2.0.0` out of `candidate` (B.9.11) ; any template, script or
schema edit.

## Negative scope

MUST NOT edit `bin/forge-migrate-mobile-pwa.sh`, any archetype template, or
`framework-owned-paths.yml`. MUST NOT restate the flagship runbook — the index links
to it. Every number the new section states MUST come from `b9-9`'s recorded
measurements or from a probe run here, never from the prose that predicted them.
