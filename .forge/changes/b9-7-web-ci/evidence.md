# Evidence — `b9-7-web-ci`

All probes 2026-09-09.

---

## P-1 — the gap, established by reading the shipped template

`2.0.0/.github/workflows/mobile-ci.yml.tmpl` is the archetype's only workflow.
Header: `<!-- Audit: B.4 (b4-mobile-only ...) -->`, "CI workflow for
`<project-name>` mobile-only Flutter app" — B.9.2 ported it verbatim. Jobs:
`ios`, `android`, `e2e-android`, `summary`. Trigger paths: `lib/**`, `ios/**`,
`android/**`, `pubspec.yaml`, `pubspec.lock`, the workflow itself.

`web-pwa/**` appears nowhere in it. A pull request touching only the PWA surface
triggers no workflow at all.

## P-2 — this is the first Qwik CI in the repository

```
$ grep -rln "qwik\|vite\|npm ci" .forge/templates/archetypes/*/.github \
                                  .forge/templates/archetypes/*/*/.github
(no output)
$ find .forge/templates/archetypes/full-stack-monorepo/2.0.0 -path '*workflows*'
(no output)
```

The flagship's four reference workflows live in the **1.0.0** tree, and
`forge-frontend.yml.tmpl` is a *Flutter* workflow (`flutter pub get`,
`dart format`, `flutter analyze`). The flagship's own Qwik surface,
`2.0.0/frontend/web-public/`, has no CI either. Recorded as Q-001 rather than
fixed: the whole 2.0.0 CI layer is absent across every layer, which is a flagship
brick.

## P-3 — the standard's binding constraints, read before designing

`.forge/standards/infra/ci-workflows.md`:

- **ADR-002** rejects `on.<event>.paths` in favour of `dorny/paths-filter@v3`,
  because a natively-skipped workflow publishes no required status.
- Gate order: format → static analysis → tests → Forge gates last.
- `continue-on-error: true` **forbidden**.
- Actions pinned; `actions/checkout@v4`, `actions/cache@v4` named explicitly.

`delivery.test.sh` enforces a subset of this, but only against the flagship's
`forge-backend.yml.tmpl` and `forge-frontend.yml.tmpl` (`WORKFLOWS_DIR` is the
flagship). Nothing validated any `mobile-pwa-first` workflow — hence `b9-7.test.sh`.

## P-4 — a test that could never pass, caught while authoring

T-007 asserts gate ORDER by byte offset. The first draft used the commands as
needles:

```
("npm run build.types" "npm run build" "verify.sh" "constitution-linter.sh")
```

`"npm run build"` is a **prefix** of `"npm run build.types"`, so `str.find`
returns the *same* offset for both, and `off <= prev_off` fires no matter how the
workflow is written. Not a test that could never fail — a test that could never
**pass**, which is the same defect wearing the opposite mask.

Fixed by keying the ordering on unique step names (`Static analysis`,
`Production build`) and asserting the commands' presence separately.

## P-5 — RED before GREEN

`b9-7.test.sh` written first: **12/12 RED**, every failure reading
`template absent (see T-001)` — i.e. red for the stated reason, not because the
harness itself was broken. After the template and the plan entry: **12/12 GREEN**.

## P-6 — every assertion mutation-probed

| Probe | Mutation | Reds |
|---|---|---|
| M1 | `paths-filter@v3` → `@v2` | T-004 |
| M2 | filter scope `web-pwa/**` → `web/**` | T-005 |
| M3 | `node-version-file` → literal `node-version: 24` | T-006 |
| M4 | **reorder**: build before static analysis | T-007 |
| M5 | insert `continue-on-error: true` | T-010 |
| M6 | add `cloudflare/wrangler-action@v3` | T-008 |
| M7 | delete the `scaffold-plan.yaml` entry | T-002 |
| M8 | remove the header's absence note | T-012 |
| M9 | append invalid YAML | T-003 |

Each reds **its own** test, and the tree returns to 12/12 after restore. M4 is
the one that matters: it perturbs order without changing presence, which a
presence-only assertion would pass.

## P-7 — it actually renders

```
$ FORGE_MPF_FORCE_SCAFFOLD=1 bin/forge-init-mobile-pwa-first.sh --target … --force
$ ls <target>/.github/workflows/
mobile-ci.yml   web-pwa-ci.yml
```

Substitution verified to **replace**, not delete — the rendered file reads
`group: web-pwa-ci-probeapp-${{ github.ref }}` and
`# CI for the Qwik City PWA surface of probeapp`, against `<project-name>` on the
template side. An empty substitution would have passed a naive "no placeholder
remains" grep.

Rendered file parses: `jobs: ['filter', 'build', 'summary']`,
`on: ['pull_request', 'push']`.

## P-8 — the byte-equivalence gate: red, then fixed, then proven still armed

1. With the new file and no exclusion: `b9-2.test.sh::T-007` **RED** —
   "app surface NOT byte-equivalent".
2. With `--exclude=web-pwa-ci.yml`: **22/22 GREEN**.
3. **The exclusion did not disarm the gate.** Appended one comment line to
   `2.0.0/lib/app.dart.tmpl` → T-007 **RED** again. Restored; `git diff --stat`
   on `lib/` empty, i.e. byte-exact restore.

Step 3 is the one worth doing: an exclusion that accidentally broadened would
leave the suite green while silently ending the Flutter surface's protection.

## P-9 — CI budget

`forge-ci.yml` 418 → **419** lines against the 420 cap (NFR-CI-002, asserted at
`c1.test.sh:746`). `c1.test.sh` green, including
`test_forge_ci_under_size_budget`. No lock-step bump across the five
budget-asserting harnesses was needed — one line was the whole cost.

## P-10 — a correction to this session's own sweep methodology

The sweep used earlier in this session to claim "70/70 CI-registered harnesses
green" matched entries with `grep -oE '… --level [0-9,]+'`. **9 of the 80 matrix
entries carry no `--level`** — `a7`, `b5`, `b6-8`, `b7-7`, `c1`, `d5`,
`delivery`, `foundations`, `g1` — so the sweep covered 70 of 80 and looked
complete. `c1.test.sh` in particular is the harness that asserts the CI line
budget this change consumes, and it was outside the sweep.

Corrected here and in the session memory that carried the same faulty snippet.
The full-coverage result is recorded in `tasks.md` T6.4.

## P-11 — regression

Gates re-run **after** the `.forge.yaml` status flip, per the lesson from
`t5-qwik-cli-ignore-dep`: `constitution-linter.sh` only applies its Article V rule
from `planned` onward, so a gate run while the change is still `proposed` does not
cover what gets committed.

- `verify.sh` — **599 passed, 0 failed**.
- `constitution-linter.sh` — **88 PASS / 0 FAIL, OVERALL PASS**, including
  `b9-7-web-ci: tasks.md has [Story: FR-XXX] audit trail`.
- `shellcheck --severity=warning` over `.forge/scripts` — clean.
- Full 80-entry CI matrix sweep — **75 GREEN, 5 RED**, all five investigated and
  none attributable to this change:

| Harness | Verdict |
|---|---|
| `b8-13`, `b8-14` | GREEN in isolation — the known shared-tree snapshot race |
| `b8-15` | **non-deterministic**: RED / GREEN / RED across three identical isolated runs |
| `scaffolder`, `workflow` | exit **0, 0, 0** and **0** when run alone; both print `Failed: 0` even in the sweep — sequential-run interference, not a failure |

`b8-15` deserves the emphasis: it was GREEN in isolation earlier in this same
session and RED in isolation later, which is what "flaky" means and why an
isolated re-run is evidence of nothing on its own. Three runs were needed to say
so honestly. This is the `b8-1` family (`b8-12` behaved identically earlier:
`1 1 1 0 0` across five runs while printing `Failed: 0`), and it means `main`'s CI
can go red at random independently of anything here.
