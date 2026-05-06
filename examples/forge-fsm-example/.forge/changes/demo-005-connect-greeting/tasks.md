# Tasks: demo-005-connect-greeting

<!-- Status: archived -->

All tasks are archived ; this file documents the path that was
followed to ship the demo.

- [x] **TD5-001** — Create `clients/package.json` with Connect v2
      runtime pins per FR-DEMO5-004. [Story: FR-DEMO5-004]
- [x] **TD5-002** — Write `clients/connect-client.ts` (~40 LOC)
      using `createConnectTransport` HTTP/1.1, calling Greeter.Greet
      with a request payload `{ name: "world" }`, seeding a W3C
      traceparent header on every call. [Story: FR-DEMO5-002 + FR-DEMO5-003]
- [x] **TD5-003** — Validate the file passes `node --check`
      (NFR-DEMO5-002). [Story: NFR-DEMO5-002]
- [x] **TD5-004** — Add a row in `examples/forge-fsm-example/README.md`
      `## Demo changes` table linking to demo-005. [Story: FR-T5-CC-035]
