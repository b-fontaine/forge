# Specs: doc-workiva-otel-status
<!-- Status: specified -->
<!-- Schema: default -->

> FR namespace: `FR-DWO-NNN` (Doc — Workiva OTel status).
> NFR namespace: `NFR-DWO-NNN`.
> All FRs target `docs/ARCHITECTURE-TARGET.md` §9.

## Functional Requirements

### FR-DWO-001 — Status annotation present in §9

`docs/ARCHITECTURE-TARGET.md` §9 MUST contain a status annotation block
documenting the Workiva `opentelemetry: 0.18.11` Dart package
signal-coverage as follows:

| Signal  | Status        |
|---------|---------------|
| Traces  | Beta          |
| Metrics | Alpha         |
| Logs    | Unimplemented |

The block MUST be placed in §9 (the OTel agent section), immediately
after the agents-impacted table, before §9.2.

### FR-DWO-002 — Date-stamp 2026-05-12

The annotation MUST carry a date-stamp: `[source verified: 2026-05-12]`
referencing the `t5-otel-dart-api-realign` change as the origin of the
status data (FR-FOT-DA-060).

### FR-DWO-003 — Future-review trigger

The annotation MUST include an explicit future-review trigger:
"Re-verify by 2026-11-12 or when `opentelemetry` pkg bumps to >= 0.19.0."

### FR-DWO-004 — Package version pinned

The annotation MUST name the package version `opentelemetry: 0.18.11`
and maintainer `Workiva` so the scope is unambiguous.

### FR-DWO-005 — Scope statement (traces only active)

The annotation MUST note that only the Traces signal is actively used
in the current Forge stack (Metrics and Logs are out of scope for the
current Forge OTel phase per Q-001 resolution in t5-otel-dart-api-realign).

## Non-Functional Requirements

### NFR-DWO-001 — Minimal diff

The annotation MUST be a single cohesive block (no scattered edits).
Total insertion: <= 20 lines.

### NFR-DWO-002 — No hallucination

Status data (Beta/Alpha/Unimplemented) MUST NOT be invented. Source is
`t5-otel-dart-api-realign` specs.md FR-FOT-DA-060 and the Workiva
opentelemetry-dart README as verified on 2026-05-11.

### NFR-DWO-003 — Gates pass

`verify.sh` and `constitution-linter.sh` MUST exit 0 after the edit.

### NFR-DWO-004 — No other section modified

No heading, table, or paragraph outside §9 of ARCHITECTURE-TARGET.md
may be altered by this change.
