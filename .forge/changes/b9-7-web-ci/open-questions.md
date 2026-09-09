# Open questions — `b9-7-web-ci`

## Q-001 — the flagship `2.0.0` tree has no workflows at all (OUT OF SCOPE, recorded)

`find .forge/templates/archetypes/full-stack-monorepo/2.0.0 -path '*workflows*'`
returns **nothing**. The four reference workflows
(`forge-backend` / `forge-frontend` / `forge-infra` / `forge-integration`) live
at the archetype root, i.e. the `1.0.0` tree, and `forge-frontend.yml.tmpl` is a
**Flutter** workflow — `flutter pub get`, `dart format`, `flutter analyze`.

So the flagship's `2.0.0` Qwik surface, `frontend/web-public/`, added by B.8.9, is
in exactly the position this change fixes for `mobile-pwa-first`: it has no CI. A
repo-wide grep confirms there is **no Qwik/vite/npm CI anywhere** in any archetype
template today; `web-pwa-ci.yml` is the first.

**Why not fixed here.** The gap is not Qwik-specific — the whole 2.0.0 CI layer is
absent, across every layer, and reconstructing it means deciding how 2.0.0 relates
to the root workflows (overlay? replacement?). That is a flagship brick with its
own render-path question, and it is adjacent to the already-recorded
"`full-stack-monorepo/2.0.0.tar.gz` snapshot never produced" item.

**Status.** Recorded, with the grep that establishes it, so the next reader does
not have to rediscover that this change's workflow is the first of its kind.

## Q-002 — `mobile-ci.yml` uses the mechanism `ci-workflows.md` rejects

The inherited workflow filters with `on.pull_request.paths`. ADR-002 of
`ci-workflows.md` rejects exactly that in favour of `dorny/paths-filter`, because
a natively-skipped workflow publishes no required status.

Not fixed here for one hard reason and one soft one. Hard: `mobile-ci.yml.tmpl` is
byte-frozen against the `mobile-only` render (FR-B9-2-004, asserted by
`b9-2.test.sh::T-007`), so changing it ends that equivalence permanently. Soft:
the same file is the `mobile-only` archetype's workflow, so the defect is B.4's
and a fix belongs where both copies can move together.

Consequence to be aware of when configuring branch protection: on a web-only pull
request, `mobile-ci` does not appear at all, whereas `web-pwa-ci` appears and
reports `skipped`-as-success on a mobile-only change. The two surfaces behave
differently for the same reason one predates the standard.

## Q-003 — the web surface has no formatter, linter or test runner

`web-pwa/package.json` declares `dev`, `build`, `build.client`, `build.types`,
`preview`, `qwik` — and no prettier, no eslint, no vitest. So `ci-workflows.md`
steps 1 (format) and 3 (tests) have nothing to run.

The workflow declares this in its header rather than quietly shipping a
three-step gate that looks like a four-step one. Adding the tooling is a real
decision — three more pins, three config files, and a verify-then-pin pass — and
belongs with the quality brick, not with "add the CI layer".

Note the interaction with B.9.5, which is already flagged in §0.14 as needing a
re-scope ("l'archétype est client-only et n'a pas de messages proto comme
source"). Whichever brick picks up web-surface quality tooling should pick up
both.

## Q-004 — no lockfile means builds are not reproducible yet

ADR-B9-7-002 chose `npm install` because a scaffolded project has no
`package-lock.json` and `npm ci` exits non-zero without one. Until the adopter
commits a lockfile, two CI runs a week apart can resolve different transitive
versions inside the declared ranges.

Options for a later brick: ship a lockfile with the template (large, and stale the
day it lands), or have the scaffolder run `npm install` once at init and commit
the result. Both have real costs; neither is this change's to pay.
