# Open Questions — k4-iris-web

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Iris-Web severity ladder — Demeter refusal ladder vs Sibyl advisory ladder?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md Cluster 7 (K4-RULE catalogue)
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

Demeter (K.3) uses a refusal ladder
(Critical/High/Medium/Low/Informational) because it BLOCKS on
CLOUD Act exposure. Sibyl (K.2) uses an advisory ladder
(Advisory/Concern/Blocking) because it recommends tuning. Iris-Web
*maintains standards* and reviews the Qwik surface — which ladder
fits? `web-frontend.yaml` explicitly keeps machine enforcement OFF at
birth ("Iris-Web/K.4 territory"), which leans advisory.

### Resolution

**Resolved by ADR-K4-001** in `design.md`. Decision : **Sibyl's
advisory ladder** (`Advisory` < `Concern` < `Blocking`). Iris-Web
recommends ; it does not refuse scaffolding. The single `Blocking`
rule is **K4-RULE-005** (server-only secret leaking into the client
bundle) — a public web surface leaking secrets is a non-negotiable
that maps the report status to `BLOCKED`, analogous to Sibyl's XI.5
fallback gate.

---

## Q-002: Conventions standard vs web-frontend.yaml — reference, reproduce-and-sync, or merge?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-K4-IW-081 / NFR-K4-IW-003
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

`web-frontend.yaml` (B.8.9) already owns the Qwik/Vite/Connect version
PINS. The new conventions standard needs those pins to talk about the
surface. Three options : (A) reference-only — mention
`web-frontend.yaml`, never reproduce a number ; (B) reproduce-and-sync
— copy the pins into the conventions doc, keep both in sync ; (C)
merge — fold conventions into `web-frontend.yaml`.

### Resolution

**Resolved by ADR-K4-002** in `design.md`. Decision : **Option A —
reference-only**. `web-frontend.yaml` stays the single source of truth
for pins ; `qwik-frontend-patterns.md` owns conventions and references
the YAML without reproducing any version number. Option B guarantees
drift (rejected by NFR-K4-IW-003). Option C mixes a 30-day-cadence
version YAML with slow-moving prose (rejected — the
`data-stewardship-rules.md` / `cloud-act-publishers.yml` precedent
keeps prose and data separate). The harness asserts the exact vite pin
literal is absent from the standard.

---

## Q-003: K4-RULE namespace — pre-allocate 10, or grow from a 6-rule seed?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md Cluster 7
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

`j8-janus-rules` ADR-J8-004 set the `<MODULE>-RULE-NNN` format ; K.3
extended it with `K3-RULE-*`. K.4 inherits the format for
`K4-RULE-*`. Pre-allocate 10 rules now (Option A), or ship a 6-rule
seed and grow incrementally (Option B)?

### Resolution

**Resolved by ADR-K4-003** in `design.md`. Decision : **Option B — 6
seed rules, incremental growth**, namespace `K4-RULE-NNN` :

- **K4-RULE-001** — Eager hydration instead of resumability
  (`Concern`).
- **K4-RULE-002** — Business logic outside route loaders/actions
  (`Concern`).
- **K4-RULE-003** — Connect transport re-instantiated per call
  (`Advisory`).
- **K4-RULE-004** — Streaming without cancel-on-unmount (`Concern`).
- **K4-RULE-005** — Server-only secret leaks into client bundle
  (`Blocking`).
- **K4-RULE-006** — Web-public route/component missing Vitest coverage
  (`Advisory`).

The 6 seed rules cover the 4 convention areas + the 3 BDD scenarios.
Future extensions append `K4-RULE-007..`. Per ADR-J8-004 inheritance,
IDs are NEVER reused — decommissioned rules carry `DEPRECATED`, the
slot is not recycled. The `K4-RULE-*` namespace is syntactically
disjoint from `J8-RULE-*` / `K3-RULE-*`.
