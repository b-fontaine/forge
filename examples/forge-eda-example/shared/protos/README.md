# shared/protos — Connect/gRPC contracts (forge-eda-example)

buf module (transport.yaml SSoT). `task proto` (or `buf generate`) emits:

- Rust gRPC/Connect stubs → `backend/gen/rust/` (neoeinstein-tonic + -prost)
- TS Connect client → `shared/protos/gen/ts/`
- Go (forward-compat) → `shared/protos/gen/go/`

`transport.yaml` (`derived_outputs: [openapi-3.1, asyncapi-3.1]`) also derives the
AsyncAPI event contract surface from the same source of truth; the authored event
contracts live in `shared/asyncapi/`.

> Codegen is a documented adopter/codegen step — the backend crates consume Connect
> BY REFERENCE (no `tonic`/`prost` pin inlined in `backend/Cargo.toml`), mirroring
> the ai-native-rag precedent (B.7.2). Pins for the Connect Rust crate family live
> in `transport.yaml`, not here.
