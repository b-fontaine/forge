# Proposal — `t8-codegen-render-builds`

`t7-qwik-deps-refresh` Q-005 and Q-006: a freshly rendered project does not build. Both
were recorded there as "not this brick's". They are this brick's.

## What is actually broken, measured on real renders

**`buf generate` — so `task proto` — exits 1 on every archetype that ships protos.**
Not just `ai-native-rag`, as Q-005 said: `event-driven-eu` and `full-stack-monorepo`
2.0.0 fail identically.

```
Please specify either: a "go_package" option in the .proto source file,
or a "M" argument on the command line.
```

And that error hides a **second, independent** failure. With it fixed:

```
plugin buf.build/community/neoeinstein-tonic:v0.4.0: read rag.v1.rs: file does not exist
```

The tonic plugin tries to READ the prost plugin's output; buf isolates each plugin, so it
never sees it — measured both with the plugins sharing an `out:` and alone (prost alone
rc=0 and writes `rag.v1.rs`; tonic alone rc=1).

**The TypeScript client imports a path buf does not write.** `protoc-gen-es` has no
flattening option — Context7 `/bufbuild/protobuf-es`: `foo/bar.proto` generates
`foo/bar_pb.ts`, and the only plugin options are `target`, `import_extension`,
`keep_empty_files`, `ts_nocheck`, `bootstrap_wkt`. With the proto at
`shared/protos/v1/rag/rag.proto`, buf can only write `generated/connect/v1/rag/rag_pb.ts`.
The template imports `./generated/connect/rag_pb`. So `tsc --noEmit` fails TS2307 and
`vite build` cannot resolve the import.

**The flagship is wrong twice over.** Its client imports `GreeterService` from
`./generated/connect/greeter_pb`, but the only proto it ships is `example.v1` with
`service ExampleService { rpc Ping }`. Wrong directory *and* wrong symbol: a path-only
edit would not compile.

**Nothing in CI could have caught any of it.** `b7-6::T-C02` treats any buf failure whose
log matches `network|connect|…|buf\.build|…` as "offline" and returns 0 — the go_package
error names `buf.build/connectrpc/go`, so it matches (run `34815880019` printed the SKIP
while the same job downloaded crates). `T-C04`, the Qwik typecheck, returns 0 on every
path. The roadmap's B.7 row and plan §0.12 cite that job as proof of the end-to-end chain.

## Fixes, each proven before being proposed

| defect | fix | proven |
|---|---|---|
| no Go package | `managed.override` `file_option: go_package_prefix`, value `<reverse-domain>/<project-name>/gen/go` | buf rc=0, all three archetypes |
| tonic reads prost output | tonic `opt: no_include=true` | rc=0, writes `<pkg>.tonic.rs` (15 KB) |
| TS import path | point it at what buf writes | `tsc --noEmit` rc=0, `vite build` rc=0, no shim |
| flagship symbol | realign to `ExampleService` / `Ping`, and its one consumer | same |

## Scope

**In:** the three live `buf.gen.yaml.tmpl` (ai-native-rag 1.0.0, event-driven-eu 1.0.0,
full-stack-monorepo 2.0.0); the two `connect-client.ts.tmpl` and the flagship's
`index.tsx.tmpl` consumer; the matching files in `examples/forge-rag-example` and
`examples/forge-eda-example`, which follow the templates (ADR-T8ETP-001); the guards —
`b7-6::T-B05` derived rather than pinned to the literal, `T-C02` failing closed, `T-C04`
given a real body; the records.

**In (added in review):** `full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl` and its
`examples/forge-fsm-example` render. This brick first excluded them as "frozen", on a
rationale review proved false — BASE comes from the snapshot tarball, not the template
tree — and, decisively, `scaffold-plan-2.0.0.yaml:174` inherits this 1.0.0 manifest, so a
fresh `forge init` of the *stable* flagship renders it. Excluding it left the headline
claim untrue on the default path (ADR-T8CRB-002).

**Also out:** `buf lint` failures on a fresh render (a separate defect found while
measuring, Q-002); the Go stubs being generated into a Rust crate directory at all (Q-003).

## Negative scope

MUST NOT touch the frozen 1.0.0 template or its example. MUST NOT move any pinned plugin
version. MUST NOT make a guard green by pinning the string it is supposed to derive.
