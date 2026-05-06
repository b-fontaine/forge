// demo-005-connect-greeting — Connect-RPC TypeScript reference client.
//
// Calls forge.greeter.v1.Greeter/Greet via the Connect adapter mounted
// at /connect on the bin-server (shipped by t5-connect-codegen). Seeds
// a fresh W3C traceparent header on every call so the L2 fixture test
// (_test_t5_l2_traceparent_dual) can assert end-to-end propagation.
//
// Audit: T.5 (t5-connect-codegen) + demo-005-connect-greeting.
//
// The file is intentionally written in TypeScript-compatible JS
// (no type annotations, no interfaces) so `node --check` parses it
// without a TS compiler — see ADR-DEMO5-003.

import { createConnectTransport } from "@connectrpc/connect-web";
import { createPromiseClient } from "@connectrpc/connect";
import { GreeterService } from "../shared/protos/v1/greeter/greeter_pb.js";

function randomHex(bytes) {
  const buf = new Uint8Array(bytes);
  crypto.getRandomValues(buf);
  return Array.from(buf, (b) => b.toString(16).padStart(2, "0")).join("");
}

function freshTraceparent() {
  // W3C trace context : version-traceId-parentId-traceFlags
  // 00-<32-hex>-<16-hex>-01
  return `00-${randomHex(16)}-${randomHex(8)}-01`;
}

const baseUrl = process.env.CONNECT_BASE_URL || "http://localhost:8080/connect";
const transport = createConnectTransport({ baseUrl, httpVersion: "1.1" });
const client = createPromiseClient(GreeterService, transport);

const traceparent = freshTraceparent();
console.log(`[demo-005] traceparent=${traceparent}`);

const response = await client.greet(
  { name: "world" },
  { headers: { traceparent } },
);
console.log(`[demo-005] response.message=${response.message}`);
