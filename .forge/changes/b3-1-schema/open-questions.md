# Open questions — `b3-1-schema`

## Q-001 — `client-only` is the wrong name for a devtool

`layer_profile` accepts `multi-layer` or `client-only`. A CLI binary is a client of
nothing Forge scaffolds; what the discriminator really answers is *"does the
{backend, frontend, infra} triple apply?"*, and the honest answer is no.

Not resolved here. A third value with identical behaviour is taxonomy inflation — two
names, one meaning. A rename touches `mobile-pwa-first`'s shipped schema,
`validate-foundations.sh` and three harnesses to change a word, on an enum `b9-1::T-014`
pins. Either is a cross-archetype decision, and neither belongs in the brick that merely
became the second user of the discriminator.

The schema explains itself in place, which is the most this brick can honestly do.

## Q-002 — every `delivered_by` number is inferred

`B.3.2`, `B.3.4`, `B.3.5`, `B.3.6`, `B.3.7` name bricks whose existence and numbering
come from the same precedent as B.3.1 itself, not from a plan. `T-014` asserts they stay
inside B.3; nothing asserts they are the right numbers, because nothing could.

Whoever transcribes the real B.3.1 → B.3.14 breakdown should reconcile these five
pointers with it. They are cheap to move and were written to be moved.

## Q-003 — B.3's signing bricks will not be verifiable here

Maintainer arbitration 2026-09-13: `code-signing` (B.3.5) ships **scaffold and
documentation**, not a produced signature. codesign needs an Apple Developer
certificate and Authenticode an EV certificate on an HSM — adopter identities Forge
cannot hold. `gpg` alone could be proven with a test key generated in CI.

Recorded now, at the schema, rather than discovered at B.3.5. The precedent is `b9-7`,
which deliberately did not ship the `pwa-deploy` job: a scaffolded deploy is red on day
one until the adopter supplies secrets.

## Q-004 — a devtool archetype has no example tree, and CI gates three

`forge-ci.yml`'s `example` job gates three example trees (FR-CI-012, `b6-8`). B.3 will
eventually want a fourth, and each costs harness lines against a budget just raised to
440 with ~19 left.

Worth deciding early whether `rust-cli-tui` gets an example tree at all. A devtool is
the one archetype whose output is a binary rather than a repository, so "an example
tree" may be the wrong shape for it — and finding that out at B.3.13 would be expensive.
