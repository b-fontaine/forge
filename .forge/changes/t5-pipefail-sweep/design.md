# Design — `t5-pipefail-sweep`

## The two transforms

| writer | rewrite | why |
|---|---|---|
| `printf '%s' "$V"` / `echo "$V"` | `READER <<<"$V"` | here-string is not a pipeline, so `pipefail` cannot apply |
| a command (`find`, `grep`, `git`, …) | `READER < <(CMD)` | process substitution is not a pipeline either; `CMD` may still take SIGPIPE but its status leaves the tested expression |

Both preserve semantics exactly: identical bytes reach the reader, and the reader's
own status is what the caller tests — which is what the caller always meant. The
pipeline form only ever added a second, unwanted status into the decision.

## Why not convert all 288

Because the transform demonstrably guesses wrong, and 60 files cannot be
hand-verified.

Draft 1 — the reader pattern was greedy and swallowed the line terminator:

```
  if grep -q .; then < <(find …)
  last_from=$(tail -1) < <(grep '^FROM' "$df")
```

Draft 2 — correct on complete lines, but a pipeline whose `||` sits on the *next*
line became an orphan:

```
  b9-1.test.sh:343: syntax error near unexpected token `||'
```

Neither reached the repository: both were dry-run against copies first, which is the
single most useful decision in this change. The final transform refuses any line
ending in `\` or followed by one opening with `||`/`&&`/`|`, and refuses any writer
containing a nested substitution or a second pipe.

That leaves 176 sites. They are listed rather than converted (ADR-T5PFS-001), which
is a weaker outcome honestly stated instead of a stronger one silently assumed.

## Triage: what actually had to be fixed

The 5 hand-converted sites share one shape:

```bash
find … 2>/dev/null | grep -q . \
  || { echo "    FAIL …" >&2; ok=0; }
```

They assert **presence**. Under `pipefail` on a large tree the pipeline is always
non-zero, so the `||` branch always fires and the test **always reports FAIL**. They
pass today only because the trees they search hold a handful of files. That is a
property of the fixtures, not of the code — which is why they were converted by hand
rather than left with the other 176.

## Verification order, and why it is that order

1. `bash -n` on every touched file. Syntax first: a suite run is a slow and confusing
   way to discover a missing `fi`.
2. Full 80-entry CI matrix, **twice**, in the **committed** state.
3. `shellcheck --severity=warning` — the `Shell lint` CI job treats warnings as
   failures.
4. `verify.sh` + `constitution-linter.sh` after the status flip.

Step 2's "committed" qualifier is not incidental. The first post-sweep run reported
`b8-11` and `b8-obi` red, which looked exactly like the regression NFR-T5PFS-001
exists to catch. `_test_b811_013_no_new_bash_in_linter` asserts `git diff HEAD` shows
no non-comment additions to `constitution-linter.sh` — a **working-tree** assertion.
The sweep edits that file legitimately, so it fires until commit. Confirmed by
committing and re-running, not by reasoning about it.

## The guard

Scoped to `find`/`grep -r` piped into `grep -q` — the shape measured at 100 % failure
— rather than to every pipe. A guard covering all 288 would flag the 176 the sweep
deliberately left, become noise, and be disabled. This one asserts a measured fact and
can be defended line by line.
