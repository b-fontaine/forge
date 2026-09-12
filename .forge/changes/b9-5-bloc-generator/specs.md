# Specs — `b9-5-bloc-generator`

**Namespace** : `FR-B95-*`, `NFR-B95-*`, `ADR-B95-*`.

---

## Functional Requirements

### FR-B95-001 — the script exists with the sibling ABI

`bin/forge-gen-bloc.sh --target <dir> --feature <name> [--dry-run] [--force]`,
executable, `set -euo pipefail`, exit envelope **0 / 2 / 5 / 7 / 8** matching
`forge-migrate-mobile-pwa.sh` and `forge-migrate-flagship.sh`.

`--help` MUST document the descriptor format in full — it is the contract, since no
template ships an example (`ADR-B95-002`).

### FR-B95-002 — the descriptor is local, declarative, and adopter-owned

Read from `<target>/lib/presentation/<feature>/<feature>.bloc.yaml`:

```yaml
name: Cart                      # PascalCase prefix for every generated class
repository: CartRepository      # optional; omitted ⇒ no constructor dependency
repository_import: ...          # optional; defaults to the archetype convention,
                                #   package:<pubspec name>/domain/<feature>/<snake>.dart
imports:                        # optional; emitted verbatim into the generated files
  - package:shop/domain/cart/cart_item.dart
events:
  - ItemAdded: {item: CartItem}
  - ItemRemoved: {id: String}
states:
  - Initial                     # first entry is the initial state
  - Loading
  - Loaded: {items: List<CartItem>}
  - Failure: {message: String}
```

A field-less entry may be written as a bare string; one with fields as a single-key
map of `name: {field: DartType, ...}`.

### FR-B95-003 — the generated names reproduce the archetype's own idiom

Derived from `lib/presentation/auth/auth_bloc.dart`, not invented:

| | pattern | from the reference |
|---|---|---|
| event base | `<Name>Event extends Equatable` | `AuthEvent` |
| event | `<Name><EventName>` | `AuthLoginRequested` |
| state base | `<Name>State extends Equatable` | `AuthState` |
| state | `<Name><StateName>` | `AuthAuthenticated` |
| bloc | `<Name>Bloc extends Bloc<<Name>Event, <Name>State>` | `AuthBloc` |
| ctor | `<Name>Bloc({required <Repo> repository})` | `AuthBloc({required AuthRepository repository})` |

Every generated class MUST declare `const` constructors and an
`@override List<Object?> get props`, matching the reference.

### FR-B95-004 — four files, split by concern

```
lib/presentation/<feature>/<feature>_event.dart
lib/presentation/<feature>/<feature>_state.dart
lib/presentation/<feature>/<feature>_bloc.dart
test/presentation/<feature>/<feature>_bloc_test.dart
```

The reference keeps all three in one file; the generator splits them, per the
maintainer's selected shape (2026-09-12) and community convention.

### FR-B95-005 — handlers throw, they do not no-op

Each `on<Event>` handler body MUST be `throw UnimplementedError(...)` naming the
event. An empty handler emits nothing and the bloc silently does nothing — code that
looks implemented and is not, the failure `pwa.yaml::PWA-RULE-002` already refused for
the offline shell.

### FR-B95-006 — the generated test is a tripwire

One `blocTest` per event, asserting `errors: [isA<UnimplementedError>()]`, with a
`mocktail` double for the repository (`mocktail: ^1.0.4` is already a declared
dev-dependency; the generator MUST NOT add one).

A header comment MUST state that the test goes red as soon as the handler is
implemented, **by design** — that is when a real assertion is owed.

**It is green on generation only for field-less events.** An event that declares fields
gets `/* TODO: <field> (<Type>) */` in its constructor call, and that test does not
compile until the adopter fills it in. Deliberate: only they can construct their own
domain types, and fabricating a value would make the suite green on data nobody chose.
The generated header says so. Corrected here after writing the generator — the original
wording of this requirement claimed unconditional green, which the code cannot deliver.

Non-primitive field types need an import the generator cannot guess, hence `imports:`
in FR-B95-002. Without it, any event with a domain-typed field produces code that does
not compile, which would make the generator a nuisance rather than a shortcut.

### FR-B95-007 — preconditions refuse with exit 7

Named, actionable refusals when: `<target>` is not a directory; it has no
`pubspec.yaml`; that pubspec declares no `flutter_bloc`; the descriptor is absent or
unparseable; `events:` or `states:` is empty; **or the first state declares fields**
(the generated `super(const <Name><First>())` would not compile).

### FR-B95-008 — collision refusal

Any of the four targets already existing ⇒ exit **8** listing them, unless `--force`.
`--dry-run` prints what would be written and mutates nothing.

### FR-B95-009 — CHANGELOG and resync

`[Unreleased]` entry; plan §0.14 / §5.2 / §11 and `.forge/product/roadmap.md`.

---

## Non-Functional Requirements

### NFR-B95-001 — zero archetype mutation

No change under `.forge/templates/`, `.forge/scaffold-snapshots/`,
`.forge/schemas/`. The B.9.9 precedent: `bin/` tooling that runs against an adopter
project needs no template file, and adding one drifts the B.9.8 snapshot and the
`b9-2` plan counts.

### NFR-B95-002 — no new dependency, adopter-side or Forge-side

`bash`, `python3` only, matching the siblings. The generated code uses
`flutter_bloc`, `equatable`, `bloc_test` and `mocktail` — all four already declared.

### NFR-B95-003 — the output is asserted, not the script

The harness MUST generate a fixture feature and assert the resulting files' content —
class names, `props`, the `on<Event>` registrations, the `UnimplementedError`, the
`blocTest` count. `b8-10b` shipped 36 raw `.tmpl` files into adopter projects because
no test ever looked at generator output.

### NFR-B95-004 — guards scoped and mutation-proven

Needles name the claim and are unique within the region they are checked in. Proven by
deleting each asserted property in turn and confirming RED — the `b9-4` lesson, where a
correctly-scoped needle still passed because the bare word recurred two paragraphs
down.

---

## ADRs

### ADR-B95-001 — the source is a local descriptor, because there is no server contract

**Context.** §5.2 specified generation from proto messages.

**Decision.** Generate from `lib/presentation/<feature>/<feature>.bloc.yaml`, a file
the adopter writes and owns.

**Rationale.** `mobile-pwa-first` is `layer_profile: client-only`: no backend layer, no
`shared/protos`. This is the archetype's premise, the same one that puts the OIDC
issuer in the adopter's information system and leaves Forge with only a config corner.
A generator needs a contract; the only contract available on this side of the boundary
is one the adopter declares.

**Consequence.** The descriptor is not a schema Forge validates against a server — it
is a local statement of intent. Drift between it and the generated code is possible and
is the adopter's to manage; the generator refuses to overwrite without `--force`
precisely so that regenerating cannot silently discard their handlers.

### ADR-B95-002 — no example descriptor in the archetype template

**Context.** An adopter has to learn the format from somewhere.

**Decision.** `--help` carries the full format. No `.bloc.yaml` is added to
`2.0.0/`.

**Rationale.** Adding one template file moves the scaffold plan from 73 to 74 entries,
changes `b9-2::T-003`'s count, and drifts the `mobile-pwa-first/2.0.0` snapshot B.9.8
froze — a real cascade, for an example that `--help` delivers at the moment of use.

**Consequence.** `auth_bloc.dart` remains the archetype's only worked Bloc, and it is
hand-written rather than generated. That is correct: its handlers are real logic, and a
descriptor claiming to have produced it would be a lie the harness could not catch.

### ADR-B95-003 — the generated test asserts the stub

**Context.** A generated `blocTest` against an unimplemented handler could assert
nothing, be skipped, or assert the stub.

**Decision.** Assert `errors: [isA<UnimplementedError>()]`.

**Rationale.** A skipped or empty test is the "looks implemented" failure applied to the
test suite: a green run that measured nothing. Asserting the stub makes the test true
where it can compile and **self-invalidating** — implementing the handler turns it red,
which is the signal to write the real assertion.

**Consequence.** A project that generates ten features and implements none has ten
green tripwires, not ten passing tests. The header comment says so, because a reader
who mistakes the count for coverage would be wrong.
