# Forge Governance

This document is the operational source of truth for the Forge project's
governance. It complements the [Forge Constitution](.forge/constitution.md),
which defines the technical articles (TDD, BDD, specs-first, etc.). The
Constitution is **principles**; this file is **procedures**.

It is referenced by **Article XII — Governance** of the Constitution.

---

## Maintainers

The Forge project follows a **BDFL-with-fallback** model. While the project
remains in the **Current Phase** (Constitution `1.x` and fewer than 5 regular
contributors), a single Benevolent Dictator For Life (BDFL) makes final
decisions. A future amendment may transition the project to the **Mature Phase**
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
- **Ratify a Constitution amendment** — the BDFL alone in the Current Phase; a
  majority vote of the maintainer committee in the Mature Phase, with the BDFL
  retaining a veto on amendments only.
- **Moderate the Code of Conduct** — the BDFL via the email listed in
  [Contact](#contact). Reports are confidential.
- **Maintain dependencies and CI** — any maintainer; routine updates do not
  require an amendment.

---

## Decision Making

### Current Phase

While the Constitution is at version `1.x` AND the project has fewer than
five regular contributors, the BDFL takes all final decisions. Discussion
happens in GitHub Issues / Discussions / PR review threads, but the BDFL is
the final arbiter.

A "regular contributor" is, for the purposes of this document, anyone with at
least three merged PRs in the last six months. The BDFL counts the threshold
honestly; this is a discipline, not an automated check.

### Mature Phase

Activation of the **Mature Phase** is itself a Constitution amendment. Once
ratified, the project is governed by a maintainer committee:

- **Size** — 3 to 7 members. The BDFL becomes one of them.
- **Voting** — simple majority on operational decisions (merges, releases,
  appointing co-maintainers, dependency choices).
- **BDFL veto** — limited to Constitution amendments. Operational decisions
  are not subject to veto.
- **Quorum** — at least half the committee must vote within 7 days, or the
  motion is deferred for re-discussion.

The exact election / co-option mechanism is left to the amendment that
activates the Mature Phase; this document records only the principle.

### Conditions for transition

Transition from the Current Phase to the Mature Phase is **not automatic**. It
requires an explicit Constitution amendment (per [Amendment Process](#amendment-process))
that:

1. Lists the initial committee members.
2. Records the date of activation.
3. Sets the voting / co-option rules in `GOVERNANCE.md`.

Until that amendment is ratified, the BDFL model holds.

---

## Amendment Process

To modify the Forge Constitution (`.forge/constitution.md`) — including
adding, modifying, or removing an article, or transitioning to the Mature Phase —
follow these steps in order:

1. **Open a Forge change** with `/forge:propose <name>`. The proposal MUST
   target `.forge/constitution.md` and explain the motivation, the proposed
   text, and the impact on existing articles.
2. **Open a public discussion** lasting at least **7 days**. This
   can be a GitHub Discussion or the PR review thread itself, but it MUST
   be publicly visible. Closed-door amendments are not allowed.
3. **Ratification** by the BDFL in the Current Phase, or by majority vote of
   the committee in the Mature Phase. The BDFL veto applies only in the
   Mature Phase and only to amendments.
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
3. **Pin VERSION + cli/package.json** to the new `X.Y.Z` value (both
   files must match the CHANGELOG heading).
4. **Run the release helper**:
   ```bash
   bash scripts/release.sh --version X.Y.Z --otp 123456
   ```
   The helper performs pre-flight checks (on `main`, clean tree, in
   sync with `origin`, VERSION / `cli/package.json` / CHANGELOG match,
   tag not yet taken, `verify.sh` + `constitution-linter.sh` PASS),
   creates the `vX.Y.Z` annotated tag, pushes it, builds and publishes
   `@sdd-forge/cli` to npm with the supplied 2FA OTP, and creates the
   GitHub release (via `gh` if installed). The helper script is
   **maintainer-side only** and is not shipped to adopters by
   `forge init` today.

   The `--otp` flag is required when 2FA is enabled on the npm
   account (it is, on the BDFL account). Three resolution paths,
   tried in order (per ADR-F3-004) :
   - `--otp <6-digits>` flag (preferred for automation).
   - Interactive silent prompt on a TTY (preferred for manual runs).
   - `$NPM_OTP` environment variable (preferred for CI / scripted
     contexts ; export the value just before invoking the script).

   The helper accepts `--dry-run` for a no-side-effect rehearsal,
   `--skip-npm` and `--skip-gh` to skip individual steps, and
   `--help` for the full flag list. The OTP value is never echoed
   or logged ; dry-run traces redact it as `<redacted>`.

5. **`prepublishOnly` gate (T5.1, `cli-trust-harness`)**. Before
   `npm publish` runs, `cli/package.json::prepublishOnly` chains
   through `node scripts/prepublish-smoke.mjs`, which :

   - Runs `npm pack` to produce the tarball that would be uploaded.
   - Installs that tarball into an isolated npm prefix
     (`npm install --prefix=<tmp> --global`). The maintainer's
     global prefix is never touched.
   - Scaffolds `full-stack-monorepo` against a fresh tmpdir using
     the **installed binary**, asserts the file matrix from
     `cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml`,
     and runs `task --list-all` on the scaffolded project (skip-pass
     when `task` is absent).

   A failure aborts `npm publish` before the tarball reaches the
   registry. The captured tarball + tmpdir paths are printed to
   stderr for post-mortem.

   **Emergency override** : `FORGE_SKIP_PREPUBLISH=1` (ADR-T51-005)
   skips the gate with a loud stderr warning containing the literal
   string `BYPASS`. The override is reserved for cases where the
   gate itself blocks legitimate work (transient npm registry
   flakes, gate false-positives). Every use of this variable MUST be
   followed within 7 days by a GitHub issue titled
   `[T5.1 bypass post-mortem] vX.Y.Z` and labeled `cli-trust-harness`,
   documenting what went wrong, what was bypassed, and what fix
   landed.

### Release communication policy

Forge ships several release types ; each calls for a different
communication surface. The matrix below documents the convention :

| Release type                                                     | GitHub Release notes | GitHub Discussions Announcement |
|------------------------------------------------------------------|----------------------|--------------------------------|
| **Patch** (`v0.X.y` → `v0.X.y+1`)                                 | **Required** — CHANGELOG section auto-extracted | **Skip** — too frequent ; signal-to-noise ratio low |
| **Pre-GA minor** (`v0.X.0` → `v0.X+1.0` while on `0.y.z` track)   | **Required**          | **Required** — surface what adopters see (new archetypes, schema bumps, breaking templates) |
| **Major / point-of-no-return** (B.8 flagship 2.0.0, v1.0, …)     | **Required**          | **Required** + carefully written (migration guide link, breaking changes, call for feedback) |
| **Structural decision** (Constitution amendment, archetype taxonomy change, ADR retiré, …) | optional (if no release) | **Required** even without a release tag |

Rationale :

- **Patches** are tactical fix-forwards (e.g. v0.3.1, v0.3.2,
  v0.3.3 shipped within 14 days). Posting each on Discussions
  burns reader attention without proportional informational
  value. The CHANGELOG + GitHub release notes remain the canonical
  audit trail.
- **Pre-GA minors** introduce visible surface changes for
  adopters (new archetypes, breaking templates, schema bumps).
  The Discussions Announcement category (post-only-by-maintainer,
  comment-by-anyone) is the right channel.
- **Majors / point-of-no-return** require explicit narrative :
  what changed, why now, what migration path. The post is the
  canonical entry point for the community.
- **Structural decisions** without a release tag (e.g. ADR-007
  retiring `flutter-firebase`, an Article XII amendment) MUST
  hit Discussions — the audit trail is in `.forge/standards/REVIEW.md`
  or `.forge/changes/`, but the **community awareness** lives on
  Discussions.

This policy is informed by [GitHub's own observations on Discussions
signal-to-noise](https://github.com/orgs/community/discussions/171009) :
notification filtering by category is not granular enough to make
every-patch announcements useful ; reserving the channel for changes
adopters actually need to know about preserves attention.

When in doubt : **skip the Discussion post**. The maintainer can always
backfill an announcement when adopter feedback signals demand. The
inverse — un-posting a noisy announcement — is impossible.

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
