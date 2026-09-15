# Open questions — `t7-qwik-deps-refresh`

## Q-001 — nothing runs `npm audit` in CI

The two HIGH `sharp` advisories (npm: 3 high) were found because this brick ran `npm audit` by hand.
`b9-7`'s `web-pwa-ci.yml` runs `npm install`, static analysis and a build — no audit step —
and no shell harness can see a transitive advisory, since they never install.

`T-037` (web-pwa) and, since the extension, `b8-9::T-014` (all three templates) pin the
*known* remediation, so this specific chain cannot silently regress. They say nothing
about the next advisory.

An `npm audit --audit-level=high` step in `web-pwa-ci.yml` looked like the obvious close
and is not one: it would see `web-pwa` only. `ai-native-rag` has no CI template and the
flagship's `forge-frontend.yml` is Flutter-only, so only an audit over rendered trees in
`forge-ci` sees all three (review round 2). Wherever it runs, it is a judgement call
rather than an oversight: audit failures are time-dependent, so the
step turns an unrelated pull request red the day an advisory lands upstream. That is
arguably the point, and arguably intolerable — it belongs to whoever owns the CI policy.

Same shape as `t7-flutter-deps-refresh` Q-002: the check exists, the runner does not run
it.

## Q-002 — the override outlives its cause unless someone checks

`overrides: { "sharp": "^0.35.4" }` is correct today and becomes dead weight the moment
qwik-city ships a vite-imagetools depending on sharp ≥0.35.4 itself. The manifest says
so, and nothing enforces it.

An override that stays after its cause is gone silently pins a transitive dependency
nobody chose — the same class of problem as the `ignore` workaround, which at least
carries a documented deletion trigger and a harness (`b8-9::T-013`). A periodic
"overrides still needed?" check would cover both.

*Update 2026-09-14:* the floor now has what `ignore` has — `web-frontend.yaml`
`versions.sharp` with its removal trigger, a `P30D` `pin_review_cadence` entry, and a
harness (`b8-9::T-014`). Still nothing *checks* whether the cause is gone; the cadence
entry only makes the question due.

## Q-003 — `.nvmrc` says 24 and this machine ran node 26

Every measurement here was taken under node v26.8.1 / npm 12.0.2 while the surface pins
node 24. The results — resolution, audit, typecheck, build — are unlikely to differ, but
they were not taken on the pinned runtime and that is worth stating rather than glossing.

`web-pwa-ci.yml` uses `node-version-file: web-pwa/.nvmrc`, so CI does run 24. If these
pins misbehave there, CI is where it will show.

## Q-004 — `examples/forge-rag-example` has neither the override nor `ignore`

Out of the 2026-09-14 extension by maintainer arbitration. The example is not a
template, so `b8-9::T-013`/`T-014` never see it, and `t5-qwik-cli-ignore-dep` skipped
it too: its `frontend/web-public/package.json` resolves the same vulnerable sharp **and**
a dead qwik CLI. It ships inside the npm tarball. Fixing it also triggers the
`example` CI job. Needs a decision on whether examples follow framework pin fixes.

## Q-005 — `buf generate` fails on a fresh `ai-native-rag` render, and the wrapper blames the network

Found while proving P-10, reproduced on two renders: `rag.proto` has no `go_package`,
and `buf.gen.yaml` runs `buf.build/connectrpc/go` under `managed: enabled` with no
`go_package_prefix`. buf 1.72.0 exits 1 (`Please specify either: a "go_package" option
... or a "M" argument`) and writes nothing — so `task proto` fails deterministically.
`bin/forge-init-ai-native-rag.sh:190` reports it as "BSR network / plugin unavailable".
Not verified against older buf releases. Not this brick's.

**And CI does not catch it** (review round 1). `harness-rust` runs `b7-6 --level 1,2` with
buf installed, but T-C02 (`b7-6.test.sh:476-479`) treats any buf failure whose log matches
`network|connect|...|buf\.build|...` as offline and returns 0 — the go_package error names
`buf.build/connectrpc/go`, so it matches. Run `34815880019` printed `SKIP T-C02 ... (offline)`
while the same job's cargo leg fetched crates. T-C04 (Qwik tsc) skips unconditionally. The
roadmap's B.7 row and plan §0.12 describe that job as proving the buf → codegen → tsc chain;
it proves neither.

## Q-006 — `connect-client.ts` imports a path buf does not generate

The template imports `./generated/connect/rag_pb`; the es plugin writes
`generated/connect/v1/rag/rag_pb.ts` (the proto's own path). So even with Q-005 worked
around, `tsc --noEmit` fails with TS2307 and `vite build` cannot resolve the import: a
rendered `ai-native-rag` web-public does not typecheck or build as scaffolded. Same
class as the Flutter root-widget defect — found only because someone built the render.
Not this brick's.

## Q-007 — `forge upgrade` never reads a project's owned-paths file

Found by review round 1, while correcting this brick's own explanation of why an upgrade
cannot deliver the sharp override. As read (not run end-to-end): `bin/forge-upgrade.sh`
sets `FORGE_REPO_ROOT` to the framework tree (`:26`; the CLI passes none), resolves owned
paths from `$FORGE_REPO_ROOT/.forge/framework-owned-paths.yml` only (`:194`, `:291`), and
takes each RIGHT side from `$FORGE_REPO_ROOT/$rel` (`:300`), skipping it when absent. The
root file owns no `package.json` and no `pubspec.yaml`. The per-archetype
`framework-owned-paths.yml.tmpl` rendered into a project is never consulted.

That falsifies `t7-flutter-deps-refresh`'s CHANGELOG claim "The bump now reaches existing
projects … `pubspec.yaml` (both archetypes) and `web-pwa/package.json` are now
framework-owned", which rests on that per-archetype file. It belongs to that change's
review, not to this brick; recorded here because this is where it was found. An
end-to-end `forge upgrade` on a rendered `mobile-pwa-first` project would settle it.
