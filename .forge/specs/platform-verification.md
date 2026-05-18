# Spec: platform-verification

<!-- Audit: T.5.2 (t5-2-platform-verification) — anti-hallucination 3-axis platform-verification checklist for external dependency-pinning standards. -->
<!-- Source change : `.forge/changes/t5-2-platform-verification/` (archived 2026-05-18). -->

**Namespace** : `FR-T52-*` / `NFR-T52-*`. **Constitution** : v1.1.0.
No amendment required — T5.2 reinforces Article III.4 (Ambiguity
Protocol — anti-hallucination) procedurally by codifying a third
verification axis (platform compatibility) on top of the existing
existence + API-surface axes that the ratification process
already exercised informally.

**Nine physical deliverables** (per `.forge/changes/t5-2-platform-verification/tasks.md`) :

- **T5.2.A** — `.claude/agents/document-specialist.md` Forge-local
  override carrying the canonical H2 `## Platform Verification
  Checklist (3-axis)` (axes Existence / API surface / Platform
  compatibility + MUST tick-all + `[PLATFORM MISMATCH:]`
  escalation token + Q-006 worked example + scope clarification +
  Article III.4 cross-reference). OMC agent-resolution precedence
  : project-level `.claude/agents/` beats plugin cache (verified
  empirically via the K.3 Demeter persona precedent).
- **T5.2.B** — `.forge/standards/global/standards-lifecycle.md`
  additive bump v1.0.0 → v1.1.0 with new H2 `## Platform
  compatibility re-verification` codifying the cadence rules
  (SHOULD at 12-month review / MUST on consuming-archetype target
  platform addition / MUST execute before first ratification).
  Frontmatter introduced explicitly during the bump (file was
  authored pre-J.7 without an explicit `version:` field — v1.0.0
  was implicit).
- **T5.2.C** — `.forge/standards/REVIEW.md` append-only ledger
  entry dated 2026-05-18 (Article XII discipline preserved : 27
  prior entries byte-identical, new entry appended at tail).
- **T5.2.D** — `.forge/scripts/tests/t5-2.test.sh` test harness :
  8 L1 grep assertions + 1 L2 opt-in (`FORGE_T52_LIVE=1`) pub.dev
  tooling smoke on `flutter_bloc` per ADR-T52-002. Pattern mirrors
  J.7 / I.5 / K.3 sibling harnesses per ADR-T52-004.
- **T5.2.E** — `.github/workflows/forge-ci.yml` matrix entry
  registered immediately after `t5-otel-live-run.test.sh`. Two
  comment lines compacted on neighbouring `t5-otel-traceparent-e2e`
  + `t5-otel-live-run` entries to stay under the 300-line budget
  asserted by `t5-1.test.sh::_test_t51_l1_017_ci_line_budget`
  (final = 298 lines).
- **T5.2.F** — `docs/CONTRIBUTING.md § Adding a Standard`
  enriched with a 3-axis verification callout cross-referencing
  the agent file H2 verbatim.
- **T5.2.G** — `docs/LINTING.md § Informative rules` adds a
  paragraph noting the checklist is procedural (not enforced by
  `constitution-linter.sh`). Enforcement is deferred — possibly
  T6+ once T5.3 has battle-tested the convention.
- **T5.2.H** — `CHANGELOG.md` [Unreleased] entry. Self-corrective
  meta-note documents the Article VIII → III.4 fix-forward
  caught by an independent code-reviewer pass pre-archive.
- **Bidirectional drift guard** (ADR-T52-003) — the two canonical
  H2 titles `## Platform Verification Checklist (3-axis)` and
  `## Platform compatibility re-verification` MUST be cited
  verbatim (case- and whitespace-sensitive) across the four
  reinforcing surfaces : agent file, standards-lifecycle.md,
  CONTRIBUTING.md, LINTING.md. Harness L1 assertions enforce.

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Forge-local `document-specialist` override (FR-T52-A-001..015)

| FR | Subject |
|---|---|
| FR-T52-A-001 | Agent file presence at `.claude/agents/document-specialist.md` |
| FR-T52-A-002 | Forge-local override HTML comment within first 5 lines |
| FR-T52-A-003 | Verbatim H2 anchor `## Platform Verification Checklist (3-axis)` |
| FR-T52-A-004 | Axis 1 named `Existence` (case-insensitive) |
| FR-T52-A-005 | Axis 2 named `API surface` (case-insensitive) |
| FR-T52-A-006 | Axis 3 named `Platform compatibility` (case-insensitive) |
| FR-T52-A-007 | MUST tick-all clause before flipping status to `verified` |
| FR-T52-A-008 | `[PLATFORM MISMATCH: ...]` marker + ADR escalation |
| FR-T52-A-009 | Worked example citing Q-006 (Workiva, `opentelemetry 0.18.11`, mobile archetypes, missing iOS+Android) |
| FR-T52-A-010 | Per-dependency `[x]` / `[ ]` task-list format in `proposal.md § Source Documents` |
| FR-T52-A-011 | Bidirectional cross-reference to `standards-lifecycle.md` § `Platform compatibility re-verification` |
| FR-T52-A-012 | Article III.4 (Ambiguity Protocol — anti-hallucination) constitutional cross-reference. **Corrected** from initial draft "Article VIII" (Infrastructure) ; see CHANGELOG meta-note. |
| FR-T52-A-013 | Scope clarification — applies to external dependency-pinning standards only ; excludes pure prose contracts |
| FR-T52-A-014 | No new MCP tool / OMC slash-command / agent subprotocol introduced |
| FR-T52-A-015 | Forge-local agent H1+H2 convention preserved (precedent : `demeter.md`, `spec-writer.md`) |

#### Cluster 2 — `standards-lifecycle.md` v1.1.0 bump (FR-T52-B-001..010)

| FR | Subject |
|---|---|
| FR-T52-B-001 | Frontmatter version v1.0.0 → v1.1.0 (frontmatter back-fill ; v1.0.0 was implicit pre-J.7) |
| FR-T52-B-002 | `last_reviewed: 2026-05-18` |
| FR-T52-B-003 | `breaking_change: false` (additive) |
| FR-T52-B-004 | Audit comment preserves T.4 pointer + appends T5.2 |
| FR-T52-B-005 | Verbatim H2 anchor `## Platform compatibility re-verification` appended at end of file |
| FR-T52-B-006 | SHOULD re-run 3-axis checklist at every 12-month Article XII review |
| FR-T52-B-007 | MUST re-run immediately on consuming-archetype target-platform addition |
| FR-T52-B-008 | MUST execute before any new external dep-pinning standard ratifies for the first time |
| FR-T52-B-009 | Bidirectional cross-reference to agent file H2 verbatim |
| FR-T52-B-010 | Q-006 worked-example mention by name |

#### Cluster 3 — REVIEW.md append-only ledger entry (FR-T52-C-001..003)

| FR | Subject |
|---|---|
| FR-T52-C-001 | Ledger H2 entry matching `^## 20[0-9]{2}-[0-9]{2}-[0-9]{2} — standards-lifecycle.md v1.0.0 → v1.1.0$` |
| FR-T52-C-002 | Body cites change name + trigger Q-006 + new H2 anchor + `breaking_change: false` |
| FR-T52-C-003 | Prior 27 H2 entries byte-identical (Article XII immutability) |

#### Cluster 4 — Harness L1 grep assertions (FR-T52-D-001..010)

| FR | Subject |
|---|---|
| FR-T52-D-001 | Harness file presence + executable + sourcing `_helpers.sh` |
| FR-T52-D-002 | Test functions named `_test_t52_l1_NNN_<description>` |
| FR-T52-D-003 | L1.001 — agent file presence + non-empty |
| FR-T52-D-004 | L1.002 — checklist H2 verbatim |
| FR-T52-D-005 | L1.003 — three axes named |
| FR-T52-D-006 | L1.004 — `[PLATFORM MISMATCH:` token |
| FR-T52-D-007 | L1.005 — lifecycle frontmatter `version: 1.1.0` |
| FR-T52-D-008 | L1.006 — re-verification H2 verbatim |
| FR-T52-D-009 | L1.007 — REVIEW ledger entry pattern |
| FR-T52-D-010 | L1.008 — Article III.4 cross-reference (renamed `_test_t52_l1_008_article_iii4_xref` from initial `_article_viii_xref` per CHANGELOG meta-note) |

#### Cluster 5 — Harness L2 opt-in live-run (FR-T52-E-001..004)

| FR | Subject |
|---|---|
| FR-T52-E-001 | Gated by `FORGE_T52_LIVE=1` ; skip-pass otherwise |
| FR-T52-E-002 | L2.001 — pub.dev tooling smoke on `flutter_bloc` ; greps `[Pp]latform` chip label + ≥ 1 platform token (Android/iOS/Linux/macOS/Web/Windows). Authoring deviation : the chip is `Platform` (singular) on pub.dev, not `Platforms` ; grep broadened case-insensitive accordingly |
| FR-T52-E-003 | Skip-pass on transport failure (non-2xx, curl error, network unreachable) |
| FR-T52-E-004 | Wall-clock budget ≤ 10 s for L2 ; 20 s hard timeout via `timeout 20` outer + `curl --max-time 10` inner |

#### Cluster 6 — `docs/CONTRIBUTING.md` (FR-T52-F-001..003)

| FR | Subject |
|---|---|
| FR-T52-F-001 | `Adding a Standard` section present |
| FR-T52-F-002 | Cross-reference to agent file H2 verbatim (option b preferred over verbatim embedding) |
| FR-T52-F-003 | Q-006 mention by name |

#### Cluster 7 — `docs/LINTING.md` (FR-T52-G-001..002)

| FR | Subject |
|---|---|
| FR-T52-G-001 | Informative rule paragraph noting checklist is procedural, not enforced by `constitution-linter.sh` |
| FR-T52-G-002 | Cross-reference to agent file H2 verbatim |

#### Cluster 8 — CHANGELOG + CI matrix + forge-questions (FR-T52-H-001..003)

| FR | Subject |
|---|---|
| FR-T52-H-001 | `CHANGELOG.md [Unreleased]` entry under `### Added` |
| FR-T52-H-002 | `.github/workflows/forge-ci.yml` matrix entry after `t5-otel-live-run.test.sh` |
| FR-T52-H-003 | `bin/forge-questions.sh --change t5-2-platform-verification` surfaces no open questions (Q-001 + Q-002 both `answered`) |

### Non-Functional Requirements

| NFR | Subject |
|---|---|
| NFR-T52-001 | Zero new external dependency added (curl is pre-existing) |
| NFR-T52-002 | Wall-clock ≤ 5 s L1 ; ≤ 15 s L1+L2. Measured : 0.06 s L1 / 0.31 s L1+L2 — 78× / 49× under budget |
| NFR-T52-003 | Auditability via REVIEW.md ledger |
| NFR-T52-004 | Backward compat — no break to existing harness / CI / J.7 / archived changes |
| NFR-T52-005 | No content modification to existing standards beyond `standards-lifecycle.md` |
| NFR-T52-006 | No CLI surface impact (no `@sdd-forge/cli` flag / subcommand change) |
| NFR-T52-007 | Harness failure messages cite the failing FR identifier first |
| NFR-T52-008 | Article XII compliance (additive bump + REVIEW append-only + `expires_at: never` structural exemption preserved) |
| NFR-T52-009 | Article III.4 reinforcement self-consistency. Every claim in the checklist verifiable by adopter following linked references. **Validated** by independent code-reviewer pass which caught the Article VIII → III.4 fabricated citation pre-archive |
| NFR-T52-010 | Verbatim H2 cross-referencing across the 4 reinforcing surfaces ; drift guard enforced by harness L1 assertions |

## ADRs (resolution surface)

- **ADR-T52-001** — Forge-local override (Option A) + cadence embedding in standards-lifecycle (Option B) combined ; Option C (upstream OMC PR) deferred post-T5.3.
- **ADR-T52-002** — L2 = pub.dev tooling smoke on `flutter_bloc` ; opt-in via `FORGE_T52_LIVE=1` ; skip-pass on transport failure.
- **ADR-T52-003** — Verbatim H2 cross-referencing as drift guard ; harness L1 enforces both canonical strings on all 4 surfaces.
- **ADR-T52-004** — Harness structure mirrors J.7 / I.5 / K.3 pattern.

## Out of scope (asserted negatively)

- No new `.forge/standards/*.yaml` file.
- No retroactive re-ratification of the 6 ratified YAML standards or the 9 existing `global/*.md` standards.
- No `constitution-linter.sh` enforcement rule for the checklist (deferred ; possibly T6+).
- No upstream OMC PR (deferred per ADR-T52-001 option C).
- No update to `flutter/opentelemetry.md` — T5.3 scope.
- No new Forge agent persona.
- No CLI flag / subcommand / behaviour change to `@sdd-forge/cli`.

## Lessons (post-archive)

The most consequential learning from T5.2 is the **self-applied meta-validation** : an independent code-reviewer pass attempted to verify the checklist's claims against the actual Forge constitution and immediately found that the change cited "Article VIII (anti-hallucination)" — a hallucinated reference (Article VIII is actually "Infrastructure" ; the anti-hallucination clause is Article III.4 "Ambiguity Protocol"). The mistake propagated across 14 occurrences in 6 surfaces before being caught. This is exactly the class of bug T5.2 exists to prevent ; the fact that T5.2 itself contained the bug — and that the bug was caught only by an independent reviewer running the very methodology T5.2 codifies — is the most direct possible validation of the methodology.

**Operational consequence for T5.3 (`t5-otel-dartastic-realign`)** : it MUST tick the 3-axis checklist inline on the Dartastic ratification AND submit to an independent code-reviewer pass before archive, mirroring the T5.2 process. The Author-and-Reviewer separation pattern (« never self-approve in the same active context » per CLAUDE.md guidance) is operationally non-negotiable for any change that touches external-dependency pins or constitutional citations.
