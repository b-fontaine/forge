# Evidence — `b8-10b-migrate-render`

All probes 2026-09-09.

---

## P-1 — the defect, reproduced end to end

Rendered a real `full-stack-monorepo / 1.0.0` project via `bin/forge-init-fsm.sh`,
`git init`-ed it, and ran the migration as an adopter would:

```
$ bash bin/forge-migrate-flagship.sh --target <adopter> --force
migrate exit=0
[Phase 2] overlay summary: unchanged=0 upgraded=36 preserved=0 conflicted=0
```

| | before |
|---|---|
| raw `.tmpl` files in the adopter tree | **36** |
| still carrying `<project-name>` / `<reverse-domain>` / `<root-module>` | **24** |
| sitting beside an already-rendered file of the same name | **9** |

`README.md.tmpl:3` was literally `# <project-name>`.

## P-2 — root cause, three lines

- `:48` `TPL_20=…/full-stack-monorepo/2.0.0` — merge RIGHT is the raw template tree.
- `:227-230` `_b810_map_relpath` strips the `2.0.0/` prefix and nothing else.
- `:263`, `:290` plain `cp`.

`grep -c 'tmpl\|substitut\|placeholder'` over the script → **0**.

## P-3 — an omission, not a deferral

`ADR-B810-001` carries a dedicated "Path-mapping note" explaining the prefix strip
and the schema layer paths, and never mentions the extension or the placeholders.
`b8-10-migrate-flagship/evidence.md:62-69` lists the sources *with* their `.tmpl`
extensions. Contrast B.8.14, which recorded its equivalent fresh-init decision
explicitly in `scaffold-plan-2.0.0.yaml`'s header — there is no such record here.

## P-4 — why five weeks of green CI missed it

`b8-10.test.sh` was 12 L1 + 1 L2. The L1 tests inspect the *script*; the single
live test is `_test_b810_l2_001_live_dry_run` — a `--dry-run`, which by
construction produces no files. **Nothing had ever inspected the output.**

## P-5 — feasibility of the chosen fix, established before designing on it

```
$ overlay.sh --target <tmp> --project-name probeapp --reverse-domain com.p.x \
             --plan _probe-plan.yaml
exit=0 ; 2 templates rendered
$ find <tmp> -type f
.forge/scaffold-manifest.yaml
frontend/web-public/package.json
frontend/web-public/README.md
$ grep -n probeapp <tmp>/frontend/web-public/README.md
3:# Qwik web-public surface for `probeapp` (2.0.0 candidate)
```

Three facts: a `templates:`-only plan is accepted; output is already in adopter
layout (so the relpath mapper is retired, not patched); and `overlay.sh` writes its
own manifest into the render dir.

## P-6 — the manifest exclusion, and a probe that proved nothing

The design claimed excluding `overlay.sh`'s temp manifest preserved *idempotence*.
**Wrong on both counts, and the probe meant to confirm it is what showed so.**

First probe: migrate a freshly-rendered tree with the exclusion removed → manifest
looked fine. A passing probe that established nothing, because a fresh tree has no
history to lose and the rendered manifest repeats the adopter's own
`project_name` / `reverse_domain` / `root_module` (they were read from it to drive
the render). Only `upgrade_history`, `scaffold_date` and `tools` differ.

Re-probed on a target seeded with a prior `upgrade_history` sentinel:

| | prior history after migration |
|---|---|
| exclusion present (shipped) | **preserved** |
| exclusion removed | **destroyed** |

So the exclusion prevents **data loss**, not non-convergence. Convergence was never
the exposure: a second full run is refused by the preflight
(`archetype_version: 1.0.0` required; the first run sets `2.0.0`), and
`docs/MIGRATIONS.md:76-81` scopes its idempotence claim to Phase 1 alone.
`specs.md` NFR-B810B-003 and `design.md` were rewritten to say the measured thing.

## P-7 — after the fix, on the same real tree

```
[Phase 2] overlay summary: unchanged=0 upgraded=35 preserved=0 conflicted=1
```

| | before | after |
|---|---|---|
| raw `.tmpl` | 36 | **0** |
| shadowing an existing file | 9 | **0** |
| placeholder-bearing files in the tree | 23 *(pre-migration baseline)* | **22** |

The placeholder row needs its baseline stated or it misleads: a *fresh 1.0.0 render*
already contains 23 such files — framework assets (`docs/*.md`, harnesses,
`overlay.sh`) that legitimately document placeholders. The migration now **removes**
one and adds none. The earlier "24" figure counted only files the migration itself
wrote.

`frontend/web-public/` arrives rendered:
`README.md:3` → ``# Qwik web-public surface for `aft` (2.0.0 candidate)``.

The single conflict is `CLAUDE.md` — one of the nine formerly-shadowed files, now
entering the real 3-way merge exactly as ADR-B810B-002 predicted. Recorded in
`.merge-conflicts` with markers in the file.

## P-8 — the refusal path

Manifest missing `project_name` → **exit 7**, message naming the key:

```
preflight: manifest-incomplete: …/scaffold-manifest.yaml has no 'project_name'.
The 2.0.0 overlay is RENDERED through overlay.sh and that key supplies a
placeholder value; migrating without it would write unsubstituted templates …
```

## P-9 — every assertion mutation-probed

`T-013` (real output, L1 synthetic):

| Probe | Mutation | Reds |
|---|---|---|
| M1 | re-`cp` one raw `.tmpl` after the render | "1 raw .tmpl file" |
| M2 | one plan entry set to `substitute: false` | placeholder assertion |
| M3 | one plan `target:` keeps the `.tmpl` suffix | `.tmpl` + shadowing |

M2's first attempt was a **bad probe**: it changed the substituted *value*, which
still substitutes, so no placeholder remained and nothing red. Replaced with
`substitute: false`, which leaves a real placeholder.

`T-014` (plan ↔ tree, both directions): removing an entry → "1 tracked 2.0.0 file
absent from the migration plan"; adding a bogus entry → "1 plan entry points at a
source that does not exist".

`T-L2-002` (real render): dropping `web-public/package.json` from the plan →
"frontend/web-public/package.json absent — the surface docs/MIGRATIONS.md promises
did not arrive rendered". Confirmed to *execute* rather than skip (flutter and cargo
present, `FORGE_B8_10_LIVE=1`).

## P-10 — a 37th file that was mine

The plan generator asserted 36 tracked files and got **37**. The extra was
`2.0.0/.omc/state/sessions/<id>/pre-tool-advisory-throttle.json` — OMC runtime state
written into the template tree because an earlier command had `cd`-ed into it,
making it the working directory. Gitignored, so `git status` showed nothing.

Removed, and the generator plus `T-014` now compare against `git ls-files` rather
than a filesystem walk, so ignored runtime state cannot skew the count again. The
assertion is what caught it; a generator that trusted `find` would have written a
37-entry plan with a junk entry.

## P-11 — regression

- `verify.sh` **605 / 0**; `constitution-linter.sh` **89 PASS / 0 FAIL, OVERALL
  PASS** — both run *after* the `.forge.yaml` status flip.
- `shellcheck --severity=warning` over `.forge/scripts` and `bin` — clean.
- Targeted: `b8-10` 16/16 (14 L1 + 2 L2), `b8-2` (frozen snapshot), `b9-2`
  (`overlay.sh` byte-unchanged), `b8-14-flip` — all GREEN.
- Full 80-entry sweep: **77 GREEN / 3 RED** — `b8-14`, `scaffolder`, `workflow`.
  None attributable to this change, each checked rather than assumed:

| Harness | Isolated runs | Verdict |
|---|---|---|
| `scaffolder`, `workflow` | `0 0 0` each, and `0 0 0` on a pristine `git worktree` of HEAD | the non-determinism already recorded for `b8-12`/`b8-15` |
| `b8-14` | `0 0 1` on this tree; **`1 1 1 1` on pristine HEAD** | fails *more* without this change than with it |

  `b8-14`'s failing tests are `_test_b812_023_coupling_guards`,
  `_test_b813_018_coupling_guards` and `_test_b814_015_coupling_guards` — guards
  that invoke `b8-12`/`b8-13` as subprocesses. Those are the known shared-tree-race
  harnesses, so the flakiness propagates through every coupling guard that calls
  them. That is the mechanism, and it explains why the red set differs run to run.

  The decisive counter-evidence is CI itself: the `Test harnesses` job was green on
  `5cd48b5`, which runs `b8-14` in the same matrix. A harness that were genuinely
  broken would not pass there.
