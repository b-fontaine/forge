# Proposal — `b9-5-bloc-generator`

`bin/forge-gen-bloc.sh` — generate a `flutter_bloc` feature (Event / State / Bloc +
`bloc_test`) from a local YAML descriptor.

## Why the brick had to be re-scoped, and it is the archetype's premise, not an accident

§5.2 specified the generators as producing `Event`/`State`/`Bloc` **from the proto
messages**. `mobile-pwa-first` has no protos, and that is not an omission to fill in:
the schema is `layer_profile: client-only` (`ADR-B9-1-001`), so there is no backend
layer, no `shared/protos`, no contract of any kind under Forge's control.

The maintainer stated the principle directly (2026-09-12): *the archetype does not
manage the server side*. The identity provider lives in the adopter's own information
system — a self-hosted Keycloak, an Auth0 subscription, whatever they run. Forge never
sees it. What Forge provides is **a corner of config** where the adopter declares what
identifies their client, plus a standards-conformant client. As long as the server
speaks OIDC, it works.

That is already how `oidc-provider.json` (B.9.3) is built: `issuer`, `scopes` and
`discoveryUrl` declared once, and per surface only what genuinely differs — `clientId`
and `redirectUri` — with `TODO_REPLACE_*` placeholders and no secret, because both
surfaces are public PKCE clients. It even carries the uncomfortable consequence rather
than dodging it: `identity.yaml` requires a self-hosted IdP at tier T3, and a
client-only archetype can self-host nothing, so the obligation **transfers** to the
deployment the adopter operates elsewhere (`ADR-B9-3-004`).

Apply the same boundary to B.9.5 and the re-scope writes itself: **we do not own a
server, so there is no server contract to generate from.** The source of truth has to
be local and declared by the adopter, exactly as the OIDC config is.

## What the repository already provides, and what it does not

| | |
|---|---|
| `flutter_bloc: ^8.1.6`, `equatable: ^2.0.5` | declared, used by the one scaffolded bloc |
| `bloc_test: ^9.1.7`, `mocktail: ^1.0.4` | **declared and used by nothing** — `test/` holds only `widget_test.dart` |
| `lib/presentation/auth/auth_bloc.dart` | the single worked example, 116 lines |
| `lib/presentation/`, `domain/`, `data/` | otherwise `.gitkeep` |

So the archetype ships the test-discipline dependencies for Bloc and not one
`blocTest`. A team adding their second feature copies `auth_bloc.dart` by hand and
writes no bloc test, because nothing shows them the shape.

## What the generator can produce, and the line it must not cross

`auth_bloc.dart`'s handler bodies are business logic — `_onLogin` calls the repository,
maps the result, emits. No generator can write that.

What is mechanical is everything around it: the event hierarchy, the state hierarchy,
`Equatable` props, the constructor, the `on<Event>` registrations, and a `blocTest` per
event. The generator emits those and leaves each handler as
`throw UnimplementedError(...)`.

**Throwing, not an empty body.** An empty handler emits nothing and the bloc silently
does nothing — code that looks implemented and is not. This repository already made
that call once, for the offline shell: *"a shell whose dependencies are fetched on
demand fails exactly when it is needed, which is worse than no shell because it looks
implemented"* (`pwa.yaml::PWA-RULE-002`). Same reasoning, same answer.

And the generated `blocTest` asserts the `UnimplementedError`. That makes it a
**tripwire**, not a fake passing test: it is green on generation and goes red the
moment the adopter writes the handler, which is precisely when they owe a real test.

## Scope

**In:** `bin/forge-gen-bloc.sh`; the descriptor format, documented by `--help`; a
harness generating a fixture feature and asserting the output's shape; CHANGELOG and
resync.

**Out:** every archetype template. The generator is `bin/` tooling that runs against an
adopter's project — adding a file to `2.0.0/` would drift the B.9.8 snapshot and the
`b9-2` plan counts for no gain (the B.9.9 precedent: a `bin/` script with zero template
mutation).

## Negative scope

MUST NOT touch `.forge/templates/`, the frozen `mobile-only/1.0.0` tree, or the
snapshots. MUST NOT add a dependency to any `pubspec.yaml.tmpl` — `bloc_test` and
`mocktail` are already there, which is the point. MUST NOT bump `flutter_bloc`'s pin
(see Q-001: the standard and the templates disagree, and the fix is not this brick's).
