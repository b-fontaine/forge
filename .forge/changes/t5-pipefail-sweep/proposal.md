# Proposal — `t5-pipefail-sweep`

`t5-helpers-sigpipe` fixed `_helpers.sh`. This sweeps the same defect out of the
harness bodies and `constitution-linter.sh`.

## It is not latent

The pattern was previously assessed as "latent rather than broken — the streams are
too small". Measured, that assessment is wrong in both directions.

**The driver is lines remaining after the match, not total bytes.** A stream with no
newlines never triggers it (grep must read to a delimiter), which is why an early
byte-size probe showed 0/200 even at 256 KB and nearly sent this investigation the
wrong way:

| lines after an early match | bytes | non-zero exits / 200 |
|---|---|---|
| 100 | 3.6 KB | 0 |
| 1 000 | 36 KB | **99** |
| 5 000 | 180 KB | **200** |
| 20 000 | 720 KB | **200** |

It saturates at **100 %**. So the shape `find <tree> | grep -q .` is not flaky — it
is **always** wrong:

```
$ find .forge/templates -type f | grep -q .     # under set -o pipefail
  200 non-zero / 200
```

`if find … | grep -q .; then` therefore **never takes its true branch** on any tree
with more than a few thousand files. The check silently reports "nothing found",
always. `constitution-linter.sh` has three of these — `:597`, `:645`, `:652` —
guarding Article XI fallback-implementation checks. In the Forge repo the searched
paths (`lib/`, `src/`, `test/`) do not exist, so the branch is correctly false and
nothing shows. In a **scaffolded project**, where they do exist and are large, the
linter would report a compliance gap that is not there.

## Inventory

Classified by whether the pipeline's exit status is consumed, since only those can
be broken:

| | count |
|---|---|
| pipe-into-reader sites in `.forge/scripts` | 407 |
| of those, reader exits early (`grep -q`, `head`, `tail`) | 316 |
| **status-consuming, under `pipefail`** | **247**, across 60 files |
| early reader but status unused (diagnostics) | 69 |

Writers, by frequency: `printf` 122, `head` 37, `echo` 29, `grep` 26, `find` 11,
the rest one-offs.

## Two transforms, chosen by writer

- **Writer is `printf` / `echo` of a shell variable** → here-string:
  `grep -q P <<<"$var"`. No pipeline, so `pipefail` cannot apply.
- **Writer is a command** (`find`, `grep`, `head`, `git`) → process substitution:
  `grep -q P < <(cmd)`. Also not a pipeline; `cmd` may still take SIGPIPE but its
  status is no longer part of the tested expression.

Both are semantics-preserving: identical bytes reach the reader, and the reader's own
exit status is what the caller tests — which is what the caller always meant.

## Why sweep rather than triage by size

Predicting stream size per site is exactly the reasoning that produced the wrong
"latent" verdict. `find .forge/templates` was small once; it is 4 000+ files now, and
crossed the 100 %-failure threshold silently. A site's safety today is not a property
worth depending on.

## Scope

**In:** the 247 status-consuming sites; a lint guard so the pattern cannot return;
the harness-authoring standard.

**Out:** the 69 diagnostic sites whose status is discarded — flagged in the guard as
warnings, not errors (`open-questions.md` Q-001). Also out: `bin/**` and `cli/**`,
which are not under `pipefail` harness conventions (Q-002).

## Negative scope

MUST NOT change any assertion's meaning. Every rewritten site must feed the reader
the same bytes and yield the same status for genuine match / non-match. The 80-entry
CI matrix must stay 80/80, verified more than once.
