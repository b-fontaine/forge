# Forge standards — lifecycle policy

> **For adopters**. This document explains how Forge standards age, when
> they are reviewed, and how the framework guards against fossilisation.
> The internal canonical version lives at
> `.forge/standards/global/standards-lifecycle.md` ; this is the public
> summary.

## Why a lifecycle ?

Forge enshrines certain technical choices (state management, transport,
persistence, identity, observability, orchestration) as
**versioned standards** in `.forge/standards/*.yaml`. The risk without
governance: a standard that outlives its technical relevance and fossilises
the framework, or a standard amended without constraint that erodes consistency.

The Forge trade-off:

- **Default review cycle: 12 months.** Every standard carries an
  `expires_at` ISO-8601 ; at expiry, a WARN appears in `verify.sh`.
- **Structural exception.** Two standards are enshrined as
  **structural** by constitutional decision (Article XII) and
  are exempt from the 12-month cycle: `transport.yaml` (proto + Connect) and
  `state-management.yaml` (flutter_bloc). Amending them requires a Constitution
  amendment procedure.

## How to read a standard

Every `.forge/standards/*.yaml` opens with a uniform frontmatter:

```yaml
version: "1.0.0"                  # version propre du standard
last_reviewed: 2026-05-04          # date de revue la plus récente
expires_at: 2027-05-04             # ou "never" si exception_constitutional
exception_constitutional: false    # true => structural (Article XII only)
linter_rule: <id-or-null>          # rule that enforces this standard
enforcement:
  ci_blocking: false               # FAIL CI ou non
  pre_commit_hook: false           # block local commit
forbidden: [...]                   # libs / providers / patterns disallowed
rationale: |
  Why this standard exists.
```

## The 6 enshrined standards (2026-05-04)

| Standard               | Version | Expires_at         | Structural exception | Source                                                |
|------------------------|---------|--------------------|------------------------|-------------------------------------------------------|
| `transport.yaml`        | 1.0.0   | never              | YES (ADR-003 + ADR-009)| `docs/ARCHITECTURE-TARGET.md` §4.2 / §4.7             |
| `state-management.yaml` | 1.0.0   | never              | YES (ADR-006)          | `docs/ARCHITECTURE-TARGET.md` §4.1 ADR-006            |
| `observability.yaml`    | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.8 ADR-008            |
| `orchestration.yaml`    | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.6 ADR-002            |
| `identity.yaml`         | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.9 ADR-007            |
| `persistence.yaml`      | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.5 ADR-010            |

## Review cycle

1. At expiry (`expires_at < today`), `verify.sh` emits a WARN. The WARN
   is NOT blocking ; it signals a review debt.
2. The maintainer reviews the standard, updates `last_reviewed` /
   `expires_at`, and adds an entry to `.forge/standards/REVIEW.md`.
3. If the review concludes REPLACE / DEPRECATE, a new Forge change is
   opened (proposal → specs → design → tasks → implement) that amends the
   standard.
4. Starting with T7, the **Themis** agent (compliance officer) automates
   this cycle via the `forge review-standards` hook.

## Structural exception: why ?

`transport.yaml` and `state-management.yaml` define **Forge's identity**,
not an amendable technical choice:

- **transport.yaml** — proto + Connect = single source of the
  Spec→Code contracts. Changing this standard would amount to redefining
  Forge's SDD pipeline.
- **state-management.yaml** — flutter_bloc enshrined as the single framework
  for cross-project consistency + event-driven SDD alignment. Changing
  this standard would break the "single canonical framework" identity assumed
  by Forge.

To amend them:

1. Public discussion ≥ 7 days via GitHub Discussions.
2. Forge change with rationale + impact analysis on the archetypes.
3. BDFL vote (current phase) or committee (mature phase).
4. Bump Constitution version (minor if extension, major if breaking).
5. Synchronised update of the standard.

## Reference documents

- `docs/ARCHITECTURE-TARGET.md` — Forge 2026 target architecture audit
  (10 ADRs ratified by `t4-adr-ratification`, sha256 pinned, drift gate
  active via `t4.test.sh`).
- `docs/new-archetypes-plan.md` — post-v0.3.0 plan (taxonomy of 5
  archetypes, modules B.6/B.7/B.8/B.9, compliance T1/T2/T3).
- `.forge/standards/REVIEW.md` — append-only ledger of review events.
- `.forge/standards/global/standards-lifecycle.md` — internal canonical
  version, source of truth.
