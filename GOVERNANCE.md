# Forge Governance

This document is the operational source of truth for the Forge project's
governance. It complements the [Forge Constitution](.forge/constitution.md),
which defines the technical articles (TDD, BDD, specs-first, etc.). The
Constitution is **principles**; this file is **procedures**.

It is referenced by **Article XII — Governance** of the Constitution.

---

## Maintainers

The Forge project follows a **BDFL-with-fallback** model. While the project
remains in **Phase actuelle** (Constitution `1.x` and fewer than 5 regular
contributors), a single Benevolent Dictator For Life (BDFL) makes final
decisions. A future amendment may transition the project to **Phase mature**
(maintainer committee).

### Current BDFL

| Name             | GitHub handle | Role                                      |
| ---------------- | ------------- | ----------------------------------------- |
| Benoit Fontaine  | `@bfontaine`  | BDFL (current phase ≤ 1.0)                |

### Co-maintainers

The BDFL may delegate write access to **co-maintainers** for specific scopes
(e.g. CI, documentation, an archetype). Co-maintainers are listed below; the
table is intentionally empty until the BDFL appoints the first one.

| Name | GitHub handle | Scope | Appointed on |
| ---- | ------------- | ----- | ------------ |
| —    | —             | —     | —            |

A co-maintainer may be appointed or removed by BDFL decision, recorded as a
PR that updates this table.

---

## Roles and Responsibilities

The roles below are exhaustive: anything not listed defaults to the BDFL.

- **Merge a PR on `main`** — the BDFL or a co-maintainer authorised for the
  affected scope. PRs that touch `.forge/constitution.md`,
  `.forge/standards/`, or this `GOVERNANCE.md` MUST be merged by the BDFL
  only.
- **Publish a release** (npm + GitHub Releases) — the BDFL or a co-maintainer
  explicitly authorised for releases. The full process is in
  [Release Process](#release-process).
- **Ratify a Constitution amendment** — the BDFL alone in Phase actuelle; a
  majority vote of the maintainer committee in Phase mature, with the BDFL
  retaining a veto on amendments only.
- **Moderate the Code of Conduct** — the BDFL via the email listed in
  [Contact](#contact). Reports are confidential.
- **Maintain dependencies and CI** — any maintainer; routine updates do not
  require an amendment.

---

## Decision Making

### Phase actuelle (current phase)

While the Constitution is at version `1.x` AND the project has fewer than
five regular contributors, the BDFL takes all final decisions. Discussion
happens in GitHub Issues / Discussions / PR review threads, but the BDFL is
the final arbiter.

A "regular contributor" is, for the purposes of this document, anyone with at
least three merged PRs in the last six months. The BDFL counts the threshold
honestly; this is a discipline, not an automated check.

### Phase mature

Activation of **Phase mature** is itself a Constitution amendment. Once
ratified, the project is governed by a maintainer committee:

- **Size** — 3 to 7 members. The BDFL becomes one of them.
- **Voting** — simple majority on operational decisions (merges, releases,
  appointing co-maintainers, dependency choices).
- **BDFL veto** — limited to Constitution amendments. Operational decisions
  are not subject to veto.
- **Quorum** — at least half the committee must vote within 7 days, or the
  motion is deferred for re-discussion.

The exact election / co-option mechanism is left to the amendment that
activates Phase mature; this document records only the principle.

### Conditions for transition

Transition from Phase actuelle to Phase mature is **not automatic**. It
requires an explicit Constitution amendment (per [Amendment Process](#amendment-process))
that:

1. Lists the initial committee members.
2. Records the date of activation.
3. Sets the voting / co-option rules in `GOVERNANCE.md`.

Until that amendment is ratified, the BDFL model holds.

---

## Amendment Process

To modify the Forge Constitution (`.forge/constitution.md`) — including
adding, modifying, or removing an article, or transitioning to Phase mature —
follow these steps in order:

1. **Open a Forge change** with `/forge:propose <name>`. The proposal MUST
   target `.forge/constitution.md` and explain the motivation, the proposed
   text, and the impact on existing articles.
2. **Open a public discussion** lasting at least **7 jours** (7 days). This
   can be a GitHub Discussion or the PR review thread itself, but it MUST
   be publicly visible. Closed-door amendments are not allowed.
3. **Ratification** by the BDFL in Phase actuelle, or by majority vote of
   the committee in Phase mature. The BDFL veto applies only in Phase
   mature and only to amendments.
4. **Apply the amendment** by:
   - Adding a row to the `## Amendments` table at the bottom of
     `.forge/constitution.md`.
   - Bumping the `**Version:**` line in the Constitution per semver
     (patch for clarification, minor for additive article, major for
     removal or breaking modification of an existing article).
   - Updating `.forge/templates/change.yaml` and any archetype
     `.forge.yaml.tmpl` files so future changes use the new version.

The change `d5-governance` (which created Article XII and brought Constitution
to `1.1.0`) is the canonical first instance of this process.

---

## Release Process

Forge follows semver (`vX.Y.Z`). Releases are published on npm (the CLI
package) and on GitHub Releases. To cut a release, follow these steps:

1. **Archive the change** that closes the release scope by running
   `/forge:archive <name>`. This invokes Calliope to update
   `CHANGELOG.md` and consolidates spec deltas into `.forge/specs/`.
2. **Verify CHANGELOG.md** lists every user-facing change since the
   previous tag, under a sealed `## [X.Y.Z]` heading (no
   `## [Unreleased]` left dangling for the released entries).
3. **Tag the release** on `main`: `git tag vX.Y.Z && git push --tags`.
   The tag MUST exactly follow the `vX.Y.Z` pattern (no suffix, no
   build metadata).
4. **Publish** — `npm publish` from `cli/` (after `npm run bundle`),
   then `gh release create vX.Y.Z` with notes pulled from
   `CHANGELOG.md`.

A release MUST NOT be cut while any open Forge change is in `proposed`,
`specified`, `designed`, `planned`, or `implemented` state on the release
branch — only `archived` changes count.

---

## Code of Conduct

The Forge project adopts the **Contributor Covenant v2.1**. The full text
lives at [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) at the repository root.

To report a Code of Conduct violation, please contact the BDFL via the
email listed under [Contact](#contact). Reports are treated confidentially.
The BDFL acknowledges receipt within 7 days and decides on enforcement
action per the Contributor Covenant guidelines.

---

## Contact

For governance questions, Code of Conduct reports, or any topic not suited
to public GitHub channels:

- **Email** — `contact@benoitfontaine.fr` (BDFL, monitored)

For non-confidential topics:

- **GitHub Discussions** — https://github.com/bfontaine/forge/discussions
  (proposals, design questions, community announcements)
- **GitHub Issues** — https://github.com/bfontaine/forge/issues
  (bug reports, regressions, concrete actionable tickets)

Please use the public channels first when the topic is not sensitive: the
audit trail benefits future contributors.

---

*This document evolves with the project. Operational changes (adding a
co-maintainer, updating a contact channel) can land via a regular PR.
Structural changes (changing the governance model itself) require a
Constitution amendment per [Amendment Process](#amendment-process).*
