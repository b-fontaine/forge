# Proposal: f3-release-script-fix
<!-- Created: 2026-05-12 -->
<!-- Schema: default -->

## Problem

The v0.3.0 release (2026-05-04, archived `optim → main` PR) was
performed by hand-driving `scripts/release-v0.3.0.sh`. The release
post-mortem captured in `.forge/product/roadmap.md` (line 118-119)
identified **two latent defects** in the release helper script that
must be fixed before the maintainer tags the next v0.3.x release :

1. **Cumulative `cd` via `eval`** (the `run()` helper at
   `scripts/release-v0.3.0.sh:54-60` evaluates string arguments with
   bash `eval`). Steps that contain `cd cli && ...` leave the calling
   shell in `cli/` because the `eval` is executed in the parent shell.
   On a successful run the cumulative effect is benign (steps 5 then
   6 happen to want the same `cli/` directory) ; on a failure the
   script exits from `cli/`, contaminating the user's shell when
   they `source` or re-enter the directory tree. Worse, when the
   script reaches the post-`cd cli` `npm publish && cd "$REPO_ROOT"`
   block (line 166), the `cd "$REPO_ROOT"` is *also* `eval`-ed only
   when `DRY_RUN=0`, leaving the dry-run path divergent.

2. **2FA OTP not handled.** `npm publish` requires a 6-digit One-Time
   Password when the maintainer's npm account has 2FA enabled (Forge's
   maintainer account has 2FA on, per the v0.3.0 release notes —
   ANNEX). The current script invokes `npm publish --access public`
   with no OTP plumbing ; the publish step **hangs interactively**
   waiting for stdin, which is broken when the script is invoked from
   automation (CI, `nohup`, `ts-node`) or when stdin has been
   redirected. The maintainer worked around this in v0.3.0 by
   running `npm publish` manually outside the script — defeating the
   purpose of the helper.

Beyond the two bugs, the file name `release-v0.3.0.sh` itself is
problematic : it pins the script to a specific version in its
filename, so the next release would require either renaming the
script (orphaning the audit trail) or hard-coding `v0.3.0` everywhere
again. The maintainer has decided (pre-change, see Background in
mission spec) to **rename the maintainer-side script to a generic
`scripts/release.sh`** and accept the release version via a `--version
<X.Y.Z>` flag.

The adopter-side copy of the script is shipped via `forge init` (or
the equivalent template emit path). Investigation **2026-05-12** of
`cli/assets/scripts/` found that the adopter copy **does NOT exist**
in the current tree — no `cli/assets/scripts/release-v0.3.0.sh` is
shipped today. The mission brief flagged this as a possible
mistake ; this change resolves it by leaving the question OUT of
scope and confirming the script is currently maintainer-only (see
`open-questions.md` Q-002).

This change ships :

- A new generic maintainer-side script `scripts/release.sh` (renamed
  + refactored) accepting `--version <X.Y.Z>` and `--otp <6-digits>`,
  with subshell isolation for every `cd` and an OTP fallback chain.
- A removal of the old `scripts/release-v0.3.0.sh` (the new
  generic script supersedes it ; the old name is **not** kept as a
  symlink — see ADR-F3-001 in `design.md`).
- A new test harness `.forge/scripts/tests/f3.test.sh` with
  ≥ 10 L1 hermetic grep-based tests + 1 L2 fixture (opt-in via
  `FORGE_F3_LIVE=1` running a mock `npm publish` shim that asserts
  the OTP was forwarded).
- Harness registration in `.github/workflows/forge-ci.yml` matrix
  (NFR-CI-002 ≤ 300 lines respected).
- Updated GOVERNANCE.md § Release Process to reflect the new
  script name + the `--otp` flag.
- CHANGELOG `[Unreleased]` entry.
- Roadmap + plan updates (F.3 Phase 3 detail row flipped Pending →
  Done ; T8 row note "F.3 pulled forward, delivered 2026-05-12").

## Solution

A single bash script `scripts/release.sh` (renamed from
`scripts/release-v0.3.0.sh`), refactored along three axes :

### F.3.a — Rename + `--version` plumbing

- File rename : `scripts/release-v0.3.0.sh` → `scripts/release.sh`.
  The old file is removed (no symlink ; ADR-F3-001 resolves Q-001
  with the simpler choice).
- New required flag `--version <X.Y.Z>` (no default — the script
  refuses without it). `--version` value validated against
  `^[0-9]+\.[0-9]+\.[0-9]+$` ; mismatches exit 2 (usage error).
- `TAG` and `EXPECTED_VERSION` derived from `--version` :
  `TAG="v$VERSION"`, `EXPECTED_VERSION="$VERSION"`.
- Pre-flight checks (existing) refactored to use the derived values
  ; the CHANGELOG `^## \[X\.Y\.Z\]` grep is parameterised on
  `$EXPECTED_VERSION`.
- ADR-F3-002 records the choice **`--version <X.Y.Z>` over
  `--bump <level>`** : `--version` is the more explicit form,
  matches `git tag` mental model, and avoids re-computing the next
  semver in shell (we already maintain `VERSION` file + CHANGELOG
  pinning manually).

### F.3.b — Subshell isolation (fix bug 1)

The current `run()` helper (line 54-60) uses `eval "$@"`. Replace
the body of `run()` so that any `cd` performed inside the evaluated
string happens in a subshell. Two complementary mechanisms :

1. The `run()` helper itself wraps execution in `bash -c "$*"` (a
   sub-shell), so any `cd` inside the evaluated string can only
   affect the sub-shell and dies with it.
2. The single in-script step that previously did `cd cli && npm
   publish && cd "$REPO_ROOT"` (line 166) is rewritten as a
   subshell : `( cd cli && npm publish --access public --otp "$OTP" )`.

After the refactor, `pwd` at the script's exit MUST equal `pwd` at
script entry — this is the structural invariant. The harness
asserts the property by grepping for the absence of any top-level
`cd "$REPO_ROOT"` re-entry (the subshell discipline obviates it),
and by asserting that the only `cd` outside `(... )` or `pushd/popd`
pairs is the very first `cd "$REPO_ROOT"` that anchors the working
directory after parsing args (line 47 of the existing script ;
preserved verbatim).

### F.3.c — 2FA OTP handling (fix bug 2)

A three-tier OTP fallback chain :

1. **Explicit flag (preferred)** : `--otp <6-digits>`. Value
   validated against `^[0-9]{6}$` ; mismatches exit 2.
2. **Interactive stdin (TTY)** : if `--otp` absent AND `[ -t 0 ]`
   true AND `SKIP_NPM=0` AND `DRY_RUN=0`, prompt
   `read -rsp "npm 2FA OTP (6 digits, leave blank to skip): " OTP`.
   Empty input → exit 2 with a clear message.
3. **Environment variable (CI)** : if both above are absent,
   consult `$NPM_OTP`. Absence here exits 2 with a clear message.

The OTP is **never logged** : the `step()`/`ok()`/`run()` helpers
only echo their first argument or the literal `[dry-run] $*`
prefix ; the OTP is passed via `npm publish --otp="$OTP"` and is
not interpolated into any `echo`/`set -x` path. Documented in
ADR-F3-003.

If the `--skip-npm` flag is present, the OTP is **not collected**
at all (the publish step is skipped). If `--dry-run` is present,
the OTP is **collected if `--otp` was passed** but the
`npm publish` command is only logged, never executed (the OTP is
not echoed in the dry-run trace — only `[dry-run] cd cli && npm
publish --access public --otp=<redacted>` appears).

### F.3.d — Test harness

`.forge/scripts/tests/f3.test.sh` ships **10 L1 + 1 L2 = 11 tests**.

L1 (10 hermetic grep-based, ≤ 3 s wall-clock) :

1. New script `scripts/release.sh` exists + executable.
2. Old script `scripts/release-v0.3.0.sh` removed (no leftover at
   the original path).
3. `set -euo pipefail` present near the top.
4. Audit comment `# Audit: F.3 (f3-release-script-fix)` in first
   10 lines.
5. `--version` flag handled in args parsing block.
6. `--otp` flag handled in args parsing block ; `NPM_OTP` env-var
   fallback present.
7. No bare `eval cd ...` anywhere in the file.
8. No top-level `cd ...` outside the initial anchor (line ~47) ;
   every other `cd` lives inside `(...)` parens or after a
   matched `pushd ... popd` pair.
9. `npm publish` invocation carries `--otp` (or `--otp="$..."`)
   forwarding.
10. CHANGELOG.md `[Unreleased]` entry references
    `f3-release-script-fix`.

L2 (1 fixture-based, opt-in via `FORGE_F3_LIVE=1`) :

11. Mock `npm` shim recording its argv ; harness invokes
    `scripts/release.sh --dry-run --version 9.9.9 --otp 123456
    --skip-gh` against a tmpdir fixture, asserts the mock saw
    `--otp=123456`. Skip-pass when `FORGE_F3_LIVE` is not set.

### F.3.e — Doc + governance update

- `GOVERNANCE.md § Release Process` (line 134-154) gets a new
  step 4 sub-bullet listing the OTP flag + the new generic
  filename.
- `CHANGELOG.md [Unreleased]` gets a `### Changed —
  scripts/release.sh (renamed + OTP support) (f3-release-script-fix)`
  entry.
- `.forge/product/roadmap.md` Phase 3 detail row line 192 flips
  `F.3 Pending` → `**Done 2026-05-12** via f3-release-script-fix`.
  Phase 3 quarterly table (line 173) note updated to remove the
  trailing `, F.3` from the T8 module list and add an inventory
  note.
- `docs/new-archetypes-plan.md` T8 row (line 1120) note updated
  to record "F.3 pulled forward to 2026-05-12 ; T8 retains B.9 /
  B.3 / C.2-C.5". Section §10 line 470 reference to F.3 updated.
- The `Inventaire .forge/changes/` table (`.forge/product/roadmap.md`
  near line 472 and `docs/new-archetypes-plan.md` near line 486)
  gets a new row `f3-release-script-fix | archived | T2 / T3
  tooling`.

## Scope In

- Rename `scripts/release-v0.3.0.sh` → `scripts/release.sh` ; remove
  the old file (no symlink ; ADR-F3-001).
- Refactor `run()` helper for subshell isolation ; rewrite the
  `cd cli && npm publish && cd "$REPO_ROOT"` block as a `( cd cli
  && ... )` subshell.
- Add `--version <X.Y.Z>` required flag + validation.
- Add `--otp <6-digits>` flag + interactive-TTY fallback + `NPM_OTP`
  env-var fallback (ADR-F3-003 three-tier chain).
- Forward the resolved OTP to `npm publish --otp="$OTP"` ; never
  log the OTP value.
- `.forge/scripts/tests/f3.test.sh` (≥ 10 L1 + 1 L2 opt-in).
- Register `f3.test.sh` in `.github/workflows/forge-ci.yml`
  `harness` matrix ; keep file under 300 lines (NFR-CI-002).
- `GOVERNANCE.md § Release Process` update.
- `CHANGELOG.md [Unreleased]` entry.
- `.forge/product/roadmap.md` + `docs/new-archetypes-plan.md`
  inventory + status updates.

## Scope Out (Explicit Exclusions)

- **Template versioning** of `cli/assets/scripts/`. The adopter
  template directory does NOT currently ship a release script
  (verified 2026-05-12). If/when one is added, that's a separate
  change. See Q-002 in `open-questions.md`.
- **CI release pipeline** : no new GitHub Actions workflow for
  release automation. The maintainer continues to drive
  `scripts/release.sh` manually post-PR-merge per GOVERNANCE.md.
- **A new release** of the framework. This change only fixes the
  script. The maintainer tags v0.3.1 (or whichever version is
  next) separately, using the fixed script.
- **`npm` SDK / API integration**. The script remains a thin
  bash wrapper around the `npm` CLI.
- **GitHub release notes auto-generation beyond the existing
  CHANGELOG section extraction** (lines 178-185 of the original
  script, preserved verbatim).
- **Sigstore / cosign signing** of the published tarball. Out of
  scope per `global/sbom-policy.md::Out-of-scope`.
- **Constitution amendment.** No Article touched.

## Impact

- **Users affected** :
  - The Forge **maintainer** : new invocation form is
    `bash scripts/release.sh --version 0.3.1 --otp 123456` instead
    of `bash scripts/release-v0.3.0.sh`. Documented in
    GOVERNANCE.md.
  - **Adopters** : no impact. The script is maintainer-side ; no
    adopter template currently ships a release script.
- **Technical impact** : 1 file renamed + refactored (~220 LOC,
  same order of magnitude as the original 218) ; 1 file deleted
  (old name) ; 1 test harness added (~250 LOC) ; 4 small doc
  edits (GOVERNANCE, CHANGELOG, roadmap, plan). No new external
  dependency. No CI worker added beyond the harness matrix row.
- **Dependencies** : the script depends on `git`, `npm`, optional
  `gh` ; same as before. The new `--otp` flag depends on
  `npm publish --otp=<value>` which has been part of `npm` since
  npm 6.x (current LTS ships npm 10.x ; well below the Forge
  CI Node 20.18.0 floor).
- **Risk level** : **Low**. The change is local to a maintainer-
  side helper. The harness asserts every behavioral invariant
  hermetically (grep + mock shim) ; the actual `npm publish`
  side-effect is exercised only when the maintainer runs the
  script for a real release.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`f3.test.sh` with **10 L1 stubs all returning `_not_implemented`**
(full RED witness). Phase 2 ships the renamed + refactored
`scripts/release.sh`. Phase 3 ships the doc / changelog /
roadmap / plan updates. Phase 4 runs final gates.

### Article II — BDD

The user-facing flow (maintainer runs `bash scripts/release.sh
--version 0.3.1 --otp 123456`) gets a Gherkin scenario in
`specs.md`. The internal step-list flow does not.

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-F3-*` +
`NFR-F3-*` namespace before any script authoring.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Two open questions raised at this phase, both resolved during
`/forge:design` :

- **Q-001** — Old script handling : delete vs symlink ?
- **Q-002** — `cli/assets/scripts/` template (does it exist ?
  ship a copy ?).
- **Q-003** — Flag form : `--version <X.Y.Z>` vs `--bump <level>` ?

### Article V — Audit Trail

Each task tagged `[Story: FR-F3-XXX]`. The new script carries
`# <!-- Audit: F.3 (f3-release-script-fix) -->` in its header
comment block. The harness file carries the same audit comment.

### Article VIII — Infrastructure

The script remains a maintainer-side bash helper. No service,
no daemon. The OTP handling is purely local (no secret stored
anywhere ; the OTP is a 6-digit value that expires in 30 s and
is consumed once by `npm publish`).

### Article IX — Observability

N/A. The script is a one-shot release helper, not a runtime
component.

### Article XI — AI-First Design

N/A. The script is maintainer-side automation, not an AI surface.

### Article XII — Governance

The change extends the **Release Process** documented in
GOVERNANCE.md § Release Process. The Release Process itself
remains BDFL-driven (no procedural change). No Article amended.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this
`proposal.md`. Three open questions Q-001 / Q-002 / Q-003 raised
in `open-questions.md`, all resolved by ADR-F3-001..003 in
`design.md`.
