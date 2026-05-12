# Phase D — golden captures

<!-- Audit: T.5 (t5-otel-live-run) — FR-T5-OLR-042 -->

This directory carries the deterministic golden output produced by the
Phase D smoke driver against the fake OTLP collector. The harness
`t5-otel-live-run.test.sh` consumes the goldens via byte-exact
`diff -q` comparison.

## Files

| File                 | Source command                                                                                                  |
|----------------------|-----------------------------------------------------------------------------------------------------------------|
| `direct.golden.json` | `bash examples/forge-fsm-example/test/live-run/run_smoke.sh --scenario direct --out <tmpdir> && cat <tmpdir>/capture-000.json` |
| `kong.golden.json`   | `bash examples/forge-fsm-example/test/live-run/run_smoke.sh --scenario kong   --out <tmpdir> && cat <tmpdir>/capture-000.json` |

## Determinism rationale

Both captures are byte-stable because :

1. The probe payload is a hex-canned constant in `run_smoke.sh`
   (ADR-T5-OLR-004) — no SDK runtime variance.
2. The W3C `traceparent` header uses deterministic placeholder values
   (`a` × 32 trace_id, `b` × 16 span_id, `01` sampled flag) so the
   collector echoes the same string every run.
3. The fake collector writes JSON with `json.dump(..., indent=2,
   sort_keys=True)` followed by a single trailing `\n` (LF, never
   CRLF) — same bytes on macOS / Linux / Windows.
4. The sanitiser (ADR-T5-OLR-003) replaces volatile fields with stable
   placeholders **before** the JSON write.

## Sanitisation rules (FR-T5-OLR-004 / FR-T5-OLR-043)

| Field            | Placeholder           |
|------------------|-----------------------|
| `timestamp`      | `"<ts:redacted>"`     |
| any IPv4 string  | `"<ip:redacted>"`     |
| `host.name` attr | `"<host:redacted>"`   |

Goldens MUST contain `"<ts:redacted>"` and MUST NOT contain any
4-octet IPv4 dotted-quad pattern (asserted by
`_test_olr_020_goldens_sanitised`).

## Placeholder values

- `traceparent` trace_id  → 32 lowercase `a` characters.
- `traceparent` span_id   → 16 lowercase `b` characters.
- `traceparent` flags     → `01` (sampled).
- `service.name`          → literal `fsm-backend`.
- `host.name` (kong only) → literal `fsm-kong-gateway` (sanitised in
  the capture).

## Regenerating the goldens

If the OTLP wire format ever changes (extremely unlikely for the
fields we use) or the schema expands :

```bash
TMP=$(mktemp -d)
bash examples/forge-fsm-example/test/live-run/run_smoke.sh \
    --scenario direct --out "$TMP"
cp "$TMP"/capture-000.json \
   .forge/changes/t5-otel-live-run/captures/direct.golden.json

TMP=$(mktemp -d)
bash examples/forge-fsm-example/test/live-run/run_smoke.sh \
    --scenario kong --out "$TMP"
cp "$TMP"/capture-000.json \
   .forge/changes/t5-otel-live-run/captures/kong.golden.json

bash .forge/scripts/tests/t5-otel-live-run.test.sh --level 1
```

Always re-run the harness afterwards to confirm the new bytes still
pass `diff -q` against fresh captures (NFR-T5-OLR-003 reproducibility
budget).
