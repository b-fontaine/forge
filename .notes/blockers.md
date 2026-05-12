# Blockers — f3-release-script-fix

## 2026-05-12 — shellcheck not locally available

**What**: NFR-F3-005 asks `scripts/release.sh` to be shellcheck-clean
at severity `warning`.

**Status**: deferred to CI / out-of-session verification.

**Root cause**: the sandbox blocks both `command -v shellcheck`
(returns exit 1 — not installed) and `docker run ... koalaman/shellcheck`
(blocked by the permission layer). No way to exercise shellcheck
from this session.

**Mitigation**:
- The script was authored carefully against shellcheck-warn-level
  rules (quoted variable expansions, `[ ... ]` brackets, no
  unquoted globs, `read -r`, `printf '%s'` over `echo` for
  arbitrary strings).
- CI's `lint` job in `.github/workflows/forge-ci.yml` scans
  `.forge/scripts` and `bin` with `severity: warning` but **NOT**
  `scripts/` (the job scope is fixed by directory). So even CI
  does not enforce shellcheck on `scripts/release.sh`. This is a
  pre-existing CI scope gap acknowledged in
  `.forge/changes/f3-release-script-fix/tasks.md`
  § "Phase 4 ADDENDUM — `forge-ci.yml::lint` job scope".
- A maintainer running `shellcheck scripts/release.sh` locally can
  surface any warning ; if found, a follow-up commit on a
  separate change can address it.

**Impact on F.3 archival**: NFR-F3-005 is a SHOULD (best-effort).
The other gates (`verify.sh`, `constitution-linter.sh`,
`f3.test.sh`, `forge-ci.yml` ≤ 300 lines) all PASS.
