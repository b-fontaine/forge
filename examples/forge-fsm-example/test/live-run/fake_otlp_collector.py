#!/usr/bin/env python3
# <!-- Audit: T.5 (t5-otel-live-run) — Phase D fake OTLP collector -->
"""Fake OTLP collector for the Phase D live-run harness.

Implements just enough of the OTLP HTTP/protobuf contract to verify
that an SDK emits trace exports with the right service.name resource
attribute and forwards a W3C traceparent header. Stdlib only — no
``protobuf`` pip dep, no ``opentelemetry`` pip dep. The walker is
intentionally lossy : it extracts only the tags the contract asserts
and leaves the rest of the payload uninspected.

Wire-format references :
- https://opentelemetry.io/docs/specs/otlp/#otlphttp
- https://protobuf.dev/programming-guides/encoding/

Sanitisation rules (FR-T5-OLR-004) :
- Timestamps replaced with literal ``"<ts:redacted>"``.
- IPv4 dotted-quads replaced with ``"<ip:redacted>"``.
- ``host.name`` resource attribute replaced with ``"<host:redacted>"``.

Per ADR-T5-OLR-001 in
``.forge/changes/t5-otel-live-run/design.md``.
"""

import argparse
import json
import os
import re
import signal
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


# ─── Stdlib varint + length-delimited tag walker ────────────────


def _read_varint(buf, pos):
    """Read a protobuf varint starting at ``pos``. Returns (value, new_pos)."""
    result = 0
    shift = 0
    while pos < len(buf):
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            return result, pos
        shift += 7
    return result, pos


def _walk_top_level(buf):
    """Walk a top-level ``ExportTraceServiceRequest`` payload.

    Returns ``(service_name, resource_spans_count, host_name)``.

    The walker scans top-level field 1 (``resource_spans``, tag 0x0a)
    and counts occurrences. For each ``ResourceSpans``, it dives into
    field 1 (``resource``, tag 0x0a) and then into the ``Resource``'s
    repeated ``attributes`` (field 1, tag 0x0a) extracting any
    ``KeyValue`` whose ``key`` is ``service.name`` or ``host.name``.
    """
    service_name = ""
    host_name = ""
    rs_count = 0
    pos = 0
    while pos < len(buf):
        tag, pos = _read_varint(buf, pos)
        field_num = tag >> 3
        wire_type = tag & 0x07
        if wire_type == 2:  # length-delimited
            length, pos = _read_varint(buf, pos)
            sub = buf[pos:pos + length]
            pos += length
            if field_num == 1:
                rs_count += 1
                sn, hn = _walk_resource_spans(sub)
                if sn and not service_name:
                    service_name = sn
                if hn and not host_name:
                    host_name = hn
        elif wire_type == 0:  # varint
            _v, pos = _read_varint(buf, pos)
        elif wire_type == 1:  # 64-bit
            pos += 8
        elif wire_type == 5:  # 32-bit
            pos += 4
        else:
            break
    return service_name, rs_count, host_name


def _walk_resource_spans(buf):
    """Walk a single ``ResourceSpans`` payload, extracting service+host."""
    service_name = ""
    host_name = ""
    pos = 0
    while pos < len(buf):
        tag, pos = _read_varint(buf, pos)
        field_num = tag >> 3
        wire_type = tag & 0x07
        if wire_type == 2:
            length, pos = _read_varint(buf, pos)
            sub = buf[pos:pos + length]
            pos += length
            if field_num == 1:  # resource
                sn, hn = _walk_resource(sub)
                if sn:
                    service_name = sn
                if hn:
                    host_name = hn
        elif wire_type == 0:
            _v, pos = _read_varint(buf, pos)
        elif wire_type == 1:
            pos += 8
        elif wire_type == 5:
            pos += 4
        else:
            break
    return service_name, host_name


def _walk_resource(buf):
    """Walk a ``Resource``'s repeated ``attributes`` (field 1)."""
    service_name = ""
    host_name = ""
    pos = 0
    while pos < len(buf):
        tag, pos = _read_varint(buf, pos)
        field_num = tag >> 3
        wire_type = tag & 0x07
        if wire_type == 2:
            length, pos = _read_varint(buf, pos)
            sub = buf[pos:pos + length]
            pos += length
            if field_num == 1:  # KeyValue
                key, value = _walk_keyvalue(sub)
                if key == "service.name":
                    service_name = value
                elif key == "host.name":
                    host_name = value
        elif wire_type == 0:
            _v, pos = _read_varint(buf, pos)
        elif wire_type == 1:
            pos += 8
        elif wire_type == 5:
            pos += 4
        else:
            break
    return service_name, host_name


def _walk_keyvalue(buf):
    """Walk a ``KeyValue`` extracting (key, AnyValue.string_value)."""
    key = ""
    value = ""
    pos = 0
    while pos < len(buf):
        tag, pos = _read_varint(buf, pos)
        field_num = tag >> 3
        wire_type = tag & 0x07
        if wire_type == 2:
            length, pos = _read_varint(buf, pos)
            sub = buf[pos:pos + length]
            pos += length
            if field_num == 1:  # key (string)
                key = sub.decode("utf-8", errors="replace")
            elif field_num == 2:  # value (AnyValue)
                value = _walk_anyvalue(sub)
        elif wire_type == 0:
            _v, pos = _read_varint(buf, pos)
        elif wire_type == 1:
            pos += 8
        elif wire_type == 5:
            pos += 4
        else:
            break
    return key, value


def _walk_anyvalue(buf):
    """Walk an ``AnyValue`` extracting its string_value (field 1)."""
    pos = 0
    while pos < len(buf):
        tag, pos = _read_varint(buf, pos)
        field_num = tag >> 3
        wire_type = tag & 0x07
        if wire_type == 2:
            length, pos = _read_varint(buf, pos)
            sub = buf[pos:pos + length]
            pos += length
            if field_num == 1:
                return sub.decode("utf-8", errors="replace")
        elif wire_type == 0:
            _v, pos = _read_varint(buf, pos)
        elif wire_type == 1:
            pos += 8
        elif wire_type == 5:
            pos += 4
        else:
            break
    return ""


# ─── Sanitisation helpers ──────────────────────────────────────


_IPV4_RE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")


def _sanitise_capture(capture):
    """Apply FR-T5-OLR-004 sanitisation rules to a capture dict."""
    # Timestamps are always replaced with the sentinel string.
    capture["timestamp"] = "<ts:redacted>"
    # IPv4 redaction in any string field.
    for k, v in list(capture.items()):
        if isinstance(v, str) and _IPV4_RE.search(v):
            capture[k] = _IPV4_RE.sub("<ip:redacted>", v)
    # host.name → <host:redacted> if the resource carries one.
    if capture.get("host_name"):
        capture["host_name"] = "<host:redacted>"
    return capture


# ─── HTTP handler ──────────────────────────────────────────────


class CollectorState:
    """Shared collector state — mutable, single-process."""

    def __init__(self, out_dir):
        self.out_dir = out_dir
        self.lock = threading.Lock()
        self.counter = 0

    def next_capture_path(self):
        with self.lock:
            path = os.path.join(self.out_dir, f"capture-{self.counter:03d}.json")
            self.counter += 1
            return path


class FakeCollectorHandler(BaseHTTPRequestHandler):
    """Routes :
      GET /          -> 200 fake-otlp-collector\\n (health, FR-T5-OLR-007)
      POST /v1/traces|/v1/metrics|/v1/logs -> 200 + write capture
      else           -> 404
    """

    # Silence default access log — we want deterministic stderr only.
    def log_message(self, fmt, *args):
        return

    def do_GET(self):  # noqa: N802 — http.server convention
        if self.path == "/":
            body = b"fake-otlp-collector\n"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self._send_404()

    def do_POST(self):  # noqa: N802 — http.server convention
        if self.path not in ("/v1/traces", "/v1/metrics", "/v1/logs"):
            self._send_404()
            return
        length = int(self.headers.get("Content-Length", "0") or 0)
        body = self.rfile.read(length) if length else b""
        traceparent = self.headers.get("traceparent", "") or ""
        # Walk the payload to extract service.name, count, host.name.
        try:
            service_name, rs_count, host_name = _walk_top_level(body)
        except Exception as exc:  # noqa: BLE001 — never crash the collector
            print(f"fake-otlp-collector: walker error: {exc}", file=sys.stderr)
            service_name, rs_count, host_name = "", 0, ""
        capture = {
            "service_name": service_name,
            "host_name": host_name,
            "traceparent": traceparent,
            "resource_spans_count": rs_count,
            "path": self.path,
            "method": "POST",
            "body_size_bytes": length,
            "timestamp": "WILL_BE_REPLACED",
        }
        capture = _sanitise_capture(capture)
        state = self.server.state  # type: ignore[attr-defined]
        out_path = state.next_capture_path()
        # Deterministic, sorted-key JSON. LF line endings.
        with open(out_path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(capture, f, indent=2, sort_keys=True)
            f.write("\n")
        # Empty 200 response (the OTLP spec allows an empty
        # ExportTraceServiceResponse body — clients tolerate it).
        self.send_response(200)
        self.send_header("Content-Type", "application/x-protobuf")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def _send_404(self):
        body = b"not found\n"
        self.send_response(404)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


# ─── Entry point ───────────────────────────────────────────────


def _parse_bind(spec):
    """Parse a HOST:PORT bind spec."""
    if ":" not in spec:
        raise SystemExit(f"fake-otlp-collector: invalid bind '{spec}' (HOST:PORT)")
    host, port = spec.rsplit(":", 1)
    return host, int(port)


def main(argv):
    parser = argparse.ArgumentParser(description="Fake OTLP collector (Phase D)")
    parser.add_argument("--bind", default="127.0.0.1:4318", help="HOST:PORT (default 127.0.0.1:4318)")
    parser.add_argument("--out", required=True, help="directory for capture JSON files")
    args = parser.parse_args(argv)
    host, port = _parse_bind(args.bind)
    os.makedirs(args.out, exist_ok=True)
    server = ThreadingHTTPServer((host, port), FakeCollectorHandler)
    server.state = CollectorState(args.out)  # type: ignore[attr-defined]

    def _shutdown(_signum, _frame):
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, _shutdown)
    signal.signal(signal.SIGINT, _shutdown)
    print(f"fake-otlp-collector: listening on http://{host}:{port}", file=sys.stderr)
    server.serve_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
