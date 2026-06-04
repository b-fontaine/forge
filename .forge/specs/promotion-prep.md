# Spec: B.8.14 Promotion Prepare (point-of-no-return, held)

Canonical requirements for the B.8.14 prepare-only governance bundle. Source
change: `b8-14-promotion-prep` (archived 2026-06-04, audit B.8.14). The follow-up
`b8-14-promotion-flip` (post-7-day-window) ratifies + applies.

## Requirements

### FR-PROMO-001: Amendment is process-gated, prepare/flip split
The §VIII.1 (Kong→Envoy) Constitution amendment MUST follow `GOVERNANCE.md
§"Amendment Process"` — a Forge change targeting `.forge/constitution.md` + a
≥7-day public discussion window + BDFL ratification + apply. A single-session
ratify+apply is forbidden. `b8-14-promotion-prep` is step 1 + a staged bundle;
ratify/apply/flip/remove is the follow-up. **§VIII.2 (Temporal) is NOT amended**
(B8O retained Temporal).

### FR-PROMO-002: Nothing breaking applied in the prepare brick
The prepare brick MUST NOT edit `.forge/constitution.md`, flip
`2.0.0.yaml` (`stage`/`scaffoldable`), remove Kong/REST, or mutate any
standard/schema/scaffolder. `constitution_version` stays `1.1.0`. A harness MUST
encode NEGATIVE held-state guards (constitution v1.1.0 + §VIII.1 "Kong SHALL";
no Envoy amendment; 2.0.0 candidate/non-scaffoldable; `fsm-kong` + `infra/kong/`
+ `.forge/standards/infra/kong.md` intact; frozen snapshot byte-identical) so a
premature flip cannot merge green.

### FR-PROMO-003: Staged artifacts
The brick MUST ship: a drafted §VIII.1 amendment (Envoy SHALL; target
Constitution v1.1.0→v2.0.0 MAJOR per `VERSIONING.md:15-17`; Amendments-table row;
real-process citations + `d5-governance` precedent); a removal manifest
enumerating the verified-real Kong/REST targets (scaffold-composition targets +
the live `.forge/standards/infra/kong.md`, superseded by `gateway.yaml`); a flip
runbook ordering ratify-before-remove, pinning the framework version to the
pre-GA carve-out `VERSIONING.md:70-73`, noting the t4 material-path; a 1.0.0
T+6-month deprecation draft.

### FR-PROMO-004: Removal gated on ratification
Removing Kong/REST before the §VIII.1 amendment ratifies is a constitutional
violation (`2.0.0.yaml:17-31`). The removal manifest is executed only by the
follow-up, after ratification, in the 2.0.0 scaffold composition (never by
editing the frozen 1.0.0 base).

<!-- Added in b8-14-promotion-prep change, 2026-06-04 -->
