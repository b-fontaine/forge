# Standard — Standards Review Rules (K5-RULE-NNN catalogue)

<!-- Audit: K.5 (k5-themis) -->
<!-- Trigger: themis, review-standards, standards-review, compliance-officer, nis2, dora, cra, ai-act, regulatory-deadline, k5-rule, review-cadence -->

```yaml
version: 1.0.0
last_reviewed: 2026-07-10
expires_at: 2027-07-10
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: >-
  Codifies the K5-RULE-NNN catalogue enforced by the Themis agent
  (bin/forge-review-standards.sh) : the standards review cadence
  (12-month window per standards-lifecycle.md) + the EU
  regulatory-deadline calendar (NIS2 / DORA / CRA / AI Act). Sibling
  rule-catalogue surface to global/data-stewardship-rules.md (K.3) and
  global/janus-orchestration-rules.md (J.8). WARN-only per the
  standards-lifecycle "WARN n'est jamais bloquant" doctrine.
```

---

## Purpose

This standard is the **human-readable canon** for the **Themis** agent
(`.claude/agents/themis.md`, K.5) and its automation
`bin/forge-review-standards.sh` — the `forge review-standards` hook named
by `global/standards-lifecycle.md`. It catalogues the `K5-RULE-NNN`
rules Themis fires at **repo-lifecycle-time** and pins the EU
regulatory-deadline calendar.

Themis is the compliance officer of the Forge offering. It owns two
duties:

1. **Standards review cadence** — automating the 12-month `expires_at`
   review window that P-3 / T.4 established
   (`global/standards-lifecycle.md`) but left manual until K.5.
2. **Regulatory-deadline tracking** — surfacing the NIS2 / DORA / CRA /
   AI Act calendar for EU-tier archetypes and driving the I.6 auditor
   hand-off bundle.

Themis is the **sibling** of Demeter (K.3, data steward). The two never
overlap — Demeter works at scaffold-time on dependency jurisdiction;
Themis works at repo-lifecycle-time on review cadence + regulatory
deadlines. See `.claude/agents/themis.md` § "Boundary — Themis vs
Demeter". The `K5-RULE-*` namespace is disjoint from Demeter's
`K3-RULE-*`, Janus's `J8-RULE-*`, and the I.3 `T3-RULE-*` (ADR-J8-004
`<MODULE>-RULE-NNN` inheritance).

Source audit item : **K.5** from `docs/new-archetypes-plan.md` §9 line
2672 + `docs/ARCHITECTURE-TARGET.md` §9.2 line 735.

Constitution cross-references :

- **Article XII** — Themis ENFORCES the review cadence; it does NOT
  amend. Structural exceptions (`transport.yaml`,
  `state-management.yaml`, any `expires_at: never`) are NEVER flagged.
- **Article III.4** — regulatory dates are copied VERBATIM from a cited
  source; when unsourced Themis emits `[NEEDS CLARIFICATION:]`.
- **Article V.1** — `K5-RULE-NNN` IDs are audit-trail glue,
  machine-parseable.

---

## Rule catalogue

| Rule ID | Trigger | Severity | Remediation | Cross-link |
|---|---|---|---|---|
| **K5-RULE-001** | Non-structural standard `expires_at < today` | Medium (WARN; blocking only under `--strict`) | Review the standard, refresh `last_reviewed` / `expires_at`, append a `REVIEW.md` entry; open a Forge change if REPLACE / DEPRECATE | `standards-lifecycle.md` § 12-month review window |
| **K5-RULE-002** | `today ≤ expires_at ≤ today + window` | Low | Schedule the review before `expires_at` | `standards-lifecycle.md` |
| **K5-RULE-003** | Standard missing `last_reviewed` / `expires_at` frontmatter | Medium for `*.yaml` (J.7 territory); Informational for `*.md` prose (pre-T.4 corpus, ADR-K5-004) | Add the frontmatter contract | `standards-lifecycle.md` § Frontmatter |
| **K5-RULE-004** | Regulatory milestone with a parseable ISO-8601 date within a 365-day horizon | Informational | Verify the repo's compliance artefacts address it; drive the I.6 bundle (`--bundle`) | § Regulatory-deadline calendar below |
| **K5-RULE-005** | `expires_at: never` XOR `exception_constitutional: true` | Medium | Align the two keys per the Article-XII bidirectional coupling | `standards-lifecycle.md` § Structural exception; J.7 `FR-J7-020` |

**Numbering invariant** — per ADR-J8-004, IDs are NEVER reused.
Decommissioned rules carry `DEPRECATED`; slots are not recycled. Future
`K5-RULE-006+` are appended.

**K5-RULE-005 vs J.7** — `validate-standards-yaml.sh` (J.7) hard-fails
(`[STD-FAIL]` `FR-J7-020`) on the `never` ⇔ `exception_constitutional`
coupling for top-level `*.yaml` standards. K5-RULE-005 is the
**review-time WARN companion** that ALSO covers Markdown standards J.7
does not scan (`global/*.md`), closing that gap without duplicating the
YAML hard gate (ADR-K5-005).

---

## Regulatory-deadline calendar

Copied **VERBATIM** from `docs/new-archetypes-plan.md` §7.1's I.6 bullet
(lines 2629-2634), which cites `docs/ARCHITECTURE-TARGET.md` §10.4 with
the original `[source: ...]` footnotes. Themis NEVER invents,
approximates, or re-derives these dates (Article III.4 /
NFR-K5-THE-009) :

- **NIS2** — reporting 24h/72h.
- **DORA** — RoI ESA submission 30 avr 2026.
- **CRA** — reporting 11 sept 2026, full requirements 11 déc 2027.
- **AI Act** — phases 2025–2027 par catégorie de risque.

The deep legal determinations the repo cannot ground (exact AI Act
risk-category phase dates, DORA notification windows, authoritative RoI
schema) remain `[NEEDS CLARIFICATION]` Phase-B work items per
`global/ai-act-dora-artefacts.md` — Themis surfaces the calendar, it
does not adjudicate the law.

`bin/forge-review-standards.sh` fires `K5-RULE-004` (Informational) for
any milestone with a parseable ISO-8601 date within a 365-day horizon
of today (DORA 2026-04-30, CRA 2026-09-11 / 2027-12-11). NIS2 24h/72h
and "AI Act phases 2025–2027" carry no single parseable date and are
reported as informational calendar entries only.

---

## Review cadence automation

`bin/forge-review-standards.sh` is the `forge review-standards` hook.
It :

1. Walks `<target>/.forge/standards/` for `last_reviewed` /
   `expires_at` frontmatter — top-level YAML in `*.yaml` standards +
   fenced ```` ```yaml ```` blocks in `*.md` standards (excludes
   `REVIEW.md` + `index.yml`).
2. Classifies each standard FRESH / DUE-SOON / EXPIRED / STRUCTURAL
   against a configurable `--window` (default 30 days).
3. Emits a deterministic Standards Review Report (JSON or Markdown;
   `SOURCE_DATE_EPOCH`-reproducible).
4. OPTIONALLY (`--bundle`) writes a regulatory-deadline summary and
   DRIVES the I.6 `.forge/scripts/compliance/bundle.sh` (never forks
   it).

### WARN-never-blocks

Per `standards-lifecycle.md` ("WARN n'est jamais bloquant : une
expiration n'arrête pas la production"), the default posture is
**WARN**. Exit codes : `0` CLEARED, `1` REVIEW-DUE (non-blocking WARN),
`2` usage error, `3` BLOCKED (only with `--strict` on an expired
standard). The sibling CI workflow
`.github/workflows/forge-standards-review.yml` runs the cadence monthly
(`on: schedule:`) with `continue-on-error: true` — a review debt
surfaces without freezing any pipeline.

### Phase A → Phase B

The K.3 `cloud-act-publishers.yml` deny-list and the I.2
`compliance-tiers.md` matrix each reserved a **Phase B** maintainer role
for Themis (6-month rolling cadence, driven by Themis's monthly
`forge review-standards` cycle). With K.5 shipped, Themis picks up that
role — the Phase A → B transition is a single PR editing the respective
`maintained_by:` fields (no data migration).

---

## Extending the catalogue

New rules follow the ADR-J8-004 extension protocol :

1. **Add a new rule ID** sequentially after `K5-RULE-005`. IDs are
   NEVER reused.
2. **Document the trigger** — condition, severity, remediation hint;
   add a row to the catalogue table above.
3. **Encode the rule** in `bin/forge-review-standards.sh`.
4. **Add a harness test** under `.forge/scripts/tests/k5.test.sh`.
5. **Bump this standard** per SemVer (minor for additive rule; major for
   removal / semantics change) and refresh `last_reviewed` /
   `expires_at` per `global/standards-lifecycle.md`, appending a
   `REVIEW.md` entry.

---

## Constitutional Compliance

This standard implements (does not amend) :

- **Article III.4** (anti-hallucination) — regulatory dates verbatim;
  `[NEEDS CLARIFICATION:]` on unsourced dates / malformed frontmatter.
- **Article V** (audit trail) — `K5-RULE-NNN` IDs + structured JSON
  report; REVIEW.md append-only.
- **Article XI.1** (agent-native) — Themis (`.claude/agents/themis.md`)
  is the canonical consumer.
- **Article XI.3** (schema-driven) — deterministic JSON output, no
  opaque LLM-generated content.
- **Article XII** (governance) — Themis ENFORCES the cadence; structural
  exceptions require an Article XII amendment; edits follow
  `global/standards-lifecycle.md` SemVer + REVIEW.md.

This standard ships as Markdown (mirroring `data-stewardship-rules.md`,
`janus-orchestration-rules.md`, `forbidden-components-rules.md`); the
YAML-equivalent fields at the top are **narrative** —
`bin/validate-standards-yaml.sh` does not scan MD standards.
