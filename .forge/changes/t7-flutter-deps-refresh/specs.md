# Specs — `t7-flutter-deps-refresh`

**Namespace** : `FR-T7FD-*`, `NFR-T7FD-*`, `ADR-T7FD-*`.

---

## Functional Requirements

### FR-T7FD-001 — every Flutter pin is current, and verified

Both archetypes declare the versions `flutter pub outdated` reports as resolvable
against Flutter 3.47.2 / Dart 3.13.2:

| | from | to |
|---|---|---|
| `flutter_bloc` | ^8.1.6 | **^9.1.1** |
| `flutter_appauth` | ^7.0.0 | **^12.1.0** |
| `flutter_secure_storage` | ^9.2.2 | **^11.1.1** |
| `local_auth` | ^2.3.0 | **^3.0.2** |
| `intl` | ^0.19.0 | **^0.20.3** |
| `bloc_test` | ^9.1.7 | **^10.0.0** |
| `flutter_lints` | ^4.0.0 | **^6.0.0** |
| `equatable` | ^2.0.5 | **^2.1.0** |
| `mocktail` | ^1.0.4 | **^1.0.5** |

`dartastic_opentelemetry` and `flutterrific_opentelemetry` are already at their
resolvable maximum and MUST NOT be moved.

### FR-T7FD-002 — the SDK floor states what the set requires

`sdk: ">=3.0.0 <4.0.0"` → `">=3.10.0 <4.0.0"`. `flutter_appauth 12.1.0` and
`local_auth 3.0.2` declare `^3.10.0`. The old floor was a claim the dependency set no
longer supported: an adopter on Dart 3.5 got a resolution failure instead of a stated
minimum.

### FR-T7FD-003 — the call sites are adapted, not the pins softened

- `local_auth` 3.0.0 replaced `options: AuthenticationOptions(...)` with direct named
  parameters; `stickyAuth` → `persistAcrossBackgrounding`, `useErrorDialogs` removed.
- `flutter_secure_storage` 11.0.0 removed `encryptedSharedPreferences`; the Jetpack
  Security backend is gone and the defaults are now the strong path.

### FR-T7FD-004 — the 9 → 11 storage migration is documented where it is read

`flutter_secure_storage` migrated Android data off Jetpack in **v10** and removed the
backend in **v11**. A project jumping 9 → 11 skips the migration. The scaffold stores
one value (`auth_token_v1`), so the effect is a single forced re-authentication — but
`pubspec.yaml` is now framework-owned, so `forge upgrade` will propagate this bump into
existing projects. The note MUST live in the pubspec template, which lands in every
project.

### FR-T7FD-005 — dependency manifests are framework-owned

`owned:` gains `pubspec.yaml` in both archetypes and `web-pwa/package.json` in
`mobile-pwa-first`. Without this a bump reaches new projects only.

### FR-T7FD-006 — the scaffold builds and its test passes

`flutter analyze` clean and `flutter test` green on real renders of **both**
archetypes. This requires fixing two pre-existing defects: the smoke test must
initialise OTel, and `BiometricLockWidget` must sit **inside** `MaterialApp` via its
`builder:` so its `Stack` and `ElevatedButton` have `Directionality`, `Theme` and
`Material` ancestors.

### FR-T7FD-007 — the coupled guards are re-scoped, not deleted

- `b9-2` T-004: from "mobile-only is git-clean" to "the alias metadata survives and the
  frozen 1.0.0 snapshot is not rebuilt".
- `b9-3` T-022: from "the Flutter surface is git-clean" to "no browser-OIDC concern
  reaches the Flutter surface" — the property `NFR-B9-3-001` actually protects.
- `b9-2` T-007 gains `framework-owned-paths.yml` in its exclusions, and `T-034`
  replaces the lost coverage precisely.

### FR-T7FD-008 — new guards

- `T-034` — the two `owned:`/`excluded:` **sets** are identical once `web-pwa` entries
  are removed.
- `T-035` — both archetypes declare their dependency manifests owned.
- `T-036` — no pin sits below the verified **major**; a caret range moving forward is
  fine, sliding back under an adapted API is not.

### FR-T7FD-009 — CHANGELOG

---

## Non-Functional Requirements

### NFR-T7FD-001 — the two renders stay byte-identical

`b9-2` T-007 must stay green. `b9-9`'s "a migrated tree equals a native render" proof
rests on it.

### NFR-T7FD-002 — the frozen snapshot is never rebuilt

`mobile-only/1.0.0.tar.gz` must still match its `.sha256`.

### NFR-T7FD-003 — every version comes from the resolver

No pin written from memory. `flutter pub outdated` is the source; it corrected three
values read off the pub.dev API.

### NFR-T7FD-004 — guards mutation-proven

---

## ADRs

### ADR-T7FD-001 — bump both archetypes in lock-step

**Context.** T-004 and T-007 together made the pins immovable.

**Decision.** Both move; T-004 is re-scoped. Maintainer-ratified 2026-09-12.

**Rationale.** T-007 is the load-bearing invariant — `b9-9` proved a migrated tree
equals a native render, and adopters rely on it. T-004's git-cleanliness was a scope
guard for `b9-2` phrased as a permanent freeze; as an invariant it condemned a
supported alias to never receiving a security update.

**Consequence.** `mobile-only`'s templates can move. Its frozen snapshot cannot, and
`T-004` now says exactly that.

### ADR-T7FD-002 — own the manifests, not the source

**Context.** Three options were put to the maintainer; the narrowest was chosen.

**Decision.** `pubspec.yaml` and `web-pwa/package.json` only.

**Rationale.** They are what makes FR-T7FD-001 reach existing projects, and the 3-way
merge is well suited to a file where the framework owns the shape and the adopter owns
the additions — the reasoning `oidc_config.dart` already carries.

**Consequence.** The `web-pwa/` source tree stays adopter-owned: framework improvements
to the service worker or the OIDC client still will not propagate. Recorded, not
resolved.

### ADR-T7FD-003 — fix the two scaffold defects here

**Context.** `flutter test` fails on a pristine render, for reasons predating this
brick.

**Decision.** Fix both.

**Rationale.** The brick's claim is "the pins are current and the scaffold works". Half
of that is unverifiable while the test cannot run, and a scaffold whose root widget
throws is not "up to date" in any sense that matters. The toolchain to prove the fix
was already in hand.

**Consequence.** `app.dart` changes in both archetypes — production code, in a brick
nominally about dependencies. Called out here rather than buried: the widget-tree fix
is the one change in this brick that alters what a scaffolded app *does*.
