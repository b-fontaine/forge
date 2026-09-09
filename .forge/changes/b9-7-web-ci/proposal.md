# Proposal — `b9-7-web-ci`

**The PWA half of `mobile-pwa-first` has no CI at all.**

## What is actually there today

The archetype ships exactly one workflow,
`2.0.0/.github/workflows/mobile-ci.yml.tmpl`. Its header still reads

> `<!-- Audit: B.4 (b4-mobile-only, ...) -->`
> `CI workflow for <project-name> mobile-only Flutter app.`

because B.9.2 ported it byte-for-byte along with the rest of the Flutter surface.
It declares four jobs — `ios`, `android`, `e2e-android`, `summary` — and filters
on:

```yaml
paths: [ "lib/**", "ios/**", "android/**", "pubspec.yaml", "pubspec.lock",
         ".github/workflows/mobile-ci.yml" ]
```

`web-pwa/**` appears nowhere. A pull request that rewrites the entire PWA surface
triggers **no workflow**, and the `summary` required check reports success
without a single web step having run.

So B.9.7's original wording — "add a `pwa-deploy` job" — is the wrong end of the
problem. Deploying a build that is never built, type-checked or gated in CI puts
the vendor integration in front of the thing it depends on. §0.14 already
re-scoped this to *the whole web CI layer*; this change implements that reading.

## Scope

**In:**

- A new per-surface workflow, `web-pwa-ci.yml`, following
  `.forge/standards/infra/ci-workflows.md`.
- Its `scaffold-plan.yaml` entry, so it actually renders.
- The `b9-2` byte-equivalence exclusion the new root-level file requires.
- A `b9-7.test.sh` harness, registered in `forge-ci.yml`.

**Out, by maintainer decision (2026-09-09):** the `pwa-deploy` job. The workflow
builds and uploads `dist/` as an artifact; wiring a host is the adopter's step.
Rationale in ADR-B9-7-003.

**Out, recorded:** the flagship's `2.0.0` tree has **no workflows at all** — its
Qwik `frontend/web-public/` surface is in the same position, and so is every
other 2.0.0 layer. That is a flagship-sized hole, not a B.9 one; see
`open-questions.md` Q-001.

## Two constraints that shape the design

**1. `on.<event>.paths` is forbidden by the standard.** `ci-workflows.md`
(ADR-002) rejects it because a skipped workflow publishes no required status, so
branch protection cannot distinguish "not applicable" from "never ran".
`dorny/paths-filter@v3` is mandated instead: the workflow always runs, and
filtered jobs skip with SUCCESS. The inherited `mobile-ci.yml` uses the rejected
mechanism — a pre-existing B.4 deviation this change does not touch (Q-002).

**2. The new file breaks a byte-equivalence gate.** `b9-2.test.sh::T-007` diffs
a legacy `mobile-only` render against the ported one, excluding only `web-pwa`,
`scaffold-manifest.yaml` and `oidc-provider.json`. Any new root-level file fails
it. B.9.3 hit exactly this and set the precedent: add a documented exclusion
rather than weaken the comparison. This change follows it, and repeats B.9.3's
warning that `--exclude` matches a **basename at any depth**.

## Why this is worth doing now rather than at B.9.11

`t5-qwik-cli-ignore-dep` (2026-09-09) made `npm run build` work in this surface
for the first time. Before it, any CI job around the build would have been red on
its first run — which is presumably why none was written. The blocker is gone,
and B.9.8's snapshot should be taken of a tree whose CI has actually exercised it.

## Negative scope

MUST NOT modify `mobile-ci.yml.tmpl`, any file under `lib/`, `ios/`, `android/`,
`test/`, `overlay.sh`, the archetype schema, or `cli/src/**`. The Flutter surface
stays byte-identical to the `mobile-only` render.
