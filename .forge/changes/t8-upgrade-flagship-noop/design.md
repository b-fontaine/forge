# Design — `t8-upgrade-flagship-noop`

## One wrong premise, one missing step

```
_a7_project_archetype   "has a plan" + "project has .forge/framework-owned-paths.yml"
                         → the flagship satisfies both, with the FRAMEWORK's own file
_a7_render_archetype    overlay.sh only → `{{reverse_domain_path}}/` stays literal
```

The first sends the flagship into a mode built for renders whose declaration comes from
their own template. The second makes the one archetype built for that mode skip a declared
file. Neither shows up in the exit code. The only trace is `files skipped`, a count that
nothing asserted on.

## Changes

- **`_a7_archetype_plan <arch_dir> <manifest>`** — new helper holding the plan-selection
  rule that `_a7_render_archetype` applied inline (`scaffold-plan-<version>.yaml`, else
  `scaffold-plan.yaml`). Detection and rendering therefore cannot read different plans.
  For rendering, the rule is unchanged. It additionally refuses a non-SemVer version
  (FR-T8UFN-006).
- **`_a7_project_archetype`** gains the ADR-T8UFN-001 condition: the selected plan has a
  `templates:` entry whose `target:` is `.forge/framework-owned-paths.yml`. This is a pure
  YAML read with no render. An unparsable plan is now reported. Before this change it
  entered archetype mode and the render failure announced the fallback; the new check
  must not turn that into a silent switch.
- **`_a7_relocate_kotlin_package <render> <reverse_domain>`** — wrapper step 3, applied to
  a render tree. The reverse domain is validated in Python with `re.ASCII`, before any
  directory is created. `rsync` is not a dependency of the driver, so the move uses
  `shutil`.
- **`_a7_valid_name` / `_a7_valid_version`** — one gate per kind of adopter-controlled
  value, used wherever that value becomes a path: the archetype template dir, the plan
  and the snapshot (FR-T8UFN-006/007). `_a7_main` refuses a non-SemVer `archetype_version`
  with exit 2.
- **`_a7_main`** records, in archetype mode, every path skipped because RIGHT lacks it.
  After the loop it reports them on stderr in both dry and real runs, and lists them
  `%q`-escaped under `--verbose`. It no longer writes the manifest after a conflicted run
  without `--force` (FR-UP-007). It registers every temporary tree in `_A7_CLEANUP`,
  removed by a single exit trap.

## What each archetype does after the change

Fresh renders from the final tree, then a real upgrade (evidence P-10):

| project | mode before | mode after | result after | manifest after |
|---|---|---|---|---|
| `mobile-pwa-first` | archetype | archetype | exit 0, 10 unchanged, **0 skipped** (was 9 / 1) | stamped 2.0.1 |
| `full-stack-monorepo` 2.0.0 | archetype (**accidental**) | framework | exit 8, 548 unchanged, 8 conflicts, as before `473cd36` | left at 2.0.0 |
| `ai-native-rag` | framework | framework | exit 8, 326 preserved / 230 conflicted (unchanged) | left at 1.0.0 (was stamped) |
| `event-driven-eu` | framework | framework | exit 8, 395 / 161 (unchanged) | left at 1.0.0 (was stamped) |
| `default` | n/a | n/a | no `scaffold-manifest.yaml`: exit 2 before any mode logic | — |

The flagship row does not claim to fix the flagship's upgrade. It removes a false success
and brings back a true failure, which `t8-upgrade-archetype-surface` Q-005 already covers.

## Verification

1. **L1, hermetic.** A synthetic flagship project is NOT detected, in 2.0.0 and 1.0.0,
   with three declarations: a byte copy of the root file, an edited copy, and a synthetic
   one. A positive control in the same cell must still detect `mobile-pwa-first`. A
   detector that compares content fails this cell.
2. **L1, hermetic.** `_a7_render_archetype mobile-pwa-first` produces
   `…/kotlin/io/forge/q7/PlayIntegrityService.kt`, and no rendered path name contains
   `{{`. A static cell over **every** scaffold plan checks that a placeholder can only
   appear in the relocated Kotlin directory. `_a7_relocate_kotlin_package` accepts a valid
   domain and refuses non-ASCII, `/`, `..` and newline, creating nothing when it refuses.
3. **L1, hermetic.** A synthetic `mobile-pwa-first` project declares two paths the render
   cannot produce, one of them named with an ESC sequence. The report line appears with
   the right count in a dry run and in a real run. The real run is not refused (rc 0).
   `--verbose` lists exactly those two paths, with no raw ESC.
4. **L1, hermetic.** An unreadable plan is reported. A readable plan without the
   declaration is silent. Non-SemVer versions are refused with exit 2. A tarball planted at
   the end of an invalid archetype name is never read as BASE. A conflicted run leaves the
   manifest untouched, and the same run with `--force` records it. An archetype-mode run
   leaves nothing in a private `TMPDIR`.
5. **LIVE (`FORGE_A7_LIVE=1`).** The `mobile-pwa-first` end-to-end cell requires the
   rendered `PlayIntegrityService.kt` to exist and `files skipped: 0`. The flagship cell
   renders with the real wrapper (it needs git, Flutter, cargo and buf, and once opted in,
   a missing tool fails the cell). It runs a real upgrade and requires 0 skipped, at least
   100 compared paths, and a manifest left at 2.0.0 whenever the run did not succeed.
6. The full `a7` suite, then the full `forge-ci` harness array, the gates and shellcheck.
