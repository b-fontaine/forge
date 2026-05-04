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
