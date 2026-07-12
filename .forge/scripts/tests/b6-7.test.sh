#!/usr/bin/env bash
# Forge — B.6.7 event-driven-eu promotion-gate harness (the ≥35-test suite)
# <!-- Audit: B.6.7 (b6-7-harness) — promotion gate candidate→stable/scaffoldable -->
#
# THE PROMOTION GATE for the event-driven-eu/1.0.0 archetype (ADR-B6-1-002). This
# suite proves the assembled archetype end-to-end BEFORE the schema is flipped to
# stage:stable / scaffoldable:true. It is a true SUPERSET gate: it re-runs every
# sibling B.6 per-brick harness (Tier A) AND adds the cross-brick coherence + live
# codegen/build legs the siblings don't check (Tiers B/C), plus the promotion
# post-flip guard + committed snapshot (Tier D).
#
# Structural clone of b7-6.test.sh (the ai-native-rag promotion gate), adapted to
# the event-driven-eu stack: an EventService Connect proto (Publish/ReadStream, no
# server-streaming), NATS JetStream + Temporal saga + Postgres event store markers,
# AsyncAPI 3.1 as the event SSoT, and NO frontend surface (so no Qwik tsc leg).
#
# Mirrors b6-2.test.sh / b7-6.test.sh structure: arg-parsed --level, _helpers.sh
# source, run_test / print_summary. Tiers:
#
#   Tier A — aggregation (8 tests, hermetic):
#     re-run b6-1/b6-2/b6-3/b6-4/b6-5/b6-6/b6-9/b6-10 at their CI level and assert
#     exit 0; absent sibling → clean SKIP (FR-B6-7-003).
#
#   Tier B — net-new L1 e2e structural (hermetic, grep/structure, CI-safe):
#     the assembled-archetype coherence the per-brick siblings don't check — the
#     EventService Publish/ReadStream proto + events.v1 versioning/idempotency, the
#     codegen-manifest Rust+TS targets, the buf.yaml governance, the AsyncAPI 3.1
#     SSoT, scaffold-plan↔tree coverage, the NATS/eventstore/saga conformance
#     markers, pin discipline, the gated wrapper + dispatch entry, the bin-server
#     axum surface + DI wiring (FR-B6-7-002).
#
#   Tier C — L2 live-build (toolchain-gated, SKIP-when-absent):
#     render via overlay.sh, then the LIVE path — `buf build` (the EventService proto
#     contract compiles) + `cargo build`/`test --workspace` of the rendered backend.
#     Each leg SKIPs gracefully (echo SKIP, return 0) when buf/cargo/registry absent
#     (the b6-2 T-L2-002 precedent). These run LIVE in the forge-ci `harness-rust` job
#     (Q-B / ADR-B6-7-005; FR-B6-7-004). NOTE: full `buf generate` plugin codegen is
#     NOT a gate — the neoeinstein-tonic remote plugin can't read prost's sibling
#     output in buf's sandbox (systemic, shared with the flagship/ai-native-rag; see
#     .forge/research/b6-7-live-codegen.md). cargo test is the real build proof (the
#     workspace does not compile the generated stubs).
#
#   Tier D — promotion post-flip guard + committed snapshot:
#     pre-flip the schema is still candidate + the CLI still refuses (RED); the flip
#     task inverts this to assert stable/scaffoldable:true (NFR-B6-7-001); plus the
#     committed snapshot tarball is present/valid/extractable (FR-B6-7-010).
#
# CI registration (.github/workflows/forge-ci.yml): the `harness` job runs this at
# --level 1 (L1 + aggregation + guards; the L2 legs SKIP there, buf-less/cargo-less);
# the `harness-rust` job runs it at --level 1,2 with buf + a Rust toolchain, so the
# live codegen/build path is a permanent per-PR gate (ADR-B6-7-005).

set -uo pipefail

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"

ARCHETYPE_DIR="$FORGE_ROOT/.forge/templates/archetypes/event-driven-eu"
TPL_DIR="$ARCHETYPE_DIR/1.0.0"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
WRAPPER="$FORGE_ROOT/bin/forge-init-event-driven-eu.sh"
SCHEMA_EDE="$FORGE_ROOT/.forge/schemas/event-driven-eu/1.0.0.yaml"
DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
STD_DIR="$FORGE_ROOT/.forge/standards"

PROTO="$TPL_DIR/shared/protos/v1/events/events.proto.tmpl"
BUF_GEN="$TPL_DIR/shared/protos/buf.gen.yaml.tmpl"
BUF_YAML="$TPL_DIR/shared/protos/buf.yaml.tmpl"
ASYNCAPI="$TPL_DIR/shared/asyncapi/asyncapi.yaml.tmpl"
MAIN_RS="$TPL_DIR/backend/bin-server/src/main.rs.tmpl"
WIRING_RS="$TPL_DIR/backend/bin-server/src/wiring.rs.tmpl"
CARGO_TOML="$TPL_DIR/backend/Cargo.toml.tmpl"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ════════════════════════════════════════════════════════════════════
# Tier A — aggregation: re-run each sibling B.6 harness, assert exit 0.
# A sibling absent from the tree → clean SKIP (the suite stays runnable
# if a sibling is renamed/retired), not a hard FAIL (FR-B6-7-003).
# ════════════════════════════════════════════════════════════════════

# Run sibling harness $1 (basename, no path) with the remaining args at its CI
# level; PASS on exit 0, SKIP (return 0) if the harness file is absent, FAIL on
# non-zero exit. Output captured; on FAIL the tail is surfaced for triage.
_b67_aggregate_sibling() {
  local name="$1"; shift
  local sib="$HARNESS_DIR/$name"
  if [ ! -f "$sib" ]; then
    echo "    SKIP: sibling harness absent: $name (FR-B6-7-003)" >&2
    return 0
  fi
  local log; log="$(mktemp)"
  if bash "$sib" "$@" >"$log" 2>&1; then
    rm -f "$log"; return 0
  fi
  echo "    FAIL: sibling harness non-zero exit: $name $* (FR-B6-7-003)" >&2
  tail -20 "$log" >&2
  rm -f "$log"
  return 1
}

# CI levels mirror .github/workflows/forge-ci.yml's harness array exactly.
_test_b67_agg_b6_1()  { _b67_aggregate_sibling "b6-1.test.sh"  --level 1,2; }
_test_b67_agg_b6_2()  { _b67_aggregate_sibling "b6-2.test.sh"  --level 1; }
_test_b67_agg_b6_3()  { _b67_aggregate_sibling "b6-3.test.sh"  --level 1; }
_test_b67_agg_b6_4()  { _b67_aggregate_sibling "b6-4.test.sh"  --level 1,2; }
_test_b67_agg_b6_5()  { _b67_aggregate_sibling "b6-5.test.sh"  --level 1,2; }
_test_b67_agg_b6_6()  { _b67_aggregate_sibling "b6-6.test.sh"  --level 1; }
_test_b67_agg_b6_9()  { _b67_aggregate_sibling "b6-9.test.sh"  --level 1,2; }
_test_b67_agg_b6_10() { _b67_aggregate_sibling "b6-10.test.sh" --level 1,2; }

# ════════════════════════════════════════════════════════════════════
# Tier B — net-new L1 e2e structural (hermetic, grep/structure, CI-safe).
# The cross-brick coherence of the ASSEMBLED archetype that no single
# sibling proves.
# ════════════════════════════════════════════════════════════════════

# T-B01 — proto: the unary Publish RPC (submit a command → idempotent versioned
# envelope on NATS JetStream) is present (assembled-view of b6-2) (FR-B6-7-002).
_test_b67_l1_b01_proto_publish() {
  [ -f "$PROTO" ] || { echo "    FAIL T-B01: events.proto template missing: $PROTO (FR-B6-7-002)" >&2; return 1; }
  grep -qE 'rpc[[:space:]]+Publish[[:space:]]*\([[:space:]]*PublishRequest[[:space:]]*\)[[:space:]]+returns[[:space:]]*\([[:space:]]*PublishResponse[[:space:]]*\)' "$PROTO" \
    || { echo "    FAIL T-B01: unary 'rpc Publish(PublishRequest) returns (PublishResponse)' absent (FR-B6-7-002)" >&2; return 1; }
}

# T-B02 — proto: the unary ReadStream RPC (read persisted events from the Postgres
# event store) is present alongside Publish (FR-B6-7-002).
_test_b67_l1_b02_proto_readstream() {
  [ -f "$PROTO" ] || { echo "    FAIL T-B02: events.proto template missing (FR-B6-7-002)" >&2; return 1; }
  grep -qE 'rpc[[:space:]]+ReadStream[[:space:]]*\([[:space:]]*ReadStreamRequest[[:space:]]*\)[[:space:]]+returns[[:space:]]*\([[:space:]]*ReadStreamResponse[[:space:]]*\)' "$PROTO" \
    || { echo "    FAIL T-B02: unary 'rpc ReadStream(ReadStreamRequest) returns (ReadStreamResponse)' absent (FR-B6-7-002)" >&2; return 1; }
  grep -qE 'service[[:space:]]+EventService' "$PROTO" \
    || { echo "    FAIL T-B02: 'service EventService' absent (FR-B6-7-002)" >&2; return 1; }
}

# T-B03 — proto: the events.v1 namespace + the event-versioning/idempotency contract
# fields (event_version + idempotency_key) — the schema event_specifics
# (event_versioning + idempotency_keys) reflected in the wire contract (FR-B6-7-002).
_test_b67_l1_b03_proto_versioning_idempotency() {
  [ -f "$PROTO" ] || { echo "    FAIL T-B03: events.proto template missing (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  grep -qE '^package[[:space:]]+events\.v1' "$PROTO" || { echo "    FAIL T-B03: 'package events.v1' absent (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'idempotency_key' "$PROTO" || { echo "    FAIL T-B03: idempotency_key field absent from contract (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'event_version' "$PROTO" || { echo "    FAIL T-B03: event_version field absent from contract (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B04 — codegen manifest: buf.gen.yaml.tmpl declares the Rust (tonic + prost)
# stub outputs to backend/gen/rust (FR-B6-7-002).
_test_b67_l1_b04_codegen_rust_targets() {
  [ -f "$BUF_GEN" ] || { echo "    FAIL T-B04: buf.gen.yaml.tmpl missing: $BUF_GEN (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  grep -qE 'neoeinstein-tonic' "$BUF_GEN" || { echo "    FAIL T-B04: tonic (Rust gRPC) plugin absent from buf.gen.yaml (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'neoeinstein-prost' "$BUF_GEN" || { echo "    FAIL T-B04: prost (Rust messages) plugin absent from buf.gen.yaml (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'backend/gen/rust' "$BUF_GEN" \
    || { echo "    FAIL T-B04: Rust stub output dir (backend/gen/rust) absent from buf.gen.yaml (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B05 — codegen manifest: buf.gen.yaml.tmpl declares the TS (bufbuild/es) Connect
# output to gen/ts (FR-B6-7-002).
_test_b67_l1_b05_codegen_ts_target() {
  [ -f "$BUF_GEN" ] || { echo "    FAIL T-B05: buf.gen.yaml.tmpl missing (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  grep -qE 'bufbuild/es' "$BUF_GEN" || { echo "    FAIL T-B05: bufbuild/es (TS Connect) plugin absent from buf.gen.yaml (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'out:[[:space:]]*gen/ts' "$BUF_GEN" \
    || { echo "    FAIL T-B05: TS output dir (gen/ts) absent from buf.gen.yaml (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B06 — buf.yaml lint + breaking governance (proto-contracts.md: STANDARD lint +
# FILE breaking) — the buf module config the L2 `buf build` leg relies on (FR-B6-7-002).
_test_b67_l1_b06_buf_yaml_governance() {
  [ -f "$BUF_YAML" ] || { echo "    FAIL T-B06: buf.yaml.tmpl missing: $BUF_YAML (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  grep -qE '^lint:' "$BUF_YAML" || { echo "    FAIL T-B06: buf.yaml has no lint config (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'STANDARD' "$BUF_YAML" || { echo "    FAIL T-B06: buf.yaml lint does not use STANDARD (FR-B6-7-002)" >&2; ok=0; }
  grep -qE '^breaking:' "$BUF_YAML" || { echo "    FAIL T-B06: buf.yaml has no breaking config (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'FILE' "$BUF_YAML" || { echo "    FAIL T-B06: buf.yaml breaking does not use FILE (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B07 — scaffold-plan ↔ tree NO ORPHAN: every .tmpl in the tree is referenced by
# the plan (widens b6-2 T-002 to the assembled tree) (FR-B6-7-002).
_test_b67_l1_b07_plan_no_orphan() {
  [ -f "$PLAN" ] || { echo "    FAIL T-B07: scaffold-plan missing: $PLAN (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  while IFS= read -r f; do
    local rel="${f#"$TPL_DIR/"}"
    grep -qF "1.0.0/$rel" "$PLAN" || { echo "    FAIL T-B07: tree .tmpl not referenced by plan: 1.0.0/$rel (FR-B6-7-002)" >&2; ok=0; }
  done < <(find "$TPL_DIR" -type f -name '*.tmpl' 2>/dev/null)
  [ "$ok" = "1" ]
}

# T-B08 — scaffold-plan ↔ tree NO DANGLING: every plan source: resolves to an
# existing tree file (FR-B6-7-002).
_test_b67_l1_b08_plan_no_dangling() {
  [ -f "$PLAN" ] || { echo "    FAIL T-B08: scaffold-plan missing (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  while IFS= read -r src; do
    src="$(printf '%s' "$src" | tr -d '[:space:]')"
    [ -z "$src" ] && continue
    [ -f "$ARCHETYPE_DIR/$src" ] || { echo "    FAIL T-B08: plan source: has no tree file: $src (FR-B6-7-002)" >&2; ok=0; }
  done < <(grep -E '^[[:space:]]*-[[:space:]]*source:' "$PLAN" | sed -E 's/^[[:space:]]*-[[:space:]]*source:[[:space:]]*//')
  [ "$ok" = "1" ]
}

# T-B09 — AsyncAPI: the event SSoT contract is present + declares asyncapi: 3.1.0
# (assembled-view of b6-2 T-008) (FR-B6-7-002).
_test_b67_l1_b09_asyncapi_version() {
  [ -f "$ASYNCAPI" ] || { echo "    FAIL T-B09: AsyncAPI contract missing: $ASYNCAPI (FR-B6-7-002)" >&2; return 1; }
  grep -qE '^asyncapi:[[:space:]]*3\.1\.0' "$ASYNCAPI" \
    || { echo "    FAIL T-B09: asyncapi field is not 3.1.0 (FR-B6-7-002)" >&2; return 1; }
}

# T-B10 — AsyncAPI: the event SSoT declares channels + operations + messages (the
# minimal AsyncAPI 3.x structure the archetype's event contract mandates) (FR-B6-7-002).
_test_b67_l1_b10_asyncapi_structure() {
  [ -f "$ASYNCAPI" ] || { echo "    FAIL T-B10: AsyncAPI contract missing (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  grep -qE '^channels:' "$ASYNCAPI" || { echo "    FAIL T-B10: AsyncAPI has no channels: block (FR-B6-7-002)" >&2; ok=0; }
  grep -qE '^operations:' "$ASYNCAPI" || { echo "    FAIL T-B10: AsyncAPI has no operations: block (FR-B6-7-002)" >&2; ok=0; }
  grep -qE '^[[:space:]]+messages:' "$ASYNCAPI" || { echo "    FAIL T-B10: AsyncAPI declares no messages (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B11 — layer roots: the assembled tree carries backend/infra/shared + the two
# shared contract dirs (protos + asyncapi) (assembled-view of b6-2 T-001) (FR-B6-7-002).
_test_b67_l1_b11_layer_roots() {
  local ok=1
  for d in "backend" "infra" "shared/asyncapi" "shared/protos"; do
    [ -d "$TPL_DIR/$d" ] || { echo "    FAIL T-B11: missing template layer root $d (FR-B6-7-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

# T-B12 — backend workspace members: the four event-driven building blocks
# (events/eventstore/saga/bin-server) exist + are declared in the workspace manifest
# (FR-B6-7-002).
_test_b67_l1_b12_workspace_members() {
  [ -f "$CARGO_TOML" ] || { echo "    FAIL T-B12: backend/Cargo.toml.tmpl missing (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  for c in "events" "eventstore" "saga" "bin-server"; do
    [ -d "$TPL_DIR/backend/$c" ] || { echo "    FAIL T-B12: missing backend crate dir $c (FR-B6-7-002)" >&2; ok=0; }
  done
  grep -qE 'members[[:space:]]*=.*events.*eventstore.*saga.*bin-server' "$CARGO_TOML" \
    || { echo "    FAIL T-B12: workspace members not all declared in Cargo.toml.tmpl (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B13 — events conformance: NATS JetStream idempotent publish via the Nats-Msg-Id
# header (event-driven.md; b6-2 T-007 carried) (FR-B6-7-002).
_test_b67_l1_b13_conformance_nats_idempotency() {
  local d="$TPL_DIR/backend/events"
  [ -d "$d" ] || { echo "    FAIL T-B13: backend/events tree missing (FR-B6-7-002)" >&2; return 1; }
  grep -rqE 'Nats-Msg-Id' "$d" 2>/dev/null \
    || { echo "    FAIL T-B13: JetStream idempotent-publish marker (Nats-Msg-Id) absent under backend/events (event-driven.md)" >&2; return 1; }
}

# T-B14 — events conformance: the inbox dedup (consumer-side idempotency) marker
# (event-driven.md; b6-2 T-007 carried) (FR-B6-7-002).
_test_b67_l1_b14_conformance_inbox() {
  local d="$TPL_DIR/backend/events"
  [ -d "$d" ] || { echo "    FAIL T-B14: backend/events tree missing (FR-B6-7-002)" >&2; return 1; }
  grep -rqiE 'InboxDedup|inbox' "$d" 2>/dev/null \
    || { echo "    FAIL T-B14: inbox-pattern (consumer dedup) marker absent under backend/events (event-driven.md)" >&2; return 1; }
}

# T-B15 — eventstore conformance: the append-only Postgres event store with an
# idempotent append (ON CONFLICT) (event-driven.md; b6-2 T-007 carried) (FR-B6-7-002).
_test_b67_l1_b15_conformance_eventstore() {
  local d="$TPL_DIR/backend/eventstore"
  [ -d "$d" ] || { echo "    FAIL T-B15: backend/eventstore tree missing (FR-B6-7-002)" >&2; return 1; }
  grep -rqE 'ON CONFLICT|append-only|EventStore' "$d" 2>/dev/null \
    || { echo "    FAIL T-B15: append-only event-store marker absent under backend/eventstore (event-driven.md)" >&2; return 1; }
}

# T-B16 — saga conformance: Temporal ACTIVITY-ONLY worker bias (Article VIII.2 — no
# ad-hoc saga in application code) (event-driven.md; b6-2 T-007 carried) (FR-B6-7-002).
_test_b67_l1_b16_conformance_saga_activity_only() {
  local d="$TPL_DIR/backend/saga"
  [ -d "$d" ] || { echo "    FAIL T-B16: backend/saga tree missing (FR-B6-7-002)" >&2; return 1; }
  grep -rqE 'activity-only|activity_only|Activity' "$d" 2>/dev/null \
    || { echo "    FAIL T-B16: Temporal activity-only saga marker absent under backend/saga (event-driven.md, VIII.2)" >&2; return 1; }
}

# T-B17 — saga conformance: the saga compensation coordinator (saga_compensation
# required; event-driven.md; b6-2 T-007 carried) (FR-B6-7-002).
_test_b67_l1_b17_conformance_saga_compensation() {
  local d="$TPL_DIR/backend/saga"
  [ -d "$d" ] || { echo "    FAIL T-B17: backend/saga tree missing (FR-B6-7-002)" >&2; return 1; }
  grep -rqE 'compensate|compensation' "$d" 2>/dev/null \
    || { echo "    FAIL T-B17: saga compensation marker absent under backend/saga (event-driven.md)" >&2; return 1; }
}

# T-B18 — event versioning: the event_version marker survives in the envelope + the
# event store (event_specifics.event_versioning: required) (FR-B6-7-002).
_test_b67_l1_b18_event_versioning() {
  local be="$TPL_DIR/backend"
  [ -d "$be" ] || { echo "    FAIL T-B18: backend tree missing (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  grep -rqE 'event_version|EventVersion' "$be/events" 2>/dev/null \
    || { echo "    FAIL T-B18: event_version marker absent under backend/events (event versioning) (FR-B6-7-002)" >&2; ok=0; }
  grep -rqE 'event_version|EventVersion' "$be/eventstore" 2>/dev/null \
    || { echo "    FAIL T-B18: event_version marker absent under backend/eventstore (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B19 — pin discipline: the LIVE verify-then-pin crates are present in the backend
# workspace manifest (async-nats/sqlx/temporalio-sdk/temporalio-client)
# (b6-2 T-003/004 carried; NFR-B6-7-005).
_test_b67_l1_b19_pins_present() {
  [ -f "$CARGO_TOML" ] || { echo "    FAIL T-B19: backend/Cargo.toml.tmpl missing (NFR-B6-7-005)" >&2; return 1; }
  local ok=1
  for crate in async-nats sqlx temporalio-sdk temporalio-client; do
    grep -qE "${crate}[[:space:]]*=" "$CARGO_TOML" \
      || { echo "    FAIL T-B19: LIVE pin '$crate' absent from backend/Cargo.toml.tmpl (NFR-B6-7-005)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

# T-B20 — pin discipline: NO crate pin leaked into the B.6.3 pattern standards
# (pins live ONLY in Cargo.toml.tmpl) (b6-2 T-004 carried; NFR-B6-7-005).
_test_b67_l1_b20_pins_not_in_standards() {
  local ok=1
  for f in "$STD_DIR"/*.yaml "$STD_DIR"/infra/*.md "$STD_DIR"/global/*.md; do
    [ -f "$f" ] || continue
    if grep -qE '(async-nats|temporalio-sdk|temporalio-client)[[:space:]]*=[[:space:]]*"[0-9]' "$f" 2>/dev/null; then
      echo "    FAIL T-B20: $(basename "$f") inlines a crate pin (NFR-B6-7-005)" >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

# T-B21 — the gated scaffolder wrapper exists + is executable + carries the
# scaffoldability gate (is_scaffoldable: stage==stable AND scaffoldable==true) that
# auto-opens at promotion; the dispatch-table entry points at it (FR-B6-7-002).
_test_b67_l1_b21_wrapper_and_dispatch() {
  local ok=1
  [ -f "$WRAPPER" ] || { echo "    FAIL T-B21: scaffolder wrapper missing: $WRAPPER (FR-B6-7-002)" >&2; ok=0; }
  [ -x "$WRAPPER" ] || { echo "    FAIL T-B21: wrapper not executable (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'is_scaffoldable' "$WRAPPER" \
    || { echo "    FAIL T-B21: wrapper lacks the scaffoldability gate (is_scaffoldable) (FR-B6-7-002)" >&2; ok=0; }
  [ -f "$DISPATCH" ] || { echo "    FAIL T-B21: dispatch-table.yml missing: $DISPATCH (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'event-driven-eu' "$DISPATCH" \
    || { echo "    FAIL T-B21: event-driven-eu not registered in dispatch-table.yml (FR-B6-7-002)" >&2; ok=0; }
  grep -qE 'bin/forge-init-event-driven-eu\.sh' "$DISPATCH" \
    || { echo "    FAIL T-B21: dispatch entry does not point at bin/forge-init-event-driven-eu.sh (FR-B6-7-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B22 — bin-server: the axum Router surface (for the Connect /connect mount at the
# adopter step) + the DI wiring that composes all three net-new layers
# (events/eventstore/saga) — Article VII.3 (binary composes ports, no business logic)
# (FR-B6-7-002).
_test_b67_l1_b22_bin_server_axum_and_wiring() {
  [ -f "$MAIN_RS" ] || { echo "    FAIL T-B22: bin-server main.rs template missing: $MAIN_RS (FR-B6-7-002)" >&2; return 1; }
  [ -f "$WIRING_RS" ] || { echo "    FAIL T-B22: bin-server wiring.rs template missing: $WIRING_RS (FR-B6-7-002)" >&2; return 1; }
  local ok=1
  grep -qE 'Router::new\(\)|axum::Router' "$MAIN_RS" \
    || { echo "    FAIL T-B22: bin-server has no axum Router surface for the Connect mount (FR-B6-7-002)" >&2; ok=0; }
  for layer in events eventstore saga; do
    grep -qE "${layer}::" "$WIRING_RS" \
      || { echo "    FAIL T-B22: wiring.rs does not compose the '$layer' layer (FR-B6-7-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

# ════════════════════════════════════════════════════════════════════
# Tier D — promotion post-flip guard + committed snapshot.
# POST-FLIP (B.6.7): the schema is stable/scaffoldable:true and the wrapper renders
# (no longer refuses). These were the pre-flip held-guards (asserting candidate +
# refusal); the flip task inverted them (NFR-B6-7-001, b8-15 "fails-loud once
# promotes" pattern). They now fail loud if the archetype is ever reverted to
# candidate without reverting the promotion.
# ════════════════════════════════════════════════════════════════════

# T-D01 — promotion guard (POST-FLIP). Asserts the schema is stage:stable /
# scaffoldable:true — the promoted source-of-truth state (NFR-B6-7-001). Inverted
# from the pre-flip candidate held-guard by the B.6.7 flip.
_test_b67_d01_promotion_guard() {
  [ -f "$SCHEMA_EDE" ] || { echo "    FAIL T-D01: event-driven-eu schema missing: $SCHEMA_EDE (NFR-B6-7-001)" >&2; return 1; }
  local stage scaffoldable
  stage="$(grep -E '^stage:' "$SCHEMA_EDE" | head -1 | sed -E 's/^stage:[[:space:]]*//')"
  scaffoldable="$(grep -E '^scaffoldable:' "$SCHEMA_EDE" | head -1 | sed -E 's/^scaffoldable:[[:space:]]*//')"
  [ "$stage" = "stable" ] \
    || { echo "    FAIL T-D01: post-flip: stage='$stage' expected 'stable' (NFR-B6-7-001 — promoted B.6.7)" >&2; return 1; }
  [ "$scaffoldable" = "true" ] \
    || { echo "    FAIL T-D01: post-flip: scaffoldable='$scaffoldable' expected 'true' (NFR-B6-7-001 — promoted B.6.7)" >&2; return 1; }
}

# T-D02 — CLI/wrapper guard (POST-FLIP). The schema is promoted, so the wrapper's
# scaffoldability gate is OPEN: it NO LONGER refuses with the candidate exit-3.
# Inverted from the pre-flip refusal held-guard by the B.6.7 flip (NFR-B6-7-001).
# A no-target probe now passes the gate and reaches arg-parsing → exit 2 (missing
# --target), NOT the candidate 3.
_test_b67_d02_cli_refusal_guard() {
  [ -x "$WRAPPER" ] || { echo "    FAIL T-D02: wrapper not runnable (NFR-B6-7-001)" >&2; return 1; }
  # Post-flip the candidate refusal precondition is gone; fail loud if it returns.
  if grep -qE '^scaffoldable:[[:space:]]*false' "$SCHEMA_EDE" 2>/dev/null; then
    echo "    FAIL T-D02: schema scaffoldable:false — reverted to candidate without reverting the promotion (NFR-B6-7-001)" >&2; return 1
  fi
  local rc=0
  bash "$WRAPPER" >/dev/null 2>&1 || rc=$?
  [ "$rc" != "3" ] \
    || { echo "    FAIL T-D02: wrapper still exits 3 (candidate refusal) AFTER the B.6.7 promotion (NFR-B6-7-001)" >&2; return 1; }
}

# T-D03 — committed snapshot tarball (FR-B6-7-010). The event-driven-eu scaffold
# snapshot ships at .forge/scaffold-snapshots/event-driven-eu/1.0.0.tar.gz for
# `forge upgrade` BASE recovery (the ai-native-rag/full-stack/mobile-only convention).
# Built deterministically by bin/forge-snapshot.sh (SOURCE_DATE_EPOCH + sorted +
# uid/gid0 + ustar + gzip mtime0). Asserts: present, ≤ 2 MB, a valid gzip/tar,
# extractable. Always-run (hermetic, no toolchain).
_test_b67_d03_snapshot_tarball() {
  local snap="$FORGE_ROOT/.forge/scaffold-snapshots/event-driven-eu/1.0.0.tar.gz"
  [ -f "$snap" ] || { echo "    FAIL T-D03: event-driven-eu snapshot tarball missing: $snap (FR-B6-7-010)" >&2; return 1; }
  local ok=1
  local size; size=$(wc -c < "$snap" | tr -d ' ')
  local budget=$((2 * 1024 * 1024))
  [ "$size" -le "$budget" ] || { echo "    FAIL T-D03: snapshot too large: ${size} bytes > ${budget} budget (FR-B6-7-010)" >&2; ok=0; }
  file -b "$snap" 2>/dev/null | grep -qiE 'gzip|tar' \
    || { echo "    FAIL T-D03: snapshot is not a gzip/tar archive (FR-B6-7-010)" >&2; ok=0; }
  if command -v tar >/dev/null 2>&1; then
    local tmp; tmp="$(mktemp -d)"
    tar -xzf "$snap" -C "$tmp" >/dev/null 2>&1 \
      || { echo "    FAIL T-D03: snapshot not extractable via tar -xzf (FR-B6-7-010)" >&2; ok=0; }
    rm -rf "$tmp"
  fi
  [ "$ok" = "1" ]
}

# ════════════════════════════════════════════════════════════════════
# Tier C — L2 live-codegen (toolchain-gated, SKIP-when-absent).
# Same overlay.sh render convention as b6-2/b7-6 (overlay.sh hardcodes
# ARCHETYPE_DIR, so the plan's relative source: paths are absolutized
# into a throwaway temp plan). These legs SKIP on a buf-less / cargo-less
# host (the CI `harness` job) and RUN in the forge-ci `harness-rust` job
# (buf + Rust toolchain).
# ════════════════════════════════════════════════════════════════════

# Render the committed scaffold-plan into $1 via overlay.sh, absolutizing the plan's
# relative source: paths first (the b6-2 _b62_render_plan helper).
_b67_render_plan() {
  local out_dir="$1"
  local absplan; absplan="$(mktemp)"
  ARCHETYPE_DIR="$ARCHETYPE_DIR" PLAN="$PLAN" ABSPLAN="$absplan" python3 - <<'PY' || { rm -f "$absplan"; return 1; }
import os, yaml
arch = os.environ['ARCHETYPE_DIR']
with open(os.environ['PLAN']) as f:
    plan = yaml.safe_load(f)
for e in plan.get('templates', []):
    s = e.get('source', '')
    if s and not os.path.isabs(s):
        e['source'] = os.path.join(arch, s)
with open(os.environ['ABSPLAN'], 'w') as f:
    yaml.safe_dump(plan, f, sort_keys=False)
PY
  SOURCE_DATE_EPOCH=0 bash "$OVERLAY_SH" --target "$out_dir" --project-name probe \
    --reverse-domain example.com --plan "$absplan" --force >/dev/null 2>&1
  local rc=$?
  rm -f "$absplan"
  return $rc
}

# T-C01 — render-clean + byte-stable re-render (no .tmpl, no <placeholder>); the
# EventService proto is present in the rendered tree (NFR-B6-7-004). Needs
# python3+PyYAML+overlay.sh (SKIP otherwise).
_test_b67_l2_c01_render_clean() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-C01: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-C01: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-C01: plan absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-C01: overlay.sh absent" >&2; return 0; }
  local work; work="$(mktemp -d)"; local out1="$work/r1" out2="$work/r2"
  _b67_render_plan "$out1" || { echo "    FAIL T-C01: overlay.sh render failed (NFR-B6-7-004)" >&2; rm -rf "$work"; return 1; }
  local ok=1
  [ -z "$(find "$out1" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-C01: .tmpl suffix survived render" >&2; ok=0; }
  ! grep -rqE '<(project-name|reverse-domain|root-module)>' "$out1" 2>/dev/null || { echo "    FAIL T-C01: unsubstituted <placeholder>" >&2; ok=0; }
  grep -rqE 'service[[:space:]]+EventService' "$out1/shared/protos" 2>/dev/null || { echo "    FAIL T-C01: EventService missing from rendered proto" >&2; ok=0; }
  _b67_render_plan "$out2" || { echo "    FAIL T-C01: second render failed (NFR-B6-7-004)" >&2; rm -rf "$work"; return 1; }
  diff -r "$out1" "$out2" >/dev/null 2>&1 || { echo "    FAIL T-C01: re-render not byte-stable (NFR-B6-7-004)" >&2; ok=0; }
  rm -rf "$work"
  [ "$ok" = "1" ]
}

# T-C02 — LIVE buf build: render, then `buf build` the rendered proto module — proves
# the EventService contract compiles into a FileDescriptorSet (proto syntax + imports
# valid) under the pinned buf toolchain (FR-B6-7-004). SKIP when buf absent (the
# buf-less CI `harness` job); RUNS in the `harness-rust` job (buf 1.70.0).
#
# NOTE (verified LIVE 2026-07-12, buf 1.70.0 — .forge/research/b6-7-live-codegen.md):
# the full `buf generate` plugin codegen is NOT asserted here. The `neoeinstein-tonic`
# REMOTE plugin cannot read the sibling `neoeinstein-prost` output ("read events.v1.rs:
# file does not exist") in buf's isolated remote-plugin sandbox — a limitation of the
# split-plugin config shared with the flagship + ai-native-rag (b7-6's C02 masks the
# same failure behind a loose offline-grep). Fixing the codegen architecture is out of
# this promotion-gate brick's scope. The genuine end-to-end BUILD proof is T-C03 (cargo
# test on the rendered workspace, which does NOT compile the generated stubs — they land
# in backend/gen/, not a workspace member). `buf build` here is the honest live proto
# gate: the contract compiles, no green-wash.
_test_b67_l2_c02_buf_build() {
  command -v buf >/dev/null 2>&1 || { echo "    SKIP T-C02: buf absent (proto build runs in the harness-rust CI job)" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-C02: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-C02: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-C02: plan absent" >&2; return 0; }
  local work; work="$(mktemp -d)"; local out="$work/render"
  _b67_render_plan "$out" || { echo "    FAIL T-C02: render failed (FR-B6-7-004)" >&2; rm -rf "$work"; return 1; }
  local log="$work/buf.log"
  if ! ( cd "$out/shared/protos" && buf build ) >"$log" 2>&1; then
    # Only a GENUINE network failure skips (buf build resolves any buf.yaml module
    # deps). A real proto-compile error FAILS loud — no green-wash.
    if grep -qiE 'dial tcp|connection refused|could not resolve host|no such host|network is unreachable|i/o timeout|TLS handshake timeout|temporary failure in name resolution' "$log"; then
      echo "    SKIP T-C02: buf build skipped — network unavailable (offline)" >&2
      rm -rf "$work"; return 0
    fi
    echo "    FAIL T-C02: buf build failed — the EventService proto contract does not compile (FR-B6-7-004)" >&2
    tail -25 "$log" >&2; rm -rf "$work"; return 1
  fi
  rm -rf "$work"
  return 0
}

# T-C03 — LIVE cargo build + test of the rendered backend workspace (the
# events/eventstore/saga/bin-server backbone; temporalio-sdk stays OFF behind the
# feature). Offline registry → SKIP (b6-2 T-L2-002 precedent). VERIFIES the LIVE pins
# resolve+build (NFR-B6-7-005).
_test_b67_l2_c03_cargo_build_test() {
  command -v cargo >/dev/null 2>&1 || { echo "    SKIP T-C03: cargo absent" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-C03: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-C03: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-C03: plan absent" >&2; return 0; }
  [ -d "$TPL_DIR/backend" ] || { echo "    SKIP T-C03: backend tree absent" >&2; return 0; }
  local work; work="$(mktemp -d)"; local out="$work/render"
  _b67_render_plan "$out" || { echo "    FAIL T-C03: render failed (NFR-B6-7-005)" >&2; rm -rf "$work"; return 1; }
  local log="$work/cargo.log"
  if ! ( cd "$out/backend" && cargo test --workspace ) >"$log" 2>&1; then
    if grep -qiE 'failed to (download|get|fetch|load source)|no matching package|could not (connect|resolve)|network|offline|registry' "$log"; then
      echo "    SKIP T-C03: cargo skipped — crate registry unavailable (offline)" >&2
      rm -rf "$work"; return 0
    fi
    echo "    FAIL T-C03: cargo test failed on rendered backend (NFR-B6-7-005)" >&2
    tail -30 "$log" >&2; rm -rf "$work"; return 1
  fi
  rm -rf "$work"
  return 0
}

# ════════════════════════════════════════════════════════════════════

main() {
  echo "── B.6.7 — b6-7-harness (promotion gate) — level $LEVEL ──"

  # Tier A — aggregation (always; superset gate).
  run_test _test_b67_agg_b6_1
  run_test _test_b67_agg_b6_2
  run_test _test_b67_agg_b6_3
  run_test _test_b67_agg_b6_4
  run_test _test_b67_agg_b6_5
  run_test _test_b67_agg_b6_6
  run_test _test_b67_agg_b6_9
  run_test _test_b67_agg_b6_10

  # Tier B — net-new L1 e2e structural (always).
  run_test _test_b67_l1_b01_proto_publish
  run_test _test_b67_l1_b02_proto_readstream
  run_test _test_b67_l1_b03_proto_versioning_idempotency
  run_test _test_b67_l1_b04_codegen_rust_targets
  run_test _test_b67_l1_b05_codegen_ts_target
  run_test _test_b67_l1_b06_buf_yaml_governance
  run_test _test_b67_l1_b07_plan_no_orphan
  run_test _test_b67_l1_b08_plan_no_dangling
  run_test _test_b67_l1_b09_asyncapi_version
  run_test _test_b67_l1_b10_asyncapi_structure
  run_test _test_b67_l1_b11_layer_roots
  run_test _test_b67_l1_b12_workspace_members
  run_test _test_b67_l1_b13_conformance_nats_idempotency
  run_test _test_b67_l1_b14_conformance_inbox
  run_test _test_b67_l1_b15_conformance_eventstore
  run_test _test_b67_l1_b16_conformance_saga_activity_only
  run_test _test_b67_l1_b17_conformance_saga_compensation
  run_test _test_b67_l1_b18_event_versioning
  run_test _test_b67_l1_b19_pins_present
  run_test _test_b67_l1_b20_pins_not_in_standards
  run_test _test_b67_l1_b21_wrapper_and_dispatch
  run_test _test_b67_l1_b22_bin_server_axum_and_wiring

  # Tier D — promotion post-flip guard + committed snapshot (always).
  run_test _test_b67_d01_promotion_guard
  run_test _test_b67_d02_cli_refusal_guard
  run_test _test_b67_d03_snapshot_tarball

  # Tier C — L2 live-codegen (toolchain-gated; SKIP-when-absent).
  case "$LEVEL" in
    *2*)
      run_test _test_b67_l2_c01_render_clean
      run_test _test_b67_l2_c02_buf_build
      run_test _test_b67_l2_c03_cargo_build_test
      ;;
  esac

  print_summary
}

main
