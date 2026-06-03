# Notepad
<!-- Auto-managed by OMC. Manual edits preserved in MANUAL section. -->

## Priority Context
<!-- ALWAYS loaded. Keep under 500 chars. Critical discoveries only. -->

## Working Memory
<!-- Session notes. Auto-pruned after 7 days. -->
### 2026-06-03 09:01
b8-10-migrate-flagship Phase 0-8 (Atlas/executor, 2026-06-03): delivered bin/forge-migrate-flagship.sh (sources forge-upgrade.sh, reuses _a7_*; 0/2/5/7/8 envelope; --target/--phase/--dry-run/--force/--rollback; additive 3-way overlay of 27-file 2.0.0 set; rollback from frozen 1.0.0.tar.gz; ledger _b810_tag_last_history_kind kind:flagship-migration + SOURCE_DATE_EPOCH determinism), .forge/scripts/tests/b8-10.test.sh (12 L1 + L2 opt-in FORGE_B8_10_LIVE), docs/MIGRATIONS.md 1.0.0->2.0.0, CHANGELOG [Unreleased] anchored b8-10-migrate-flagship, forge-ci.yml +b8-10 line (283 lines, <=300). RED was 2/12 (T-010,T-011 pre-pass); GREEN 12/12.
LESSONS: (1) no-DBOS harness guard strips ONLY comment lines (^[[:space:]]*#) then greps dbos case-insensitive — so usage() heredoc strings and echo lines containing 'DBOS' FAIL even though semantically explanatory; reword active (non-comment) lines to 'cancelled orchestration-swap leg (B8O)' without the literal token. (2) a7.test.sh does NOT accept --level (rejects with rc=2); forge-ci invokes it bare as "a7.test.sh"; native run is 29/29 GREEN — do not pass --level to it during sibling sweeps. (3) smoke-fixture helpers MUST redirect git init/add/commit to /dev/null or the git stdout leaks into the captured $(mkfix) path var. (4) shellcheck default leaves SC1091 (sourced file not followed) + SC2317 (return after exit) as benign info-only notes; -S warning is clean rc=0. forge-upgrade.sh + frozen snapshot/.sha256 left byte-unchanged (verified). Phase 9 (gates/flip/review/archive) left for main thread.


## MANUAL
<!-- User content. Never auto-pruned. -->

