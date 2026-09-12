# Open questions — `b9-5-bloc-generator`

## Q-001 — the `flutter_bloc` pin and the standard disagree by a major version

```
.forge/standards/state-management.yaml:37     version_pinned: ^9.0.0
mobile-only/pubspec.yaml.tmpl:15              flutter_bloc: ^8.1.6
mobile-pwa-first/2.0.0/pubspec.yaml.tmpl:15   flutter_bloc: ^8.1.6
```

Nothing catches it. `no-state-management-alternatives` is CI-blocking but forbids
*alternatives* — `riverpod`, `provider`, `get`, `mobx` — and never looks at the version
of the sanctioned library.

Not fixed here, for two reasons. `mobile-only/1.0.0` is **frozen** (`ADR-B8-2-004`,
B.9.8), so its pubspec cannot move; and bumping `mobile-pwa-first`'s would drift the
2.0.0 snapshot B.9.8 froze. Either the standard is ahead of the templates on purpose
and should say so, or the templates owe a bump — that is a maintainer call with a
snapshot consequence, i.e. a brick.

The generator is unaffected: it emits the shapes `auth_bloc.dart` already uses, which
compile against whatever the project pins.

## Q-002 — `T-033` asserts declarations, not compilability

The harness reads the generated files and checks class declarations, field types,
registrations, the `UnimplementedError` and the `blocTest` count. It does **not** run
`dart analyze`, because the Flutter toolchain is not a CI dependency of this
repository.

The limit is real and was demonstrated inside this brick: the first version emitted
`final CartItem item;` with no import for `CartItem`, and every structural assertion
passed. It was found by reading the output, not by a test.

What would close it: an L2 test gated behind `FORGE_B9_5_LIVE=1` running
`dart analyze` on a generated fixture inside a real scaffolded project — the shape
`b9-2::T-L2-002` already uses for `npm install && tsc --noEmit`. Deferred rather than
half-done: it needs a Flutter SDK in the runner, which is a CI decision.

## Q-003 — the descriptor has no schema and no linter rule

`<feature>.bloc.yaml` is validated only by the generator, at the moment it runs. There
is no JSON Schema under `.forge/schemas/`, and `constitution-linter.sh` does not look
for descriptors whose generated files have drifted.

That is defensible today — the descriptor is adopter-owned, and Forge validating a file
it does not own would be the same overreach the archetype avoids for the OIDC issuer.
It becomes a question if drift turns out to bite in practice: an adopter who edits
`cart_event.dart` by hand and leaves `cart.bloc.yaml` stale has two sources of truth and
no warning. The collision refusal (exit 8) protects their handlers but says nothing
about the divergence.

## Q-004 — no generator for the `web-pwa` surface

This brick covers the `app` layer only. The Qwik surface has its own state story
(signals / stores) and no equivalent scaffolding, so a feature spanning both surfaces is
generated on one side and hand-written on the other.

Whether that matters depends on how often features really span both — the two surfaces
hold independent sessions by design (`oidc-provider.json`: *"a token minted in the
native app is not available to the PWA"*), which suggests they may diverge more than
they mirror. Worth one measurement before building anything.
