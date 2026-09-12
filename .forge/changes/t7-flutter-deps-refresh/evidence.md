# Evidence — `t7-flutter-deps-refresh`

All probes 2026-09-12, against Flutter 3.47.2 / Dart 3.13.2.

---

## P-1 — the two open questions are one problem

`_a7_resolve_owned_paths` (`bin/forge-upgrade.sh:192-226`) merges only paths matched by
`owned:`; `excluded:` is a subtractive filter on that set. `pubspec.yaml` is in
neither, so a framework pin bump reached new `forge init` projects and no existing one.

## P-2 — the guard collision, before touching anything

`b9-2` T-004 asserts `mobile-only` is byte-clean vs HEAD. `b9-2` T-007 asserts the two
archetypes render identically, `pubspec.yaml` included. Bump one ⇒ T-007 red; bump both
⇒ T-004 red. Put to the maintainer, who chose lock-step.

## P-3 — the resolver corrected my reading

I read versions off the pub.dev API. `flutter pub outdated` on a real render disagreed
on three of them: `equatable`, `mocktail` and `dartastic_opentelemetry` are already at
their resolvable maximum, and `^1.1.0-beta.6` is a deliberate prerelease pin, not
staleness. Nine packages moved, not twelve.

Before: `28 packages have newer versions incompatible with dependency constraints`.
After: 8, all transitive and SDK-bound.

## P-4 — three majors, two call sites

```
flutter analyze  →  3 issues
  local_auth 3.x            biometric_service.dart:19    options: / AuthenticationOptions
  flutter_secure_storage 11 secure_storage_adapter.dart:20  encryptedSharedPreferences
```

Nothing from `flutter_appauth` despite 7 → 12. Both signatures were read from the
**installed package sources**, not from memory:

```dart
Future<bool> authenticate({
  required String localizedReason,
  bool biometricOnly = false,
  bool sensitiveTransaction = true,
  bool persistAcrossBackgrounding = false,   // was AuthenticationOptions.stickyAuth
})
```

## P-5 — a failing test that was not mine

`flutter test` failed after the bump: `Bad state: OTel.initialize() must be called
first`. Re-run against a **pristine, unbumped** render — the same failure. Pre-existing
since B.4, not caused by the bump.

Fixing it (the test must call `initOtel()`, as `main()` does) revealed a second defect
underneath:

```
No Directionality widget found.
Stack widgets require a Directionality widget ancestor.
  ownership chain: Stack ← BiometricLockWidget ← ... ← App
```

`BiometricLockWidget` wrapped `MaterialApp`, so its `Stack` and `ElevatedButton` had no
`Directionality`, `Theme` or `Material` ancestor. **`forge init` produced a project
whose root widget threw on first build**, and the OTel failure had been masking it.

Both fixed. Neither would have been found without running `flutter test`, which no
harness does (Q-002).

## P-6 — the proof, on both archetypes

```
──── mobile-pwa-first ────      ──── mobile-only ────
  pub get OK                      pub get OK
  No issues found!                No issues found!
  All tests passed!               All tests passed!
```

First time a `forge init` render of either archetype resolves, analyses clean **and**
passes its test.

## P-7 — what the template change broke, and what it must not

Running the full matrix after the edit surfaced four coupled guards. Two were expected
(T-004, T-007); two were not:

| | why | resolution |
|---|---|---|
| `b9-2` T-004 | mobile-only edited | re-scoped to the alias metadata + the frozen snapshot |
| `b9-2` T-007 | `framework-owned-paths.yml` diverges by the two PWA lines | excluded, with `T-034` bounding the divergence exactly |
| `t5-otel-dartastic` T-011 | `cli/assets/` mirror stale | `npm run bundle` |
| `b9-3` T-022 | Flutter surface not git-clean | re-scoped to "no browser-OIDC concern on the Flutter surface" |

Measured, before deciding: the **only** template-sourced divergence between the two
renders is `framework-owned-paths.yml`, and only the two lines added for
`web-pwa/package.json`. Everything else `diff -rq` reported was build artefacts from my
own `pub get` runs.

`b4` stayed green throughout — the frozen `mobile-only/1.0.0` snapshot still matches its
`.sha256`.

## P-8 — T-034's first version asserted the prose

It diffed the two owned-paths files line by line, filtering lines containing `web-pwa`,
and failed on a comment that happened not to contain the token. It was asserting that
the *comments* matched.

Rewritten to compare **parsed** `owned:`/`excluded:` sets. What matters is what the file
means to `_a7_resolve_owned_paths`, not how it is worded.

## P-9 — mutation probes

| probe | result |
|---|---|
| `pubspec.yaml` un-owned in mobile-only | RED |
| `pubspec.yaml` un-owned in mobile-pwa-first | RED |
| owned sets diverge on something other than web-pwa | RED |
| `flutter_bloc` slid back to `^8.1.6` | RED |
| `flutter_secure_storage` slid back to `^9.2.2` | RED |

**5/5**, all files restored byte-identical.

## P-10 — regression

Full CI matrix **81/81** · `verify.sh` **665/0 PASS** · `constitution-linter` **99/0
OVERALL PASS** · shellcheck clean · `b9-2` 36/0 · `b9-3` 27/0 · `b4` 43/0 (frozen
snapshot intact) · `b9` 28/0.
