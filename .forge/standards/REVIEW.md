# Standards Review Ledger

This file is **append-only**. Every review event of a `.forge/standards/*.yaml`
file is recorded here as one H2 section, in chronological order. Removing or
amending a past entry is a Constitution violation (Article XII).

The schema for each entry :

```markdown
## YYYY-MM-DD — <one-line summary>

- **Reviewer**: @<github-handle>
- **Reviewed standards**: <table or list>
- **Decision**: KEEP | KEEP-WITH-CHANGES | REPLACE | DEPRECATE
- **Next review due**: <YYYY-MM-DD or "never (structural)">
- **Notes**: optional free text
```

Entries with `Next review due: never (structural)` are subject to Article XII
amendment process (see `.forge/standards/global/standards-lifecycle.md`
§Structural exception).

---

## 2026-05-04 — Initial ratification (t4-adr-ratification)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard               | Version | Decision | Next review due       | Notes                                               |
  |------------------------|---------|----------|-----------------------|-----------------------------------------------------|
  | transport.yaml         | 1.0.0   | KEEP     | never (structural)    | Structural exception per ADR-006 + ADR-009          |
  | state-management.yaml  | 1.0.0   | KEEP     | never (structural)    | Structural exception per ADR-006                    |
  | observability.yaml     | 1.0.0   | KEEP     | 2027-05-04            | OBI eBPF kernel ≥ 5.8 prerequisite                  |
  | orchestration.yaml     | 1.0.0   | KEEP     | 2027-05-04            | DBOS-rs maturity (< 1 year prod) to revisit         |
  | identity.yaml          | 1.0.0   | KEEP     | 2027-05-04            | Zitadel AGPL — confirm licensing fit at review      |
  | persistence.yaml       | 1.0.0   | KEEP     | 2027-05-04            | Citus sharding threshold review (~5 TB)             |

- **Decision**: All 6 standards ratified under Constitution v1.1.0 via change
  `t4-adr-ratification` (2026-05-04). Source : `docs/ARCHITECTURE-TARGET.md`
  ADRs 001 through 010 (sha256
  `cd8fef37ed01de981c8779a79d40234a70a4411387235dd990a86b705f3de925`).
- **Notes**: This is the **seed entry**. Future review events MUST follow
  the schema documented at the top of this file. The structural exceptions
  (`transport.yaml` and `state-management.yaml`) escape the 12-month
  expiry trigger but remain reviewable through Article XII Constitution
  amendments.

---

## 2026-05-05 — Updated transport.yaml to v1.1.0 (t5-connect-codegen)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard       | Version | Decision           | Next review due    | Notes                                                                                                  |
  |----------------|---------|--------------------|--------------------|--------------------------------------------------------------------------------------------------------|
  | transport.yaml | 1.1.0   | KEEP-WITH-CHANGES  | never (structural) | Added `codegen.connect_layout_version: 1` + `codegen.versions:` (11 pins) ; refreshed `codegen.tools:` |

- **Decision**: Updated by `t5-connect-codegen` (Phase 1 ARCHITECTURE-TARGET).
  Additive only — `exception_constitutional: true` preserved, no breaking
  change. Connect codegen plugins added to flagship `buf.gen.yaml` ; Rust
  adapter via `connectrpc` crate (Anthropic OSS) + Axum integration via
  `connectrpc::Router::into_axum_service()`.
- **Notes**: Two stale entries in the v1.0.0 `codegen.tools:` list were
  replaced per Context7 investigation 2026-05-05 :
  `protoc-gen-connect-es` (retired by Connect v2 — replaced by
  `@bufbuild/protoc-gen-es`) ; `protoc-gen-connect-dart-community`
  (skadero plugin abandoned 2022-09 — replaced by the official
  `connectrpc/connect-dart` plugin published by the ConnectRPC governance
  team). Five Rust pins added (`connectrpc`, `buffa`, `buffa-types`,
  `protoc-gen-connect-rust`, `protoc-gen-buffa` — all `=0.3.3` exact pin
  per ADR-T5-002 footnote pre-1.0 caveat). See
  `.forge/changes/t5-connect-codegen/design.md` ADR-T5-001 + ADR-T5-002
  for the full provenance trail.

---

## 2026-05-05 — Correction note on the v1.1.0 entry above (t5-connect-codegen pivot)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard       | Version | Decision | Next review due    | Notes |
  |----------------|---------|----------|--------------------|-------|
  | transport.yaml | 1.1.0   | KEEP     | never (structural) | Textual correction only — no version bump, no spec change. |

- **Decision**: KEEP the previous v1.1.0 entry as-is (Article XII
  append-only). This entry corrects a textual drift in the previous
  Notes block introduced before the post-T-BUF pivot to Path α
  (`connectrpc-build` build-dep) on 2026-05-05.
- **Notes**: The previous entry's *Notes* section says
  *« Five Rust pins added (`connectrpc`, `buffa`, `buffa-types`,
  `protoc-gen-connect-rust`, `protoc-gen-buffa`) »*. After the T-BUF
  investigation pivoted to **Option 2 / Path α** (`connectrpc-build`
  via `build.rs` build-dependency rather than buf-driven local plugins,
  to preserve the codebase's "remote plugins only" convention — see
  `tasks.md::T-VER-006` evidence and the `fc41e49` commit), the
  effective Rust pin set in `transport.yaml::codegen.versions` is
  **four** entries : `connectrpc`, `buffa`, `buffa-types`,
  `connectrpc-build` (no `protoc-gen-connect-rust`, no
  `protoc-gen-buffa` — those local protoc plugins are not used). The
  previous entry's textual count and naming are stale relative to the
  shipped `transport.yaml` ; this corrective entry records the truth
  without amending the past entry. A `WAIVER 2026-05-05` comment was
  also added inline next to the `=0.3.3` pins in `transport.yaml` to
  document the 13-day age waiver of ADR-T5-002 #1 visibly to reviewers
  reading the standard alone.
