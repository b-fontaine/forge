#!/usr/bin/env bash
# <!-- Audit: T.5 (t5-otel-live-run) — Phase D smoke driver -->
#
# Boots the fake OTLP collector (test/live-run/fake_otlp_collector.py),
# posts a hex-canned ExportTraceServiceRequest, asserts the resulting
# capture-NNN.json carries service_name + traceparent + resource_spans_count
# per FR-T5-OLR-020..028 and ADR-T5-OLR-004. Pure stdlib (bash + python3).
#
# Exit codes (FR-T5-OLR-026, single source of truth for the harness gate):
#   0 — all assertions PASS
#   1 — collector failed to start, probe failed, or an assertion failed
#   2 — missing toolchain (no python3 on PATH)

set -uo pipefail

# ── Argument parsing ────────────────────────────────────────────────
OUT=""
SCENARIO="direct"
PROBE_ONLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)          OUT="$2"; shift 2 ;;
    --scenario)     SCENARIO="$2"; shift 2 ;;
    --probe-only)   PROBE_ONLY=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--out DIR] [--scenario direct|kong] [--probe-only]
EOF
      exit 0
      ;;
    *) echo "run_smoke: unknown flag: $1" >&2; exit 1 ;;
  esac
done

case "$SCENARIO" in
  direct|kong) ;;
  *) echo "run_smoke: --scenario must be 'direct' or 'kong' (got '$SCENARIO')" >&2; exit 1 ;;
esac

if [ -z "$OUT" ]; then
  OUT=$(mktemp -d -t fsm-live-run-XXXXXX)
fi
mkdir -p "$OUT"

# ── Toolchain check (FR-T5-OLR-026 — exit 2) ───────────────────────
if ! command -v python3 >/dev/null 2>&1; then
  echo "run_smoke: python3 not on PATH" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COLLECTOR_PY="$SCRIPT_DIR/fake_otlp_collector.py"
if [ ! -f "$COLLECTOR_PY" ]; then
  echo "run_smoke: collector script missing: $COLLECTOR_PY" >&2
  exit 1
fi

# ── Hex-canned OTLP payloads (ADR-T5-OLR-004) ──────────────────────
# Both payloads carry resource.attributes.service.name = "fsm-backend"
# + exactly one ResourceSpans. The kong variant additionally carries
# host.name = "fsm-kong-gateway" (sanitiser collapses it to
# "<host:redacted>" in the capture — the only field that differs from
# the direct golden, modulo body_size_bytes).
case "$SCENARIO" in
  direct)
    HEX_PAYLOAD="0a210a1f0a1d0a0c736572766963652e6e616d65120d0a0b66736d2d6261636b656e64"
    ;;
  kong)
    HEX_PAYLOAD="0a420a400a1d0a0c736572766963652e6e616d65120d0a0b66736d2d6261636b656e640a1f0a09686f73742e6e616d6512120a1066736d2d6b6f6e672d67617465776179"
    ;;
esac

TRACEPARENT="00-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-bbbbbbbbbbbbbbbb-01"
BIND="127.0.0.1:4318"
URL="http://${BIND}/v1/traces"
HEALTH_URL="http://${BIND}/"

# ── Collector boot (FR-T5-OLR-021) ─────────────────────────────────
COLLECTOR_PID=""
cleanup() {
  if [ -n "$COLLECTOR_PID" ] && kill -0 "$COLLECTOR_PID" 2>/dev/null; then
    kill -TERM "$COLLECTOR_PID" 2>/dev/null || true
    wait "$COLLECTOR_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [ "$PROBE_ONLY" -eq 0 ]; then
  python3 "$COLLECTOR_PY" --bind "$BIND" --out "$OUT" >/dev/null 2>"$OUT/collector.stderr" &
  COLLECTOR_PID=$!

  # Readiness poll (FR-T5-OLR-021): up to 5 s, 100 ms interval.
  READY=0
  for _ in $(seq 1 50); do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then READY=1; break; fi
    sleep 0.1
  done
  if [ "$READY" -ne 1 ]; then
    echo "run_smoke: collector did not become ready on $HEALTH_URL within 5s" >&2
    [ -f "$OUT/collector.stderr" ] && sed 's/^/  collector: /' "$OUT/collector.stderr" >&2 || true
    exit 1
  fi
fi

# ── OTLP probe (FR-T5-OLR-022, Python urllib) ──────────────────────
python3 - "$URL" "$TRACEPARENT" "$HEX_PAYLOAD" <<'PY' || { echo "run_smoke: probe POST failed" >&2; exit 1; }
import sys, urllib.request
url, traceparent, hex_payload = sys.argv[1], sys.argv[2], sys.argv[3]
body = bytes.fromhex(hex_payload)
req = urllib.request.Request(
    url,
    data=body,
    method="POST",
    headers={
        "Content-Type": "application/x-protobuf",
        "traceparent": traceparent,
    },
)
with urllib.request.urlopen(req, timeout=5) as resp:
    if resp.status != 200:
        print(f"probe: HTTP {resp.status}", file=sys.stderr)
        sys.exit(1)
PY

# Give the collector a moment to flush the capture JSON to disk.
sleep 0.1

# ── Assertions (FR-T5-OLR-023..025) ────────────────────────────────
CAP=$(ls "$OUT"/capture-*.json 2>/dev/null | head -1)
if [ -z "$CAP" ]; then
  echo "run_smoke: no capture-NNN.json file produced in $OUT" >&2
  exit 1
fi

if ! grep -q '"service_name": "fsm-backend"' "$CAP"; then
  echo "run_smoke: service_name assertion failed in $CAP" >&2
  exit 1
fi
if ! grep -qE '"traceparent": "00-a{32}-b{16}-01"' "$CAP"; then
  echo "run_smoke: traceparent assertion failed in $CAP" >&2
  exit 1
fi
if ! grep -qE '"resource_spans_count": [1-9]' "$CAP"; then
  echo "run_smoke: resource_spans_count assertion failed in $CAP" >&2
  exit 1
fi

echo "$OUT"
exit 0
