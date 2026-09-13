# Proposal — `b3-1-schema`

`.forge/schemas/rust-cli-tui/1.0.0.yaml` — the contract the rest of B.3 validates
against. First brick of the last unstarted archetype.

## The brick number is inferred, and that is worth saying first

`docs/new-archetypes-plan.md` §3.3 is the whole of B.3's plan:

> *B.3 `rust-cli-tui` — `KEEP`. Inchangé du plan d'origine (B.3.1 → B.3.14).
> Effort : `XL`. Reste à livrer.*

**That list of fourteen items is not in this repository.** The only statement of B.3's
content here is one line of `roadmap.md:202` — cargo-dist, signed releases, SBOM SPDX,
multi-channel distribution.

So "B.3.1 is the schema" is an inference from precedent, not a specification: B.6.1,
B.7.1 and B.9.1 are each their archetype's schema. Three for three. The inference is
recorded as `ADR-B31-001` and stated in the schema's own header, so whoever writes the
real breakdown reconciles rather than discovers.

## What is not invented

The archetype's shape is already ADR-ratified. `archetype.schema.json:21` describes it
as *"Devtools archetype — clap + ratatui + cargo-dist signed releases ; multi-channel
distribution"*, and `t4.test.sh` pins that enum. The two layers — `cli` and `tui` — come
from that sentence, and their agents from the Rust sub-team `CLAUDE.md` fixes: Vulcan
orchestrates, Terminal owns the TUI.

No taxonomy edit is needed, exactly as `b9-1` needed none.

## Four lessons applied rather than relearned

- **No `extends:` key** (`ADR-B9-1-003`). Nothing resolves it: `parseSchemaMeta` reads
  version/stage/scaffoldable, and the validator reads `phases` straight from the file.
  The tdd-rust chain is materialised inline.
- **No version pins.** Every component names its owning standard or a `delivered_by`
  brick. `t7-flutter-deps-refresh` is the cautionary case — nine pins had drifted, three
  by a major, and the resolver corrected three versions read off a registry API.
- **No dispatch key.** Adding one flips `forge init` from exit 2 to exit 3 and makes
  `t5-1` FR-T51-055 demand a CLI trust fixture. Both belong to the template brick, as
  `b7-2a` and `b9-2` did.
- **Candidate, with `scaffoldable: false` asserted as a pair.** A half-flip is what
  `b9-11` had to guard against.

## Scope

**In:** the schema, `b3-1.test.sh` (18 L1), its CI registration — the first line of the
headroom `t7-ci-line-budget-440` opened — and CHANGELOG.

**Out:** templates, the dispatch key, the standards `cli.yaml` will need, and the
promotion. Each is a later B.3 brick, and each `delivered_by` pointer names which.

## Negative scope

MUST NOT touch a shipped archetype's schema, the taxonomy enum, or the dispatch table.
MUST NOT write a resolved version pin — the template brick resolves them live.
