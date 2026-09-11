# Evidence — `b9-4-archetype-decision-tree`

All probes 2026-09-11.

---

## P-0 — the audit was adversarial, and it earned its keep

Four independent readers mapped the matrix against the registry; every finding then
went to a skeptic prompted to refute it. **Six of nine verified findings were
refuted**, three of which I would otherwise have written into the document:

| finding | verdict |
|---|---|
| `rust-cli-tui`'s row is stale, no dispatch key, no schema | **REFUTED** — required verbatim by `FR-IW-009` (`b5-1-init-wizard/specs.md:252`) and pinned by `b5.test.sh:246-260`. Editing it turns CI red. The archetype was *never* in the dispatch table (`git show 519cb46` of that file: two keys), so nothing drifted. |
| `mobile-pwa-first` has no row — a stale-doc defect | **REFUTED on framing** — a tracked deferral to this brick, restated in four places. And no archetype has ever held a row while `stage: candidate`: `ai-native-rag` and `event-driven-eu` each got theirs after promotion. |
| `pwa.yaml` is the only accurate statement; the rule elsewhere drops the hedge | **REFUTED** — the other passages state a *routing rule*, which makes no capability claim in either direction. A conditional route is not a degraded restatement of a platform fact. |
| the PWA branch routes to a non-installable surface (icons absent) | **REFUTED** — the icons really are absent, but the "routes adopters to a broken surface day 1" premise is unreachable. |
| the iOS fallback ships no push capability | **REFUTED** — physical facts hold, framing and one grep do not. |

The second refutation is the one that changed the design: it turned "add the missing
row" into `ADR-B94-001`, which adds no row and makes the guard demand one at promotion
instead.

## P-1 — the iOS rule has no technical basis in this repository

Survived refutation. The routing rule is restated in four places —
`pwa.yaml:102-107`, `mobile-pwa-first/2.0.0.yaml:198-200` and `:150-153`,
`web-pwa/README.md.tmpl:5-8`, `web-pwa/src/routes/index.tsx.tmpl:30-33` — and
`ARCHITECTURE-TARGET.md` §6.3 conditions its native container on *« Si push critique
sur iOS »*.

No file states an iOS version floor, a home-screen-install precondition, or a named
Push API limitation. `grep -rn "installed-PWA"` returns exactly one line in the whole
repository: `pwa.yaml:77`, *"iOS support for installed-PWA push is not assumed"*. The
only external citation is `ARCHITECTURE-TARGET.md:142` — one blog URL, accessed
2026-04.

Hence `FR-B94-002`: the section documents the route and says the constraint is not
established here. Writing *"iOS cannot do Web Push"* would have invented a claim that
stopped being true at Safari 16.4.

## P-2 — the existing matrix guard, measured

`b5.test.sh`'s `test_archetypes_decision_matrix_present` loops five hardcoded names and
greps the whole file. Deleting one archetype row at a time and re-running CI's own
invocation:

```
  delete `default             ` -> b5=0 b4=0  *** DELETABLE, CI STAYS GREEN ***
  delete `full-stack-monorepo ` -> b5=0 b4=0  *** DELETABLE, CI STAYS GREEN ***
  delete `flutter-firebase    ` -> b5=1 b4=0  caught
  delete `mobile-only         ` -> b5=1 b4=1  caught
  delete `ai-native-rag       ` -> b5=0 b4=0  *** DELETABLE, CI STAYS GREEN ***
  delete `event-driven-eu     ` -> b5=0 b4=0  *** DELETABLE, CI STAYS GREEN ***
  delete `rust-cli-tui        ` -> b5=1 b4=0  caught
```

**4 of 7.** The two pinned rows other than `mobile-only` are a removed archetype and a
not-started one; the two live archetypes shipped since April are unprotected. The
correct cleanup turns CI red and real drift stays green.

After the rewrite (derived from `dispatch-table.yml`, scoped to the `## Available
archetypes` rows): **7 of 7 RED, 0 deletable.**

### P-2a — the first run of that probe was wrong

It reported `b5=2` at baseline and printed "CAUGHT" on every row. `b5.test.sh` is one of
the nine CI entries that take **no** `--level` argument, so `--level 1` was rejected
before a single test ran, and the probe was comparing two error exits. Re-run with
`forge-ci.yml`'s own invocation for each harness.

The lesson is already written down in this repo, and I walked into it anyway.

## P-3 — the forward guard, proven rather than asserted

`ADR-B94-001` claims the new guard will demand the `mobile-pwa-first` row the moment
B.9.11 promotes it. Simulated by flipping `status: candidate` → `stable` in
`dispatch-table.yml`, running, and restoring:

```
simulated B.9.11 promotion (candidate -> stable) -> b5 exit 1
    matrix has no row for `mobile-pwa-first`, which dispatch-table.yml registers as available (FR-B94-007)
dispatch-table.yml restored, sha256 matches
```

## P-4 — `flutter-firebase` does not refuse; it crashes

`docs/ARCHETYPES.md:103` lists `J8-RULE-001` as a live refusal for
`--archetype flutter-firebase`. Static check: `cli/src/domain/dispatch-table.ts:115`
returns `{ archetypes }` and never reads `forbidden_archetypes`, so the guard at
`cli/src/commands/init-archetype.ts:163` is unreachable. Measured, unpiped:

```
$ node cli/dist/index.js init ffprobe --archetype flutter-firebase --org com.example.t
bash: /home/bfontaine/github/forge/cli/assets/<removed>: Aucun fichier ou dossier de ce nom
real exit = 127
```

Not exit 3, not a `[REFUSAL: …]` line. Recorded as Q-001; the CLI fix is not this
brick's.

## P-5 — Kong and DBOS

```
kong occurrences in scaffold-plan-2.0.0.yaml : 0
kong occurrences in scaffold-plan.yaml (1.0.0): 2
DBOS occurrences under .forge/templates/     : 0
```

`roadmap.md:160-162`: *"Temporal retained as the durable-execution default (DBOS
deferred to watch-list `future-option` — no Rust SDK ; B8O 2026-06-01, ADR-B8O-001
cancels ADR-002 for Rust)"*.

## P-6 — RED before GREEN

`T-031` against the untouched document: **RED**, `no '## Choosing the mobile channel'
section`. After the section: `b9-2` **31/31**.

The `b5` rewrite is **not** a red-before-green test — the table already satisfied the
derived set, so it passed on first run. Its proof is P-2's probe, not its exit code.
Stated here because a guard-strengthening that passes immediately looks exactly like a
guard that does nothing.

`T-031`'s first GREEN run also failed, correctly: the doc said *"exits 3"* and the
needle is `exit 3`. Fixed in the document, not by weakening the needle.

## P-7 — mutation probes, and the one that failed

| probe | result |
|---|---|
| disclaimer `makes no claim about iOS capability` dropped | RED |
| `not assumed` flattened to `not supported` | RED |
| `exit 3` changed to `exit 0` | RED |
| `channel_fallback` dropped | RED |
| **`client-only` claim dropped** | **STILL GREEN** |

The needle was the bare word `client-only`, which recurs two paragraphs later in *"a
client-only archetype has none"*. Deleting the load-bearing table row left the
incidental prose mention, and the battery passed.

Narrowed to `layer_profile: client-only` (one occurrence). Re-run: **5/5 RED.**

This is the same defect three times in two days — `b9-2::T-029`, `b5`'s FR-IW-009
guard, and now inside the battery written to replace them. A substring that occurs
twice in the region is not an assertion about either occurrence.

## P-8 — negative scope

The `rust-cli-tui` row is asserted byte-identical by the transformer itself before it
writes (`assert after_rust == before_rust`). `git status` shows no file under `cli/`,
`bin/`, `.forge/templates/`, `.forge/schemas/`, `.forge/scaffolding/`, `.forge/specs/`,
and `docs/ARCHITECTURE-TARGET.md` is untouched.

## P-9 — regression

`b5` 17/0 · `b4` 48/0 · `b9-2` 31/31 · `t4` (schema-enum pin) · full 80-entry CI
matrix · `shellcheck --severity=warning` · `verify.sh` + `constitution-linter.sh`
after the status flip: `tasks.md` T6.
