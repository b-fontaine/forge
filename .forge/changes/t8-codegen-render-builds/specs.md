# Specs — `t8-codegen-render-builds`

**Namespace** : `FR-T8CRB-*`, `NFR-T8CRB-*`, `ADR-T8CRB-*`.

---

## Functional Requirements

### FR-T8CRB-001 — `buf generate` succeeds on every live archetype

A fresh render of `ai-native-rag/1.0.0`, `event-driven-eu/1.0.0` and
`full-stack-monorepo/2.0.0` MUST complete `buf generate` (so `task proto`) with exit 0,
writing the prost messages, the tonic services, the Connect stubs and the TS descriptors.

### FR-T8CRB-002 — managed mode declares a Go package prefix

Each live `buf.gen.yaml.tmpl` MUST carry, under `managed:`, an `override` entry with
`file_option: go_package_prefix` whose value is derived from the scaffold placeholders —
`<reverse-domain>/<project-name>/gen/go` — so each project gets a path of its own rather
than a shared literal.

### FR-T8CRB-003 — the tonic plugin does not read another plugin's output

Each live `buf.gen.yaml.tmpl` MUST pass `no_include=true` to
`buf.build/community/neoeinstein-tonic`, with a comment saying why: buf isolates plugin
outputs, so the generated include would reference a file tonic cannot see.

### FR-T8CRB-004 — the TypeScript client imports what buf writes

`ai-native-rag` MUST import from `./generated/connect/v1/rag/rag_pb`. The flagship 2.0.0
MUST import `ExampleService` from `./generated/connect/v1/example/example_pb` — the
service its own proto declares — and its `src/routes/index.tsx.tmpl` consumer MUST be
realigned with it. A fresh render MUST pass `tsc --noEmit` and `vite build` with **no
shim and no hand-edit**.

### FR-T8CRB-005 — the example renders follow their templates

`examples/forge-rag-example`, `examples/forge-eda-example` and
`examples/forge-fsm-example` MUST carry the same fixes, substituted from the templates
they render (ADR-T8ETP-001). For the fsm tree only its `shared/protos/buf.gen.yaml`
changes — it renders the 1.0.0 manifest, which this brick fixes (ADR-T8CRB-002).

### FR-T8CRB-006 — `b7-6::T-B05` derives the expected specifier

It MUST read the es plugin's `out:` from `buf.gen.yaml.tmpl` and the proto's own path, and
assert the client's import matches what that combination produces — never a hardcoded
literal, which is what let the wrong path pass review for three months.

### FR-T8CRB-007 — `b7-6::T-C02` fails closed

Its "offline" escape MUST NOT swallow a plugin error. Only a genuine transport failure may
SKIP; a plugin exiting non-zero MUST fail. BSR rate-limiting stays a legitimate SKIP, and
MUST be distinguished from a plugin failure rather than matched by the same pattern.

### FR-T8CRB-008 — `b7-6::T-C04` actually typechecks

It MUST, when node and npm are present, install the rendered web surface and run
`tsc --noEmit` against it, and only SKIP when the toolchain is genuinely absent. An
unconditional `return 0` is not a test.

### FR-T8CRB-009 — the records stop claiming a gate that does not gate

The roadmap B.7 row and plan §0.12, which cite `harness-rust` as proof of the
buf → codegen → tsc chain, MUST say what that job proves once T-C02/T-C04 are real.
`t7-qwik-deps-refresh` Q-005 and Q-006 are resolved, and the CHANGELOG Known-issues bullet
they back is removed or narrowed.

---

## Non-Functional Requirements

### NFR-T8CRB-001 — no forge-ci.yml line

`T-C02`/`T-C04` live in `b7-6.test.sh`, already registered, and `harness-rust` already
installs node and buf. `forge-ci.yml` stays at 421 of the 440 `NFR-CI-002` budget.

### NFR-T8CRB-002 — every version comes from a resolve, every claim from a run

Plugin versions unchanged. Each fix measured on a real render before being written, and
re-measured on a render from the updated template.

### NFR-T8CRB-003 — guards mutation-proven

Each new or rewritten assertion RED before GREEN, each probe naming the offending file,
every file restored byte-identical.

---

## ADRs

### ADR-T8CRB-001 — move the import, do not flatten the codegen

**Context.** Three ways to make the client resolve: change the import; flatten buf's
output; or shim the specifier through `tsconfig` paths and a vite alias.

**Decision.** Change the import.

**Rationale.** Flattening is not available — `protoc-gen-es` documents no such option, and
the only lever that flattens is narrowing the buf module root to the service directory,
which silently drops every other proto from lint, breaking-change detection and codegen.
The shim was measured and does not even work: `tsconfig` `paths` does not resolve a
relative specifier, so `tsc` still fails. That leaves the import, which is also the only
option that leaves the generated tree looking like the proto tree.

**Consequence.** The specifier carries the proto's version directory, so adding
`v2/rag/rag.proto` later produces a second descriptor beside the first rather than
overwriting it. `T-B05` derives the expected path so the two cannot drift apart again.

### ADR-T8CRB-002 — the 1.0.0 flagship manifest IS fixed (decision reversed in review)

**Context.** `full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl` carries the same two
defects, and `examples/forge-fsm-example` ships its render.

**First decision, and why it was wrong.** This ADR originally said "do not touch either",
on the grounds that the tree is the BASE `forge upgrade` three-way-merges against, so
editing it would make BASE diverge from what adopters received. Review round 1 forced
that premise to be checked, and it is false: `bin/forge-upgrade.sh:277-286` recovers BASE
from the committed snapshot tarball `.forge/scaffold-snapshots/<archetype>/<from>.tar.gz`,
never from the live template tree. Editing the template changes RIGHT, which is exactly
the side that should carry a fix. The rationale was plausible and unverified — the failure
mode this repository keeps paying for.

Worse, the freeze did not hold where it mattered: `scaffold-plan-2.0.0.yaml:174` inherits
this 1.0.0 manifest rather than the 2.0.0 overlay's, so `forge init --archetype
full-stack-monorepo` — the stable, scaffoldable default — renders THIS file. Leaving it
alone left FR-T8CRB-001 unmet on the archetype's own default path, while the records
claimed the flagship was fixed.

**Decision.** Fix it, and re-render `examples/forge-fsm-example`'s manifest from it.

**Rationale.** It is the file a fresh flagship init actually gets; BASE is unaffected; and
`b8-9::T-010`'s frozen guard asserts only that this file carries no `B.8.9` annotation,
which remains true (verified: 14/14 after the edit).

**Consequence.** Both flagship manifests now carry the fix, and the 2.0.0 overlay's copy
is reached only by the migration path. That the two can drift is pre-existing and not
this brick's to resolve — recorded as Q-001.
