<!--
  Forge PR template.
  Every PR MUST satisfy the Constitution (.forge/constitution.md) and the
  TDD rules (.forge/standards/global/tdd-rules.md). Check each box below
  truthfully — maintainers verify, they do not re-run your tests for you.
-->

## Summary

<!-- 1–3 sentences: what changes, and why. Link to issue(s) or roadmap item(s). -->

Closes #

## Change type

- [ ] Bug fix (PATCH)
- [ ] New feature / capability (MINOR)
- [ ] Breaking change (MAJOR — pre-1.0: breaking change under MINOR also allowed, see `docs/VERSIONING.md`)
- [ ] Documentation only
- [ ] Internal / CI / repo hygiene

## Related Forge change (if any)

<!--
  If this PR implements an item from `.forge/changes/<name>/`, link the
  proposal / specs / design / tasks files here. For cross-cutting framework
  changes (T-series roadmap items), link the roadmap section instead.
-->

- Proposal: `.forge/changes/<name>/proposal.md`
- Specs: `.forge/changes/<name>/specs.md`
- Design: `.forge/changes/<name>/design.md`
- Tasks: `.forge/changes/<name>/tasks.md`

## Constitutional compliance

- [ ] Article I — TDD: every production change is preceded by a failing test that I ran and saw fail. Evidence in the commit history or CI log.
- [ ] Article II — BDD: user-facing behavior has a Given/When/Then scenario (if applicable).
- [ ] Article III — Specs before code: no implementation without an accepted spec (or this PR is the spec itself).
- [ ] Article IV — Semantic delta: `specs.md` uses ADDED / MODIFIED / REMOVED blocks (if applicable).
- [ ] Article V — Gates: `verify.sh` and `constitution-linter.sh` pass locally.
- [ ] Article VI–XI — domain articles applicable to this change: listed below, each respected.

<!-- List the applicable articles (e.g. VII for Rust, IX for observability, XI for AI-first) with one line per article on how this PR complies. -->

## Testing

- [ ] New/changed behavior is covered by a failing test that I watched fail before making it pass (RED → GREEN).
- [ ] All existing tests still pass (`task test` / `npm test` / `cargo test` as appropriate).
- [ ] Deterministic scripts pass: `bash .forge/scripts/verify.sh && bash .forge/scripts/constitution-linter.sh`.

## External libraries

- [ ] I did not use training data for external library APIs.
- [ ] Docs were resolved via Context7 (`mcp__context7__resolve-library-id` → `mcp__context7__query-docs`) for each external library touched. List the libraries:
  - `<library-name>@<version>`

## Documentation & changelog

- [ ] `CHANGELOG.md` updated under `## [Unreleased]` with the right subsection (`Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security` / `BREAKING`).
- [ ] User-facing documentation updated (`README.md`, `docs/`, relevant standard, relevant agent prompt) when behavior changes.
- [ ] `VERSION` and `docs/VERSIONING.md` unchanged **unless** this PR is a release PR (then the bump is justified below).

## Version bump (release PRs only)

<!-- Delete this section for non-release PRs. -->

- [ ] `VERSION` bumped according to `docs/VERSIONING.md`.
- [ ] Release notes drafted in the GitHub release UI or queued for `release-please`.

## Risk and rollback

- **Blast radius**: <!-- local file / deterministic script / CLI / installer / Docker image / multi-project -->
- **Rollback plan**: <!-- revert commit / manual steps / N/A -->

## Reviewer checklist

- [ ] Reviewed the linked Forge change (proposal + specs + design + tasks) if applicable.
- [ ] Verified the TDD evidence (commits or CI log), not just the claim.
- [ ] Ran `verify.sh` and `constitution-linter.sh` locally on the PR branch.
- [ ] Confirmed the CHANGELOG entry is accurate and categorized correctly.
