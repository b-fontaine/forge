# Open Questions — b6-4-hermes-async

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
All three questions for this change are NON-BLOCKING (contrast b7-pythia Q-001).
-->

## Q-001: Hermes-* name-adjacency — is "Hermes-Async" distinct from Hermes / Hermes-API?

- **Status**: answered
- **Raised in**: proposal.md § Solution K.1.a ; specs.md FR-B6-HA-002
- **Raised on**: 2026-07-10
- **Raised by**: b6-4-hermes-async planning

### Question

The roadmap (§9 line 2668, §6.1 line 2556, ARCHITECTURE-TARGET §9.2 line 731) names
the K.1 agent **Hermes-Async** verbatim. Two other roster entries share the "Hermes"
root:

- **Hermes** — the Flutter performance sub-agent (`CLAUDE.md` line 76 / `docs/GUIDE.md`
  line 193 "Flutter Performance | Hermes | Profiling, optimisation").
- **Hermes-API** — the Connect/gRPC + OpenAPI 3.1 codegen agent (plan §9.1 line 2682).

Is "Hermes-Async" a genuine collision (like b7-pythia's Q-001, where two agents
contended for the *same* literal "Pythia"), or a benign adjacency?

### Recommendation

Benign adjacency. Unlike "Pythia" (which two agents wanted verbatim), the three
"Hermes-*" names are distinct dispatch tokens. Keep the roadmap-mandated
"Hermes-Async" and add a disambiguation note in the persona so a reader never
conflates the three surfaces (Flutter perf / sync RPC codegen / async event
contracts).

### Resolution

**Resolved 2026-07-10 by ADR-K1-001 (design.md).** Keep **Hermes-Async** as-is. No
collision: "Hermes", "Hermes-API", and "Hermes-Async" are three distinct dispatch
names; name-based dispatch (`SendMessage to: "Hermes-Async"`, the CLAUDE.md trigger
table) disambiguates cleanly. The persona embeds a one-paragraph disambiguation note
(FR-B6-HA-002). Zero churn to the two existing Hermes-* entries. Non-blocking — this
was a confirmation, not a contested decision.

---

## Q-002: K1-RULE namespace — pre-allocate or grow incrementally?

- **Status**: answered
- **Raised in**: proposal.md § Solution K.1.a ; specs.md FR-B6-HA-006 / 120-cluster
- **Raised on**: 2026-07-10
- **Raised by**: b6-4-hermes-async planning

### Question

`j8-janus-rules` ADR-J8-004 set the `<MODULE>-RULE-NNN` format; `b7-pythia`
ADR-K2-002 inherited it as `K2-RULE-NNN` with 6 seed rules (incremental). K.1
inherits it as `K1-RULE-NNN`. Pre-allocate ~10 rules or grow incrementally?

### Recommendation

Incremental, ~6 seed rules (one per checklist area + the VIII.2 idempotency gate),
mirroring ADR-K2-002. Per ADR-J8-004 inheritance, IDs are never reused.

### Resolution

**Resolved 2026-07-10 by ADR-K1-002 (design.md).** Chosen: **incremental growth, 6
seed rules** (`K1-RULE-001..006`) — one per checklist area plus the VIII.2
idempotency gate (`K1-RULE-006`, the only `Blocking`-severity rule). Severity
vocabulary `Advisory` < `Concern` < `Blocking`. Future extensions append
`K1-RULE-007..`; IDs never reused. Asserted by `b6-4.test.sh`
`_test_b64_007_rule_catalogue` + `_test_b64_008_idempotency_blocking`.

---

## Q-003: Advisory agent vs scanner — does Hermes-Async ship a scanner script?

- **Status**: answered
- **Raised in**: proposal.md § Scope Out ; specs.md (overall shape)
- **Raised on**: 2026-07-10
- **Raised by**: b6-4-hermes-async planning

### Question

The `b7-pythia` precedent is advisory (no scanner); the earlier `k3-demeter`
precedent ships a deterministic scanner. Which shape does K.1 take?

### Recommendation

Advisory only, no scanner — mirror `b7-pythia` ADR-K2-003. The plan §9 K.1 verbs are
advisory (maintain/generate/enforce); contract-sync + idempotency review is
design-judgement, not a deterministic deny-list lookup. The one deterministic
enforcement in the event-driven domain (forbidden-broker) is a Janus scaffold-time
rule owned by sibling brick B.6.10, not a Hermes-Async scanner.

### Resolution

**Resolved 2026-07-10 by ADR-K1-003 (design.md).** Chosen: **advisory agent, NO
scanner.** Hermes-Async ships only `.claude/agents/hermes-async.md` (persona
checklists + `Event Contract Readiness Report` template + `K1-RULE-*` catalogue) in
the Sibyl / Panoptes mould — nothing executable. NO `bin/forge-hermes*.sh`, NO
`.forge/data/*.yml`, NO exit-code contract, NO new standard. Guarded by `b6-4.test.sh`
`_test_b64_016_no_scanner` + `_test_b64_014_no_new_standard`; the single L2 fixture
`_test_b64_l2_anchor_integrity` asserts persona-anchor integrity instead of a
scanner-exit-code run.
