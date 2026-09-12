# Open questions — `t7-flutter-deps-refresh`

## Q-001 — the `web-pwa/` source tree is still adopter-owned

The maintainer chose the narrow option: dependency manifests only. So
`web-pwa/package.json` now merges on `forge upgrade`, and everything under
`web-pwa/src/` still does not — the service worker, the push client, the browser OIDC
implementation. A framework fix to any of them reaches new projects only.

That is defensible under the client-only principle (the adopter owns their surface) and
it is now a **choice** rather than an accident, which was the point of `b9-10` Q-001.
Revisit if a security fix ever needs to reach `web-pwa/src/lib/auth/`.

## Q-002 — no harness runs `flutter test` on a rendered tree

Two defects lived in the scaffold since B.4 — an uninitialised OTel in the smoke test,
and a root widget that threw on first build — and neither was catchable by anything in
CI. The L2 cells that exist run `flutter analyze` at most, and `analyze` reported
**no issues** on the broken tree.

What would close it: an L2 cell, gated like `b9-2::T-L2-002`, that renders and runs
`flutter test`. The obstacle is CI, not the harness — the runner has no Flutter SDK, and
adding one is a workflow decision with a real time cost. Until then the scaffold's
runnability is verified only when someone happens to have the toolchain, which is how it
stayed broken for four months.

## Q-003 — `web-pwa/package.json`'s own pins were not verified

This brick refreshed the Flutter side and proved it with the toolchain it had. The Qwik
side is now framework-owned but its versions are untouched, because verifying them needs
an `npm install` resolve that was not run here.

`b9-7`'s `web-pwa-ci.yml` does run `npm ci` and a build, so the surface is exercised in
CI — but nothing reports that its pins are behind, the way `flutter pub outdated` does.
The symmetric brick is small and worth doing.

## Q-004 — `state-management.yaml` still pins a range, not the verified version

The standard says `version_pinned: ^9.0.0` and the templates now say `^9.1.1`. Both
admit 9.1.1, so nothing is inconsistent — but the standard's value is looser than the
verified one, and `T-036` guards the templates rather than the standard.

Whether a standard should carry the exact verified pin or an intentional range is a
convention question that applies to every `version_pinned` in `.forge/standards/`, not
just this one.
