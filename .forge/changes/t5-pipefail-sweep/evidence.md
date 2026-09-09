# Evidence — `t5-pipefail-sweep`

All probes 2026-09-09.

---

## P-1 — the risk curve: lines, not bytes

An early byte-size probe showed **0 failures / 200 at 256 KB** and nearly retired the
whole investigation. The stream had no newlines, so `grep` had to read to EOF to
delimit a line and never exited early. Re-run with newlines:

| lines after an early match | bytes | non-zero exits / 200 |
|---|---|---|
| 100 | 3.6 KB | 0 |
| 1 000 | 36 KB | **99** |
| 5 000 | 180 KB | **200** |
| 20 000 | 720 KB | **200** |

The driver is **how many lines remain when the reader exits**, and it saturates at
100 %. "The streams are too small" — the reasoning that classified these as latent —
was measuring the wrong quantity.

## P-2 — `find | grep -q .` is always wrong, not flaky

```
$ find .forge/templates -type f | grep -q .     # set -o pipefail
  200 non-zero / 200
```

## P-3 — and it silently breaks the constitution linter on real projects

`constitution-linter.sh:597` guards an Article XI check with
`if find "$FORGE_ROOT/lib" "$FORGE_ROOT/src" -type f -name '*.schema.json' | grep -q .`.

Built a tree with **3 000** matching files and ran that exact expression:

```
  files present: 3000 — branch TAKEN 0/50, MISSED 50/50
```

`has_schema` stays 0 with 3 000 schemas present. In the Forge repo `lib/` and `src/`
do not exist, so the branch is correctly false and nothing shows — the defect only
appears in a scaffolded project, which is the one place the linter is meant to run.

## P-4 — inventory

| | count |
|---|---|
| pipe-into-reader sites in `.forge/scripts` | 407 |
| reader exits early | 316 |
| status-consuming under `pipefail` | 247 across 60 files |

Writers: `printf` 122, `head` 37, `echo` 29, `grep` 26, `find` 11, rest one-offs.

## P-5 — the transform broke things twice before it worked

Recorded because it is the argument for not converting everything.

**First draft** — greedy reader pattern swallowed `; then`:

```
  if grep -q .; then < <(find …)          # invalid shell, nonsense semantics
  last_from=$(tail -1) < <(grep '^FROM' "$df")
```

**Second draft** — correct on single lines, but orphaned a `||` continuation:

```
  b9-1.test.sh:343: syntax error near unexpected token `||'
```

Fixed by refusing any line ending in `\` or followed by a line opening with
`||`/`&&`/`|`. Two independent classes of breakage on the first two attempts, across
60 files that cannot be hand-verified, is why the final transform converts only
unambiguous shapes and leaves the rest listed (ADR-T5PFS-001).

## P-6 — what was converted

| | count |
|---|---|
| automatic (here-string / process substitution) | **107** across 43 files |
| hand-converted multi-line `find … \| grep -q . \\` | **5** |
| **total** | **112** |
| left in place, listed in `skipped.json` | 176 |

`bash -n` on every touched file: **0 syntax errors**.

Proven-broken shape remaining anywhere in `.forge/scripts`: **0**
(`grep -rnE '(find|grep\s+-r)[^|]*\|\s*grep\s+-\w*q'` → no hits outside comments).

The five hand-converted sites all asserted *presence* —
`find … | grep -q . || { echo FAIL; }` — so on a large tree they would have failed
permanently, not intermittently.

## P-7 — the guard

`foundations.test.sh::test_no_find_piped_into_grep_q`, scoped to the measured-100 %
shape rather than to every pipe (ADR-T5PFS-002). Mutation-probed: reintroducing the
piped form at `b9-3.test.sh:160` reds it with
`a find/grep -r is piped into grep -q — that branch can never be taken`.

## P-8 — two harnesses went red, and it was not the sweep

The first post-sweep run reported `b8-11` and `b8-obi` red.

`b8-11::_test_b811_013_no_new_bash_in_linter` asserts `git diff HEAD` shows no
non-comment additions to `constitution-linter.sh`. The sweep legitimately edits that
file, so the guard fires on the **uncommitted working tree**. Verified rather than
assumed: after committing, both are GREEN. `b8-obi` showed no failing test — the
coupling-chain signature again.

Worth noting as a property of that guard: it will fire for anyone who edits the
linter until they commit, which is a working-tree assertion wearing the shape of an
invariant.

## P-9 — regression

See `tasks.md` T5.
