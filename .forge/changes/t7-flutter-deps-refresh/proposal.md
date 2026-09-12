# Proposal — `t7-flutter-deps-refresh`

Bring every Flutter pin current, and make a pin bump able to reach a project that
already exists.

## Two open questions that turned out to be one problem

`b9-5` Q-001: `state-management.yaml` pins `flutter_bloc: ^9.0.0` while both Flutter
archetypes ship `^8.1.6`. Nothing catches it — the `no-state-management-alternatives`
linter forbids *alternatives*, never a version.

`b9-10` Q-001: `.forge/framework-owned-paths.yml` names nothing under `web-pwa/`.

Reading `_a7_resolve_owned_paths` joins them: `forge upgrade` merges **only** what
`owned:` matches, and `excluded:` is a subtractive filter on that set rather than an
independent list. `pubspec.yaml` is in neither. So a dependency bump — security fixes
included — reaches new `forge init` projects and **no existing one**. Fixing the pins
without fixing ownership would have been half a fix.

## The two guards that made the pins immovable

`b9-2` T-004 asserted `mobile-only` is byte-clean vs HEAD. `b9-2` T-007 asserts the two
archetypes render identically, `pubspec.yaml` included. Together: bump one and T-007
breaks, bump both and T-004 breaks. There was no green state in which a supported
legacy alias could receive a security update.

Maintainer decision (2026-09-12): **bump both in lock-step**, re-scope T-004. T-007 —
the invariant that actually matters, because `b9-9`'s migration proof rests on it —
keeps holding. The frozen `1.0.0` snapshot is untouched; it is the historical merge
BASE, which is what the freeze is for.

`b9-3` T-022 needed the same treatment for the same reason, and its message misstated
its own mechanism: it claimed the surface was "byte-frozen by b9-2 T-007" while
actually diffing against git history.

## Verified, not asserted

Flutter 3.47.2 / Dart 3.13.2 are on this machine, so every pin was moved and then
proven: `flutter pub get`, `flutter analyze`, `flutter test` on real renders of **both**
archetypes. `flutter pub outdated` supplied the resolvable set — it accounts for
transitive constraints, which a pub.dev scrape does not, and it corrected three
versions I had read off the API.

Nine bumps, three of them major, and only **two** call sites needed adapting.

## What the toolchain found that no harness could

`flutter test` on a **pristine, unbumped** render fails. Two stacked defects, latent
since B.4:

1. the scaffolded smoke test builds `App` without `OTel.initialize()`, which
   `App.build` requires;
2. underneath it, `BiometricLockWidget` wraps `MaterialApp` — so its `Stack` has no
   `Directionality` ancestor and the root widget throws on first build. `forge init`
   produced a project that did not run.

Neither is caused by this change; both are fixed here, because the brick had the
toolchain, the proof, and the files already open. No harness runs `flutter test` on a
rendered tree — that gap is Q-002.

## Scope

**In:** the nine pins and the SDK floor in both archetypes; the two API adaptations;
the two scaffold defects; `pubspec.yaml` (+ `web-pwa/package.json`) as framework-owned;
`b9-2` T-004 and `b9-3` T-022 re-scoped; three new guards; CHANGELOG.

**Out:** the `web-pwa/` source tree's ownership — the maintainer chose dependency
manifests only. Qwik-side pins: `web-pwa/package.json` is now owned but its versions
are unchanged, since verifying them needs an `npm` resolve this brick did not run.

## Negative scope

MUST NOT rebuild the frozen `mobile-only/1.0.0` snapshot. MUST NOT let the two renders
diverge on the Flutter surface. MUST NOT weaken a re-scoped guard to a tautology: each
is replaced by a standing property, not deleted.
