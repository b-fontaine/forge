# Open Questions: t5-bin-server-deps
<!-- Created: 2026-05-16 -->
<!-- Audit: T5.1.E (Option B follow-on) -->

## Q-001 — `axum` version in workspace deps

**Status** : answered (ADR-T5BSD-001)

**Question** : the existing example carries `axum = "0.7"` but
`connectrpc 0.3.3` declares `axum = "^0.8"`. Which to pin in
the **template** ?

**Resolution** : **ADR-T5BSD-001 — `axum = "0.8"`**. The example
will be regenerated later (T5.3 territory) — the template MUST
satisfy the live `connectrpc` constraint to make `cargo check
--workspace` resolve.

---

## Q-002 — `bin-server/Cargo.toml.tmpl` layout

**Status** : answered (ADR-T5BSD-002)

**Question** : self-contained vs workspace-inherited vs embedded
in grpc-api ?

**Resolution** : **ADR-T5BSD-002 — workspace-inherited** ; mirrors
the canonical pattern documented in `backend/CLAUDE.md` § Strict
Dependency Rules, also followed by the existing example.

---

## Resolution summary

| ID    | Status   | Resolution                                                                    |
|-------|----------|-------------------------------------------------------------------------------|
| Q-001 | answered | **ADR-T5BSD-001** — `axum = "0.8"` (matches connectrpc 0.3.3 constraint)      |
| Q-002 | answered | **ADR-T5BSD-002** — Workspace-inherited deps + path dep on grpc-api           |
