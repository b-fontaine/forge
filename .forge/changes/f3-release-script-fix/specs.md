# Specifications: f3-release-script-fix
<!-- Status: archived -->
<!-- Schema: default -->

**Namespace** : `FR-F3-*` / `NFR-F3-*`. **Constitution** : v1.1.0.
No amendment required (F.3 fixes a maintainer-side helper script ;
modifies no Article).

## Source Documents

| Field                  | Value                                                                                                                                                                                  |
|------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Roadmap ref**        | `.forge/product/roadmap.md` Phase 3 detail row line 192 (F.3) ; v0.3.0 post-mortem line 118-119                                                                                          |
| **Plan ref**           | `docs/new-archetypes-plan.md` line 1120 (T8) ; line 470 (section "Modules toujours en attente")                                                                                          |
| **Original script**    | `scripts/release-v0.3.0.sh` (218 LOC, archived after v0.3.0 release 2026-05-04). Bugs : `eval` accumulates `cd` (line 54-60 `run()`) ; `npm publish` 2FA OTP not handled (line 166)     |
| **GOVERNANCE ref**     | `GOVERNANCE.md § Release Process` lines 134-154 (Forge's 4-step release procedure)                                                                                                       |
| **Pattern reuse**      | Existing maintainer-side bash patterns : `bin/forge-sbom.sh`, `bin/forge-demeter-scan.sh` (F.2 / J.7 / J.8.d bash-thin + Python inline ; not directly applicable here — release.sh is bash-only) |
| **Test harness frame** | `.forge/scripts/tests/i6.test.sh` (16 L1 + 2 L2 grep-based pattern) ; `.forge/scripts/tests/_helpers.sh` (shared assertions + runner)                                                    |
| **CI matrix**          | `.github/workflows/forge-ci.yml` `harness` job (281 lines today ; NFR-CI-002 ≤ 300)                                                                                                      |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Script file rename + presence (FR-F3-001 → 010)

##### FR-F3-001 — New script presence

A new file `scripts/release.sh` MUST exist as an executable
bash script (`-rwxr-xr-x` or equivalent).

##### FR-F3-002 — Audit comment

The new script MUST carry a comment
`# <!-- Audit: F.3 (f3-release-script-fix) -->` or
`# Audit: F.3 (f3-release-script-fix)` within the first 10 lines.

##### FR-F3-003 — Bash strict mode

The new script MUST declare `set -euo pipefail` within the first
50 lines (after the documentation header comment block, which is
~40 lines because of the explicit usage block per FR-F3-006).

##### FR-F3-004 — Old script removed

The file `scripts/release-v0.3.0.sh` MUST NOT exist after this
change (deletion ; no symlink ; ADR-F3-001).

##### FR-F3-005 — Shebang preserved

The new script MUST start with `#!/usr/bin/env bash` on line 1
(identical to the original).

##### FR-F3-006 — Header comment block preserved

The new script's first 25 lines MUST document : its purpose,
the standard invocation form (`bash scripts/release.sh
--version X.Y.Z --otp <6-digits>`), the recognised flags, and
the exit-code envelope (mirrors the original lines 2-22 ;
content adapted to the new flag set).

#### Cluster 2 — `--version <X.Y.Z>` plumbing (FR-F3-020 → 030)

##### FR-F3-020 — `--version` flag accepted

The new script MUST accept a `--version <X.Y.Z>` flag during
argument parsing. Both `--version 0.3.1` and `--version=0.3.1`
forms accepted (mirrors `--level` / `--target` conventions in
the Forge corpus).

##### FR-F3-021 — `--version` required

The new script MUST exit 2 (usage error) if no `--version` flag
is provided AND `--help` is not requested.

##### FR-F3-022 — `--version` validation

The `--version` value MUST match `^[0-9]+\.[0-9]+\.[0-9]+$`. A
non-matching value MUST exit 2 with the message
`release: --version must match X.Y.Z, got '<value>'` on stderr.

##### FR-F3-023 — TAG derivation

The script MUST derive `TAG="v$VERSION"` (prefix `v`) and
`EXPECTED_VERSION="$VERSION"` from the validated `--version`
value.

##### FR-F3-024 — Pre-flight VERSION file check

The pre-flight section MUST compare `cat VERSION | tr -d ' \n'`
against `$EXPECTED_VERSION` and exit 1 if they differ (preserves
the existing pre-flight check 4 of the original script,
parameterised on the supplied `--version`).

##### FR-F3-025 — Pre-flight cli/package.json check

The pre-flight section MUST extract `cli/package.json`'s
`version` field and compare against `$EXPECTED_VERSION` (preserves
the original pre-flight check 5).

##### FR-F3-026 — Pre-flight CHANGELOG check

The pre-flight section MUST grep CHANGELOG.md for a sealed
`^## \[$EXPECTED_VERSION\]` heading (escaped dots) and exit 1 if
absent. The original script's date check (`— 2026-05-01`) MUST
be **removed** (the date is release-specific and would break
the script for any subsequent version) ; the heading alone is
the contract.

#### Cluster 3 — `--otp` flag + fallback chain (FR-F3-040 → 060)

##### FR-F3-040 — `--otp` flag accepted

The new script MUST accept a `--otp <6-digits>` flag during
argument parsing. Both `--otp 123456` and `--otp=123456` forms
accepted.

##### FR-F3-041 — `--otp` validation

The `--otp` value MUST match `^[0-9]{6}$`. A non-matching value
MUST exit 2 with the message
`release: --otp must be 6 digits, got '<redacted>'` on stderr
(the rejected value is redacted, not echoed).

##### FR-F3-042 — Interactive TTY fallback

If `--otp` is absent AND `[ -t 0 ]` is true (stdin is a TTY)
AND `--skip-npm` is absent AND `--dry-run` is absent, the script
MUST prompt the user with `read -rsp` (silent read) for the OTP.
The prompt string MUST mention "npm 2FA OTP" and "6 digits".
The read value MUST be validated per FR-F3-041.

##### FR-F3-043 — Env-var `NPM_OTP` fallback

If `--otp` is absent AND `[ -t 0 ]` is false (stdin is not a
TTY) AND `--skip-npm` is absent AND `--dry-run` is absent, the
script MUST consult `$NPM_OTP`. Absence (empty value) MUST exit
2 with the message
`release: 2FA OTP required (pass --otp, run on a TTY, or set NPM_OTP)`
on stderr.

##### FR-F3-044 — Forward to `npm publish`

When the publish step runs (i.e., `--skip-npm` is absent AND
`--dry-run` is absent), the resolved OTP value MUST be passed
to `npm publish` via `--otp="$OTP"`. The forwarding MUST happen
inside a subshell (`(...)`) so any `cd cli` inside the subshell
cannot affect the parent shell's working directory
(FR-F3-061).

##### FR-F3-045 — OTP never logged

The resolved OTP value MUST NOT appear in any `echo` /
`step()` / `ok()` / `run()` output, dry-run trace, or error
message verbatim. The dry-run trace for the publish step MUST
render the OTP as `<redacted>` (e.g.,
`[dry-run] cd cli && npm publish --access public --otp=<redacted>`).

##### FR-F3-046 — `--skip-npm` skips OTP collection

If `--skip-npm` is present, the OTP MUST NOT be collected. The
TTY prompt MUST NOT fire ; `$NPM_OTP` MUST NOT be consulted ;
absence of `--otp` MUST NOT cause exit 2.

##### FR-F3-047 — `--dry-run` skips OTP collection

If `--dry-run` is present AND `--otp` is absent, the script MUST
NOT prompt the user. The dry-run mode is non-interactive by
design ; a maintainer running `--dry-run` is exploring, not
publishing. The dry-run trace of the publish step renders the
OTP placeholder as `<would-be-resolved-at-publish-time>`.

#### Cluster 4 — Subshell isolation (FR-F3-060 → 070)

##### FR-F3-060 — `run()` helper subshell

The `run()` helper MUST execute its argument string inside a
subshell (`bash -c "$*"` or `( eval "$@" )`). Any `cd` inside
the evaluated string MUST be isolated from the parent shell.

##### FR-F3-061 — Inline `cd` blocks subshell-wrapped

Every step in the script that contains `cd cli` (or any other
directory change) MUST be wrapped in a subshell `( cd cli &&
... )` rather than the original
`cd cli && ... && cd "$REPO_ROOT"` pattern.

##### FR-F3-062 — Top-level `cd` count

The script MUST contain **exactly one** top-level `cd`
invocation : the initial `cd "$REPO_ROOT"` that anchors the
working directory after argument parsing (preserves the original
script's line 47). Every other `cd` MUST live inside `(...)`
parens.

##### FR-F3-063 — No `eval cd ...`

The script MUST NOT contain any bare `eval "cd ..."`,
`eval cd ...`, or equivalent eval-then-cd pattern. The intent
is to forbid the cumulative-`cd` bug class entirely.

##### FR-F3-064 — Working directory invariant

At script exit (any exit code), `pwd` MUST equal the value of
`pwd` at script entry. Asserted structurally by FR-F3-061 +
FR-F3-062 + FR-F3-063 ; not directly verified by the harness
(would require fork-and-trace).

#### Cluster 5 — Harness (FR-F3-080 → 100)

##### FR-F3-080 — Harness file presence

`.forge/scripts/tests/f3.test.sh` MUST exist as executable
bash.

##### FR-F3-081 — Harness audit comment

The harness MUST carry `# Audit: F.3 (f3-release-script-fix)`
within the first 10 lines.

##### FR-F3-082 — L1 test count

The harness MUST run **≥ 10 L1 hermetic tests** covering the
manifest in `design.md` § "L1 unit-level" table.

##### FR-F3-083 — L2 test count

The harness MUST declare **1 L2 fixture-based test** gated by
both `--level 2` (or `--level 1,2` / `--level all`) AND
`FORGE_F3_LIVE=1`. When either gate is absent, the test MUST
exit 0 with an informational `[INFO: ...]` line on stderr.

##### FR-F3-084 — `--level` parsing

The harness MUST accept `--level 1`, `--level 2`,
`--level 1,2`, `--level all` (default `1`). Mirrors the
existing harness convention.

##### FR-F3-085 — Exit codes

The harness MUST exit 0 when all tests GREEN, 1 otherwise.

##### FR-F3-086 — Harness MANIFEST comments

The harness MUST cite at least one FR-F3-XXX identifier per
test function in MANIFEST comments (mirrors `i5.test.sh` /
`i6.test.sh`).

##### FR-F3-090 — CI registration

`.github/workflows/forge-ci.yml` `harness` job MUST contain a
new matrix row invoking `bash .forge/scripts/tests/f3.test.sh
--level 1` immediately after the existing `i5.test.sh` row.
The file MUST stay under 300 lines (NFR-CI-002).

#### Cluster 6 — Doc + governance (FR-F3-110 → 130)

##### FR-F3-110 — GOVERNANCE.md update

`GOVERNANCE.md § Release Process` (line 134-154) MUST be
updated to :
- Replace `scripts/release-v0.3.0.sh` references with
  `scripts/release.sh`.
- Document the `--version` and `--otp` flags.
- Note the OTP fallback chain (flag → TTY → `NPM_OTP`).

##### FR-F3-120 — CHANGELOG entry

`CHANGELOG.md [Unreleased]` MUST gain a
`### Changed — scripts/release.sh (renamed + OTP support) (f3-release-script-fix)`
entry citing the rename + the subshell-isolation fix + the OTP
plumbing.

##### FR-F3-125 — Roadmap inventory delta

`.forge/product/roadmap.md` MUST flip the F.3 row at line 192
(Phase 3 detail table) from `Pending` to
`**Done 2026-05-12** via f3-release-script-fix`. The T8 row
at line 173 MUST drop the trailing `, F.3` from the modules
list and add an inline note acknowledging the early delivery.

##### FR-F3-126 — Plan inventory delta

`docs/new-archetypes-plan.md` MUST update :
- Line 470 (`### Modules toujours en attente`) reference to
  F.3 to flip it from pending to done.
- Line 1120 (T8 row) module list to remove F.3 and add an
  inline note.

##### FR-F3-127 — Inventaire row

Both `.forge/product/roadmap.md` (line ~472) and (optionally)
`docs/new-archetypes-plan.md` (line ~486) Inventaire tables
MUST gain a row for `f3-release-script-fix | archived | T2 / T3
tooling`.

---

### Non-Functional Requirements

#### NFR-F3-001 — Test harness performance budget

`bash .forge/scripts/tests/f3.test.sh --level 1` MUST complete
in ≤ 3 s wall-clock on a developer laptop. Hermetic grep-based
tests only at L1 ; no spawn of `npm` / `git` ops.

#### NFR-F3-002 — Script file size budget

`scripts/release.sh` SHOULD remain under 400 lines (the original
script is 218 lines ; the refactor adds ~140 lines : the
`_resolve_otp()` helper + `--version` + `--otp` parsing + the
widened header comment block documenting the OTP fallback chain
+ the subshell wrappers + a `_print_help` helper). Soft
constraint. Measured 2026-05-12 : 357 lines.

#### NFR-F3-003 — Backward compatibility

The change is **breaking** for the maintainer's invocation
form : `scripts/release-v0.3.0.sh` no longer exists ; the new
form REQUIRES `--version`. This is acceptable because :
- The script is maintainer-side only ; no adopter consumes it.
- GOVERNANCE.md is updated in the same change.
- The next release (v0.3.1) will use the new form from day one.

#### NFR-F3-004 — verify.sh / constitution-linter additive

The change MUST NOT introduce new `[NEEDS CLARIFICATION:]`
markers in implemented changes. `verify.sh` overall PASS MUST
be preserved (Passed total monotonically increases or stays
equal). `constitution-linter.sh` OVERALL PASS MUST be preserved.

#### NFR-F3-005 — Shellcheck clean

`scripts/release.sh` MUST pass `shellcheck` with **zero
warnings at severity `warning`** (matching the
`forge-ci.yml::lint` job's `severity: warning` setting). Any
deliberate `# shellcheck disable=<rule>` MUST carry a one-line
rationale comment immediately above.

#### NFR-F3-006 — Forge-ci.yml line budget

The `.github/workflows/forge-ci.yml` matrix-row addition MUST
keep the file under the NFR-CI-002 budget of 300 lines.
Current file is 281 lines ; adding one row brings it to
~284. Comfortable margin.

#### NFR-F3-007 — OTP non-disclosure

The resolved OTP value MUST NOT appear in :
- Standard output of the script.
- Standard error of the script.
- Any temp file the script creates.
- Any `set -x` trace if the maintainer activates it (the
  script MUST NOT activate `set -x` itself).

Asserted by FR-F3-045 ; verified structurally by the harness
(grep for `OTP` in the script source asserts no `echo
$OTP` or equivalent pattern exists).

---

## ADRs (locked at design time, see `design.md`)

- **ADR-F3-001** — Old script handling : **delete**, no symlink
  (resolves Q-001).
- **ADR-F3-002** — `cli/assets/scripts/` template handling :
  **out of scope** (the template does not exist in the current
  tree ; resolves Q-002).
- **ADR-F3-003** — Flag form : **`--version <X.Y.Z>`** (resolves
  Q-003).
- **ADR-F3-004** — OTP fallback chain : flag → TTY (interactive
  `read -rsp`) → env-var `NPM_OTP` ; fail with exit 2 if all
  three absent and publish is not skipped (resolves Q-004).

---

## Constitutional Compliance summary

- **Article I (TDD)** — RED → GREEN → REFACTOR enforced via
  `tasks.md` Phase 1 (full RED harness) before Phase 2 (script
  rename + refactor).
- **Article II (BDD)** — Gherkin scenario in `proposal.md` for
  the maintainer's release-invocation flow.
- **Article III.4 (anti-hallucination)** — `[NEEDS
  CLARIFICATION:]` protocol observed ; four Q-NNN open
  questions resolved in `design.md`. Q-002 specifically
  prevented invention of a non-existent template.
- **Article V (audit trail)** — every task tagged
  `[Story: FR-F3-XXX]` in `tasks.md` ; script + harness both
  carry the `<!-- Audit: F.3 (...) -->` anchor.
- **Article XII (governance)** — `GOVERNANCE.md § Release
  Process` is updated in the same change. No constitutional
  amendment.

No constitutional amendment required.
