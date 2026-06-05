# Proposal: b8-14-promotion-flip

**Audit item**: B.8.14 (the FLIP follow-up) · **Effort**: L · **Status**: proposed → 2026-06-05
**THE POINT OF NO RETURN.** Executes what `b8-14-promotion-prep` staged.

## Why
B.8.14-prep opened the §VIII.1 (Kong→Envoy) Constitution amendment + staged the
removal manifest + flip runbook, holding all breaking change for the post-window
follow-up. This brick is that follow-up: it ratifies + applies the amendment,
promotes the 2.0.0 schema to scaffoldable, builds the Kong-less 2.0.0 scaffold,
and activates the 1.0.0 deprecation.

## BDFL waiver (recorded honestly)
The ≥7-day public discussion window (GOVERNANCE.md Amendment Process) opened
2026-06-04 (prep brick). The BDFL elected to ratify now (2026-06-05, ~1 day) —
a **window compression**, recorded as a REVIEW.md Correction Entry with the real
dates (NOT a fabricated "7-day completed"). The BDFL holds this authority
(GOVERNANCE.md Phase actuelle). Rationale: solo-maintainer project; the design
has been publicly tracked since inception (plan + ARCHITECTURE-TARGET).

## Decisions (BDFL 2026-06-05)
1. **Full atomic flip now** (constitution + scaffolder enablement — coupled: once
   §VIII.1 says Envoy, a Kong-scaffolding default is non-compliant, so 2.0.0 must
   become scaffoldable + produce a Kong-less Envoy tree).
2. **ARCHITECTURE-TARGET §11/§12.1 in-place rewrite via the t4 material-path**
   (rehash + REHASH-LOG; supersedes the Kong/DBOS parts of t4's ADRs).
3. **kong.md = tombstone-redirect** to gateway.yaml + transport.yaml during the
   T+6-month deprecation (+ remove its index.yml trigger).

## Scope — two ordered commits (ratify → enable)

**Commit 1 — ratification + governance (no scaffolder dependency):**
- REVIEW.md BDFL-waiver Correction Entry.
- `.forge/constitution.md`: §VIII.1 Kong→Envoy/Connect; Amendments row #2 (waiver
  callout); `**Version**: v1.1.0 → v2.0.0`; effective-date line.
- Version strings 1.1.0→2.0.0 in TEMPLATES only: `change.yaml` (2×),
  full-stack-monorepo + mobile-only `.forge.yaml.tmpl` (the 46 historical change
  files STAY 1.1.0 — d5 ADR-006).
- Invert `d5.test.sh` (_012/_013) in lockstep.
- `CHANGELOG.md` `### BREAKING` (constitution v2.0.0; framework stays 0.4.0 pre-GA).
- ARCHITECTURE-TARGET §11/§12.1 rewrite (DBOS→Temporal, Kong→Envoy) + rehash
  (`forge-rehash-architecture-doc.sh`) + REHASH-LOG; t4.test green after re-pin.
- kong.md → tombstone-redirect; remove standards/index.yml kong entry.
- 1.0.0 deprecation announce (CHANGELOG `### Deprecated`, EOL 2026-12-05;
  VERSIONING support note).
- Retire b8-14-prep held-guards → flip positive constitution/version assertions.

**Commit 2 — enablement (net-new code, after C1):**
- Promote `2.0.0.yaml`: stage candidate→stable, scaffoldable false→true.
- New `scaffold-plan-2.0.0.yaml` (omits Kong) + `forge-init-fsm-2.0.0` path +
  `dispatch-table.yml` 2.0.0 entry → a fresh `forge init` produces a Kong-less
  Envoy/Connect tree (1.0.0 base MINUS Kong PLUS the 2.0.0 overlay).
- `cli/src` versioned-schema selection + runtime `scaffoldable:false` refusal
  guard (the deferred B.8.3.b guard).
- New harness `b8-14-flip.test.sh` (RED-first) + forge-ci registration.
- Invert `b8-3.test.sh` (_006 scaffoldable→true); activate `b8-15.test.sh` _005
  front-door + Kong-removal-in-fresh-scaffold cells.
- 2.0.0 README wording (drop "scaffoldable:false until B.8.14"/"Kong constitutional").
- Bundle regen (`npm run bundle`).

## Out of scope / invariants
- migrate-flagship stays **additive forever** (1.0.0 adopters keep Kong; b8-12 +
  b8-15 line-225 STAY green — removal is fresh-scaffold composition only).
- The frozen 1.0.0 base / snapshot are NEVER edited (b8-2 guard).
- §VIII.2 (Temporal) NOT amended (B8O).
- Framework stays on the 0.4.0 MINOR line (pre-GA carve-out); constitution → v2.0.0.

## Risks (from the grounding critic)
| Risk | Mitigation |
|------|------------|
| d5.test silent break (hard-codes v1.1.0) | Invert _012/_013 in the SAME commit as the version bump. |
| Removing Kong from migrate-flagship (would break b8-12/b8-15 additive contract) | Removal is composition-layer ONLY; migrate stays additive; b8-15 line-225 untouched. |
| Dangling kong index.yml entry → j7 red | Remove index.yml entry atomically with the kong.md tombstone. |
| New harness never runs (forge-ci hardcoded array) | Register b8-14-flip.test.sh in the array. |
| Over-bumping 46 historical change files | Only templates bump; historical stay 1.1.0 (d5 ADR-006). |
| t4 pin red after arch-doc edit | Material-path: rehash + REHASH-LOG; t4 green after re-pin. |
| Fabricated waiver / self-approval | Honest REVIEW Correction Entry + independent reviewer before approval (t5.2 lesson). |
