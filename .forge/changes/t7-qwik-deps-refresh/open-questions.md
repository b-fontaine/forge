# Open questions — `t7-qwik-deps-refresh`

## Q-001 — nothing runs `npm audit` in CI

The three HIGH advisories were found because this brick ran `npm audit` by hand.
`b9-7`'s `web-pwa-ci.yml` runs `npm ci`, static analysis and a build — no audit step —
and no shell harness can see a transitive advisory, since they never install.

`T-037` now pins the *known* remediation, so this specific chain cannot silently
regress. It says nothing about the next advisory.

An `npm audit --audit-level=high` step in `web-pwa-ci.yml` is the obvious close, and it
is a judgement call rather than an oversight: audit failures are time-dependent, so the
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

## Q-003 — `.nvmrc` says 24 and this machine ran node 26

Every measurement here was taken under node v26.8.1 / npm 12.0.2 while the surface pins
node 24. The results — resolution, audit, typecheck, build — are unlikely to differ, but
they were not taken on the pinned runtime and that is worth stating rather than glossing.

`web-pwa-ci.yml` uses `node-version-file: web-pwa/.nvmrc`, so CI does run 24. If these
pins misbehave there, CI is where it will show.
