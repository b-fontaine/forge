# Open Questions — b8-1-audit-baseline

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN is sequential
per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Baseline document location

- **Status**: answered
- **Raised in**: `.forge/changes/b8-1-audit-baseline/specs.md` FR-B8-1-001
- **Raised on**: 2026-05-29
- **Raised by**: maintainer (b8-1-audit-baseline specify pass)

### Question

Where does the baseline artifact live?

- (a) **`docs/B8-BASELINE.md`** (adopter-facing). The B.8.13 rollback
  runbook will cite it; adopters reading the migration guide benefit. Lean
  here.
- (b) **`.forge/_memory/b8-1-baseline.md`** (internal). Keeps the audit
  out of the published doc surface; consistent with the trio exploration
  note location.

### Resolution

- **Resolved on**: 2026-05-30 (`/forge:design` → ADR-B8-1-001)
- **Decision**: Option (a) — `docs/B8-BASELINE.md`. The machine-readable
  span inventory is split out to `.forge/baselines/` per ADR-B8-1-005.
- **Rationale**: The B.8.13 rollback runbook cites a single published anchor;
  adopters mid-migration read the 1.0.0 reference. No linter impact (Markdown).

---

## Q-002: Latency baseline form

- **Status**: answered
- **Raised in**: `.forge/changes/b8-1-audit-baseline/specs.md` FR-B8-1-012 / FR-B8-1-030
- **Raised on**: 2026-05-29
- **Raised by**: maintainer (b8-1-audit-baseline specify pass)

### Question

The 1.0.0 `fsm-backend` is a placeholder (`image: scratch`), so live
end-to-end latency cannot be captured from the dev compose unmodified.
What form does the latency baseline take?

- (a) **Methodology + one sample capture** (reproducible, machine-noted).
  The procedure is the deterministic artifact; a single sample run is
  attached with hardware/context caveats. Lean here.
- (b) **Committed live p50/p95/p99 numbers**. Fragile, machine-dependent,
  and currently impossible (placeholder backend). Rejected unless a real
  backend image is built within this change's scope (it is not — Scope Out).

### Resolution

- **Resolved on**: 2026-05-30 (`/forge:design` → ADR-B8-1-002)
- **Decision**: Option (a) — methodology is the deterministic artifact; an
  optional sample capture is non-normative + caveated. No committed live
  numbers.
- **Rationale**: Placeholder backend makes live capture impossible now;
  B.8.13 rollback thresholds are relative deltas measured during the
  migration window, not against a frozen 1.0.0 number. Article III.4.

---

## Q-003: Flagship-only vs also pre-capture mobile-only baseline

- **Status**: answered
- **Raised in**: `.forge/changes/b8-1-audit-baseline/proposal.md` (Open Questions seed)
- **Raised on**: 2026-05-29
- **Raised by**: maintainer (b8-1-audit-baseline propose pass)

### Question

B.8.1 (plan §4.2) scopes the baseline to the flagship. B.9 (mobile-only →
mobile-pwa-first) has its own future baseline need. Does this change also
pre-capture a `mobile-only / 1.0.0` baseline, or stay flagship-only?

- (a) **Flagship-only** — matches plan §4.2 wording; mobile baseline is
  B.9 territory. Lean here.
- (b) **Both** — pre-capture mobile-only now to amortize the harness frame.
  Scope creep risk; B.9 is T8, far downstream.

### Resolution

- **Resolved on**: 2026-05-30 (`/forge:design` → ADR-B8-1-004)
- **Decision**: Option (a) — flagship-only. Harness + inventory path are
  parameterized by `<archetype>-<version>` so B.9 adds a sibling inventory
  file, not a new harness.
- **Rationale**: Matches plan §4.2; B.9 is T8, far downstream; avoids scope
  creep while keeping the frame reusable.
