# Design — `b9-10-migration-paths`

## Shape of the edit

`docs/MIGRATION-PATHS.md` today is: title, three-line preamble, a dated provenance
note, `---`, one T.5 section. 92 lines.

After:

```
title
preamble  ............................  rewritten: states the boundary (FR-B910-006)
provenance note ......................  kept verbatim, plus one line for this brick
INDEX TABLE ..........................  NEW — 3 rows (FR-B910-005)
---
## B.9 — mobile-only 1.0.0 → mobile-pwa-first 2.0.0   NEW  (FR-B910-001..004, 007, 008)
---
## T.5 — Connect codegen additive ....  BYTE-UNCHANGED (NFR-B910-004)
```

The B.9 section goes **above** T.5, not appended. The provenance note says *"future
migrations append a new section per archetype × version pair"*, which is why the file
would otherwise grow oldest-first — the reverse of what a reader landing on an index
wants. The index table makes ordering a presentation choice rather than a lookup
mechanism, so newest-first is free.

## Why the index is a table and not a list of links

The single fact a reader needs before clicking is *which of the two documents holds
the walkthrough*. A table makes that a column. It also gives the coverage guard
(FR-B910-005) something to match against: one row per driver script.

Columns: **from** · **to** · **kind** · **driver** · **walkthrough**.

`kind` is where ADR-B910-002's boundary becomes visible per row —
`same-archetype` / `cross-archetype` — including on the T.5 row, which is
same-archetype and lives here anyway. Recording the anomaly in the column is cheaper
than a footnote and harder to forget than a comment.

## The B.9 section's outline

Ordered by what an adopter needs before they run anything:

1. **Status** — `candidate` until B.9.11, and what that means for them today.
2. **Why `forge upgrade` cannot do this** — it resolves versions *within* an
   archetype. This jump changes the archetype, so there is no version to resolve.
3. **Invocation** — `--dry-run` first, then the real run.
4. **What it adds** — 26 files, grouped: `web-pwa/` (23), `oidc-provider.json`,
   `.github/workflows/web-pwa-ci.yml`, `.forge/scaffold-manifest.yaml`.
5. **What stays untouched** — the whole Flutter surface, byte-for-byte, measured.
6. **Where the substitution values come from** — and what a non-literal Gradle
   `namespace` produces (exit 7, actionable).
7. **Exit codes** — the table.
8. **After the migration** — the three manual steps the script prints, expanded.
9. **What `forge upgrade` will not do afterwards** — the `framework-owned-paths.yml`
   gap (FR-B910-007).
10. **Rollback** — by hand, because there is no flag (FR-B910-008).

## Guards

Three, hosted in `b9-2.test.sh` as `T-028`..`T-030`. Same reasoning as B.9.9's
`T-024`..`T-027`: `forge-ci.yml` is at **419/420** lines against NFR-CI-002 and B.9.11
still needs that last line to register `b9.test.sh`. A new harness now would consume
it.

| test | asserts | fails when |
|---|---|---|
| `T-028` | the B.9 section's content battery — driver name, 26/0, byte-identical-except-manifest, exit 7 + exit 8, the `candidate`/B.9.11 caveat, the owned-paths note | the section is absent, or drifts into prose that drops a fact |
| `T-029` | **coverage** — every `bin/forge-migrate-*.sh` appears in the document | a new migration script ships without an index row (the defect this brick found) |
| `T-030` | **claims track code** — every flag and every exit code the section states is present in `bin/forge-migrate-mobile-pwa.sh` | the doc describes an ABI the script does not have |

`T-029` is the one with a future: it is the only guard here that fires on work nobody
has written yet.

## Two traps this repo has already paid for

**The negative assertion that fires on its own explanation.** `T-028` greps a document
that *discusses* exit codes and file counts. Any check phrased as "this string must
not appear" would match the sentence explaining why it does not. Every `T-028` check
is therefore a **positive** presence assertion; there are no negatives in the battery.
(`b9-2::T-013`, `t6-fsm-2-0-0-wiring::P-6`.)

**`printf | grep -q` under `pipefail`.** Not used anywhere in the three guards —
here-strings and process substitution only. (`t5-helpers-sigpipe`.)

## Verification strategy

The content battery can only prove the document *says* things. What makes the facts
true is that they are transcribed from `b9-9/evidence.md` and re-probed here: the
migration is re-run end-to-end in this change's evidence, the exit codes are provoked,
and the `framework-owned-paths.yml` claim is checked by `sha256sum` on the two
templates rather than by reading them.

`T-030` closes the remaining gap: the document cannot claim a flag or an exit code the
script does not have, even if a future edit invents one.
