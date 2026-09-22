# Evidence — `t8-example-tree-pins`

2026-09-16. node v26.8.1 / npm 12.0.2 (the surfaces pin node 24 in `.nvmrc`; same caveat
as `t7-qwik-deps-refresh` Q-003). Every npm command ran in a scratch dir outside the repo.

---

## P-1 — the drift set, measured before deciding the fix

Rendered all eleven `ai-native-rag/1.0.0/frontend/web-public/*.tmpl` with
`<project-name>` → `forge-rag-example` and diffed against the committed example:

```
DRIFT: ./package.json
DRIFT: ./README.md
DRIFT: ./vite.config.ts
(no file missing in the example, no extra file)
```

So the subtree re-render IS the three-file change — which is what lets the fix keep
`examples/README.md`'s "committed verbatim" claim true.

Scope of that statement, stated precisely: it covers the eleven `web-public` templates.
A whole-tree render also differs in: `.forge/scaffold-manifest.yaml` (a birth record, see
Q-002); the root `README.md` (hand-written navigation the example deliberately keeps); and
`shared/protos/buf.yaml` + `shared/protos/buf.gen.yaml`, which still carry unsubstituted
`<project-name>` placeholders — those two are defects, not carve-outs, and are inventoried
in Q-003 for whoever writes the parity guard.

## P-1b — there is no fifth Qwik surface

```
$ git ls-files | grep -E '(^|/)package\.json(\.tmpl)?$'      -> 6 tracked manifests
$ ... of those, containing '"@builder.io/qwik'                 -> 4
    .forge/templates/archetypes/ai-native-rag/1.0.0/frontend/web-public/package.json.tmpl
    .forge/templates/archetypes/full-stack-monorepo/2.0.0/frontend/web-public/package.json.tmpl
    .forge/templates/archetypes/mobile-pwa-first/2.0.0/web-pwa/package.json.tmpl
    examples/forge-rag-example/frontend/web-public/package.json
```

The three templates were already correct; the example was the only one left. `cli/package.json`
and `examples/forge-fsm-example/clients/package.json` are not Qwik surfaces, and
`examples/forge-eda-example` has no npm manifest at all. So "every Qwik surface" is now a
claim with a measured denominator rather than a hope.

## P-2 — why two sweeps missed it

Both guards discovered surfaces with `find "$FORGE_ROOT/.forge/templates" -name
'package.json.tmpl'`. The example manifest is `examples/forge-rag-example/frontend/
web-public/package.json`: wrong root, wrong name. `t5-qwik-cli-ignore-dep` (2026-09-09)
and both passes of `t7-qwik-deps-refresh` (2026-09-13/14) each swept "every Qwik surface"
and could not have seen it.

## P-3 — RED, guard half first

Widened discovery applied with the example still unfixed — `b8-9` **12/14**, five
failures, each naming the file:

```
FAIL T-013: examples/forge-rag-example/frontend/web-public/package.json declares
            @builder.io/qwik but not 'ignore' — its 'npm run build' is dead
FAIL T-014: .../package.json overrides.sharp is None; web-frontend.yaml requires '^0.35.4'
FAIL T-014: .../package.json vite is '=7.3.5'; web-frontend.yaml pins '=7.3.6' exactly
FAIL T-014: .../README.md `vite` Pin cell is '`=7.3.5` (EXACT)'; …says `=7.3.6`
FAIL T-014: .../README.md pin table has 0 `sharp` rows, expected exactly 1
```

## P-4 — GREEN

Three rendered files written → `b8-9` **14/14**; `git diff --stat` on `examples/` shows
exactly those three files.

## P-5 — the fixed example resolves clean

Manifest copied to a scratch dir, `npm install --package-lock-only`:

```
sharp@0.35.4 · vite@7.3.6 · ignore@7.0.9
npm audit --audit-level=high  -> exit 0
npm audit                      -> found 0 vulnerabilities
```

## P-6 — mutation probes on the new paths

| probe | result |
|---|---|
| example `vite` pin reverted to `=7.3.5` | RED, names the example manifest |
| example `overrides.sharp` removed | RED |
| example `ignore` devDependency dropped | RED (T-013) |
| example README `sharp` row deleted | RED |
| example manifest stops declaring Qwik → `examples/` matches nothing | RED via the **scoped floor** (`discovered ZERO Qwik surfaces under examples/`) |
| a Qwik manifest planted under `examples/**/node_modules/` | **GREEN** — correctly not discovered |

6/6 as intended, every file restored byte-identical (sha256), the planted
`node_modules` removed, `b8-9` 14/14 after.

## P-7 — regression

On commit `ac53ab7` (clean tree): `npm run bundle`, then all **82** harness entries parsed
from `forge-ci.yml` — **82/82 PASS**. `verify.sh` RESULT: PASS. `constitution-linter.sh`
104 PASS / 0 FAIL, OVERALL PASS. `forge-ci.yml` 421 lines, unchanged (NFR-T8ETP-001).
`b7-7`'s no-uncommitted-template-edit guard is green throughout: this brick touches no
`ai-native-rag` template file.

## P-8 — review round 1 (2026-09-17): the floor counted the wrong thing

An independent guard lane returned **CHANGES REQUIRED** on one major finding, reproduced
end-to-end by the reviewer before I touched anything:

> T-014's scoped `examples/` floor counted **discovered** files, not **checked** surfaces.

The two halves did not line up. Discovery is a shell grep for the needle
`"@builder.io/qwik`; the python loop then skips, with a non-fatal NOTE, any manifest that
does not actually declare a Qwik package in `dependencies`/`devDependencies`. The floor
sat on the first count. And the needle is reachable in prose — the example's own `_audit`
block, line 8, reads:

```
"@builder.io/qwik peerDependencies '>=5 <8' (see README PITFALL).",
```

So a future restructure (npm workspaces hoisting the pins to an outer manifest is the
natural one) would leave that prose behind, keep the floor satisfied, and stop
pin-checking the examples — the exact blind spot this brick exists to close, hidden
behind a floor reporting itself green.

**Partly fixed in round 1** by moving the floor to where the counting is real: python
tracks `checked_examples`, incremented only after the declares-Qwik filter, and fails when
it is zero. That closed the hole *as reported* — but see P-9: the npm-workspaces variant
named just above was **still green** after it, and this paragraph originally claimed
otherwise. The shell-side floor for T-014 is gone, replaced by a comment saying why it cannot
live there. `T-013` keeps its shell floor: its loop checks every discovered surface and
its needle is the exact `"@builder.io/qwik"` (closing quote included), which the prose
line does **not** match — verified, `grep -c` = 1 for the prose-free form.

**Probe 7**, the reviewer's scenario, run against the fixed guard:

| probe | before the fix | after |
|---|---|---|
| Qwik dropped from both dependency maps, `_audit` prose kept, `overrides` deleted, `vite` reverted | GREEN | **RED** |

```
NOTE T-014: examples/.../package.json mentions @builder.io/qwik but declares neither
            package in dependencies/devDependencies — not checked
FAIL T-014: no surface under examples/ was pin-checked — the shipped reference renders
            are out of the sweep again (FR-T8ETP-004)
```

The six earlier probes still behave (5 RED, `node_modules` still correctly ignored),
`b8-9` 14/14, `shellcheck --severity=warning` clean, file restored byte-identical.

**Cleared by the same lane, each re-measured rather than assumed:** the `node_modules`
exclusion holds at any depth (manifests planted at three depths, none discovered); a
30 000-file `node_modules` adds ~30 ms, no L1 budget risk; `cli/assets/examples` is
correctly *not* swept (gitignored, rebuilt from `examples/` by the bundler, so sweeping it
would false-fail on a stale local bundle); a deeply nested new example surface **is**
discovered and reported by full path; `examples/` absent fires both floors, and no
consumer path produces a tree with `.forge/scripts/tests` but no `examples/`; the helper
survives an empty array, spaces and glob metacharacters in `FORGE_ROOT`, and does not
over-match a sibling `examples-old/`; no `pipefail` + `grep -q` race (every grep reads a
file argument); the README sibling derivation cannot cross-contaminate the two roots.

**Noted, not changed:** T-013's exact needle and T-014's prefix needle disagree on a
qwik-city-only surface. T-013 would then fire its floor while T-014 checks the tree
fine — implausible (the `ignore` workaround T-013 guards exists only because of the
`@builder.io/qwik` CLI) and it fails safe, red rather than green.

## P-9 — review round 2 (2026-09-22): the motivating scenario was still green

A fresh lane re-attacked the round-1 fix and reproduced two escapes. Both are now closed;
both were GREEN before.

**(a) The npm-workspaces hoist — the very restructure P-8 names as the motivation.**
Plant `examples/forge-rag-example/package.json` as a workspace root declaring the Qwik
packages and correct pins; let the inner `frontend/web-public/package.json` keep its
`_audit` prose but declare neither package, drop `overrides` and drift to `vite =7.3.5`.
The outer manifest alone satisfied `checked_examples`, while the inner surface — the one
npm actually installs from, and npm honours its per-workspace exact range — was skipped
with a non-fatal NOTE. Guard green, shipped render on the vulnerable pin.

*Fix:* under `examples/`, "mentions the needle but declares neither package" is now
**FAIL**, not NOTE. A shipped render must declare what it installs, which is
ADR-T8ETP-001's stated consequence: such a case fails and gets argued about.

**(b) The README half had only a global floor.** With the manifest byte-correct, the
example README could lose its whole pin table — or be renamed away — and stay green,
because the three template siblings keep `readme_rows` positive.

*Fix:* a checked surface under `examples/` must have a sibling README, and that README
must expose a pin table. Both are FAIL, each naming the file.

| probe | round 1 | round 2 |
|---|---|---|
| npm-workspaces hoist, inner surface drifts | GREEN | **RED** (inner manifest, and the outer README having no pin table) |
| example README pin table stripped entirely | GREEN | **RED** |
| example README renamed away | GREEN | **RED** |

All ten probes now behave (P-6's six, P-8's one, these three), baseline `b8-9` 14/14,
`shellcheck --severity=warning` clean, every file restored byte-identical.

**Cleared by the same lane, re-measured not assumed:** `rel` is always repo-relative and
the `else path` fallback is unreachable (checked live through a symlinked repo root); a
symlinked `examples/` fails safe (find does not descend a symlink argument, both floors
fire); no early `continue` sits between the counter and the pin comparisons; T-013's
retained shell floor is sound because its needle is the exact quoted form, which no prose
in the repo matches; and no legitimate tree produces a false RED.


## P-10 — the F.1 discovery tool was silent on the whole repository

Raised by the round-2 claims lane as "the Q-004 Resolution block omits the mandated
fields". Reshaping it to the schema led to the larger fact:

```
$ bash bin/forge-questions.sh          # lists every Status: open question
(no output)
```

Zero lines, repository-wide, while dozens of real open questions exist. The awk parser
(`bin/forge-questions.sh:73,80,83,86`) requires `^## Q-NNN: ` plus `- **Raised on**:` and
`- **Raised by**:` — exactly what `global/open-questions.md § Question Schema` prescribes.
Nearly every `open-questions.md` under `.forge/changes/` writes `## Q-NNN — title` with an
em dash and omits both `Raised` fields, so none of them is visible to the tool that exists
to find them.

This brick's own file was written to the schema, and `t7-qwik-deps-refresh` Q-004's
Resolution block now carries the five mandated fields. After that:

```
$ bash bin/forge-questions.sh
t8-example-tree-pins:Q-001  No guard checks that an example still matches the template …
…six questions listed…
```

Converting the other changes is a separate brick; the real fix is a guard, because
`verify.sh`'s Open Questions Gate counts `Status: open` without ever checking that a
question is parseable. Recorded as Q-006.
