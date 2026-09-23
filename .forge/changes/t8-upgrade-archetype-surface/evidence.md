# Evidence — `t8-upgrade-archetype-surface`

2026-09-23. Every render and upgrade ran in a scratch directory outside the repository.

---

## P-1 — a freshly rendered project fails its own upgrade

`bin/forge-init-mobile-pwa-first.sh --target … --project-name q7probe --reverse-domain
io.forge.q7` (rc=0, "app (Flutter, .) + web-pwa (Qwik City)"), `git init` + commit, then
`bin/forge-upgrade.sh --target … --to-version 2.0.1 --dry-run --verbose`:

```
archetype:        mobile-pwa-first
from version:     2.0.0
files unchanged:  0
files upgraded:   0
files preserved:  507
files conflicted: 49
                                  → exit 8
```

Untouched project, produced by the same framework, and the upgrade cannot complete.
`grep -c 'pubspec.yaml'` and `grep -c 'web-pwa/package.json'` over the run log: **0 and 0**.

## P-2 — the mechanism, at the source

```
$ _a7_resolve_owned_paths "$FORGE_REPO_ROOT" | wc -l
556                      # .claude/agents/*.md, .forge/templates/**, …
$ python3 -c "…"         # the project's own declaration
project declares 10 owned paths, including: ['pubspec.yaml', 'web-pwa/package.json']
```

`bin/forge-upgrade.sh:291` passes `$FORGE_REPO_ROOT` to the resolver and `:300` takes
RIGHT from `$FORGE_REPO_ROOT/$rel`, so the driver merges Forge's own tree into a project
whose `.forge/` is a render. The 3 matches for `pubspec.yaml` inside the framework list
are `.forge/templates/**/pubspec.yaml.tmpl` — template paths, not the project's file.

The snapshot confirms the layout mismatch that ADR-T8UAS-002 turns on: 553 entries, and
the only `pubspec` in it is
`./.forge/templates/archetypes/mobile-pwa-first/2.0.0/pubspec.yaml.tmpl`.

## P-3 — why "unchanged" needs no BASE, and why BASE still matters

`_a7_classify` with an empty BASE returns `unchanged` when LEFT equals RIGHT. So a correct
owned set plus a rendered RIGHT removes the phantom conflicts on their own. BASE decides
the next case: a framework bump on a file the adopter never touched is `upgraded` with a
rendered BASE, and a 2-way `conflict` without one.

## P-4 — RED, and the vacuous pass it caught first

Three L1 cells written before the driver changed. First run: two failed (`_a7_project_*`
undefined) and **one passed** — `test_framework_paths_excluded_from_archetype_surface`,
because with the function missing the surface is empty, and an empty surface contains no
framework path either. The cell was asserting nothing.

An anti-vacuity floor — require a non-empty surface *before* checking what is in it —
made it fail like its siblings. The third run: **3 RED**, which is the RED this brick
needed.

## P-5 — GREEN, on the exact scenario of P-1

Same project, same command:

```
files unchanged:  9
files upgraded:   0
files preserved:  0
files conflicted: 0
files skipped:    1
                                  → exit 0
```

`a7.test.sh` 34/34, `shellcheck --severity=warning` clean, and with `FORGE_A7_LIVE=1`
the end-to-end cell — render a real `mobile-pwa-first`, commit it, upgrade it — passes too.
(That cell failed on its first run with `FORGE_ROOT: unbound variable`: I had used the
wrong harness variable, so it had never actually executed. Fixed to `FORGE_ROOT_REAL`.)

## P-6 — mutation probes: the surface really is the project's

| probe | rc | unchanged | conflicted |
|---|---|---|---|
| baseline | 0 | 9 | 0 |
| the framework moves a declared path | **8** | 8 | **1** |
| the adopter edits a declared path | **8** | 8 | **1** |
| the project's declaration loses one entry | 0 | **8** | 0 |
| restored | 0 | 9 | 0 |

Row 2 is the point of the brick: a framework change to a declared path is now *seen* by an
existing project, which is what "framework-owned" was supposed to mean. Row 3 shows an
adopter edit is reported rather than silently clobbered. Row 4 shows the project's own
declaration — not the framework's — drives the surface. Every file restored
byte-identical (sha256).

Under the 2-way fallback that today's snapshots force, rows 2 and 3 are both `conflict`.
Telling them apart — `upgraded` versus `preserved` — is exactly what the snapshot-rendered
BASE buys, and exactly what cannot be exercised until the snapshots carry their dotfiles.

## P-7 — why BASE cannot run today, measured

```
$ ls .forge/templates/archetypes/mobile-pwa-first/2.0.0/.envrc.example      → present
$ tar -tzf .forge/scaffold-snapshots/mobile-pwa-first/2.0.0.tar.gz | grep -c '…/.envrc.example'
0
$ dotfiles in that archetype: repository 9 · snapshot 0
```

`_a7_render_archetype` against the extracted snapshot aborts on the first missing dotfile
(`FileNotFoundError: …/2.0.0/.envrc.example`), so the upgrade takes the documented 2-way
fallback and says so in `--verbose`. The cause is the snapshot builder's
`glob.glob(pattern, recursive=True)`, which never matches a leading dot. Recorded as
Q-001; not fixed here, because rebuilding snapshots changes what `forge upgrade` recovers
as BASE for every existing adopter and is its own brick.

## P-8 — the repository's own guard caught me

The first full replay was 81/82. The red was `foundations.test.sh ::
test_no_find_piped_into_grep_q`, and the offender was this brick's new cell:

```
if find "$out" -name '*.tmpl' -type f | grep -q .; then
```

`find … | grep -q` lets grep exit on the first match and SIGPIPE the find, so the branch
can be missed — the pipefail race this repository has paid for repeatedly, with a
standing rule and a harness enforcing it. Rewritten as
`grep -q . < <(find …)`; `foundations` 25/25, `a7` 34/34, shellcheck clean.

Worth recording rather than quietly fixing: I wrote the exact defect the project has a
guard for, in a brick whose own review lane is told to look for it.

## P-9 — regression (T6.1)

After the fix: all **82** harness entries from `forge-ci.yml` PASS, `verify.sh` RESULT:
PASS, `constitution-linter.sh` 106 PASS / 0 FAIL, `forge-ci.yml` 421 lines unchanged
(NFR-T8UAS-002). Re-verified on the committed tree in P-10.

## P-10 — regression on the committed tree

On commit `9a902a5` (clean tree): `npm run bundle`, then all **82** harness entries —
**82/82 PASS**. `verify.sh` RESULT: PASS. `constitution-linter.sh` 106 PASS / 0 FAIL.
Unlike the two preceding bricks this one needed no uncommitted-tree allowance: it touches
no archetype template, so `b7-7`, `b6-8` and the `b8-12..15` chain were green throughout.
