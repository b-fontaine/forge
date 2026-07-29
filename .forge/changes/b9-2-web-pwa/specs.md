# Specifications: b9-2-web-pwa

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.9.2 (docs/new-archetypes-plan.md §5.2 — web-pwa/ Qwik subfolder + app-surface port) -->

**Namespace** : `FR-B9-2-*` / `NFR-B9-2-*` / `ADR-B9-2-*`.
**Constitution** : v2.0.0, unchanged, no amendment.
**Governing articles** : I (TDD), II (BDD — this brick ships user-facing behaviour, so
scenarios are required), III.1/III.2, III.4 (Anti-Hallucination / verify-then-pin),
IV (delta-based), VI (Flutter architecture, `app` surface), X.1 (80 % coverage).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §5.2 B.9.2 (effort M) |
| **Layer contract** | `.forge/schemas/mobile-pwa-first/2.0.0.yaml` (B.9.1) — `app` at `.` (Hera), `web-pwa` at `web-pwa/` (Iris-Web), `layer_profile: client-only` |
| **Qwik precedent** | `full-stack-monorepo/2.0.0/frontend/web-public/` (B.8.9), 10 files. **`src/lib/connect-client.ts` excluded** — no backend layer exists here |
| **Renderer (observed)** | `.forge/scripts/scaffolder/overlay.sh` — plan-driven; each `templates[]` entry carries its own `target`. Substitutes exactly **three** placeholders at `:187-189`: `<project-name>`, `<reverse-domain>`, `<root-module>`. **Does NOT consume `post_steps`** (0 occurrences; the key in existing plans is declarative). **Cannot relocate a directory** (0 `mv`/rename occurrences) |
| **Wrapper pattern (observed)** | `bin/forge-init-ai-native-rag.sh` (B.7.2, ADR-B7-2-007) — a *gated real body*: reads the schema `stage`/`scaffoldable` itself and refuses exit 3 with zero filesystem writes while candidate; renders via `overlay.sh`, **never** `init.sh` (which is hardcoded to full-stack-monorepo) |
| **Port source (observed)** | `.forge/templates/archetypes/mobile-only/` — 48 files, 40 `.tmpl`, **no `scaffold-plan.yaml`** (the only archetype without one) |
| **Placeholder delta (observed)** | Template **contents** use exactly two: `{{project_name}}` ×29, `{{reverse_domain}}` ×10. **`{{reverse_domain_path}}` appears in zero file contents** — it exists only as a literal **directory name** on disk: `android/app/src/main/kotlin/{{reverse_domain_path}}` |
| **Bespoke renderer (observed)** | `bin/forge-init-mobile-only.sh:123-126` seds the three `{{…}}` forms; `:136-146` relocates the Kotlin package directory post-substitution via `mkdir -p` + `rsync` + `rm -rf` |
| **Pin source** | `web-frontend.yaml` v1.0.0, `last_reviewed: 2026-06-03`, `pin_review_cadence` qwik/qwik_city/vite `P30D` — **cadence lapsed** (→ ADR-B9-2-003) |
| **Downstream gated by this** | B.9.3 … B.9.11 |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — The `app` surface port (FR-B9-2-001 → 007)

##### FR-B9-2-001 — copy-forward, never move
All 48 files under `.forge/templates/archetypes/mobile-only/` MUST be reproduced under
`.forge/templates/archetypes/mobile-pwa-first/2.0.0/`. `mobile-only`'s own tree, its
wrapper and its dispatch entry MUST remain byte-unchanged (it is a still-supported
legacy alias).

##### FR-B9-2-002 — placeholder rewrite, exhaustive and mechanical
Every `{{project_name}}` (29 occurrences) MUST become `<project-name>` and every
`{{reverse_domain}}` (10) MUST become `<reverse-domain>`, matching `overlay.sh:187-189`.
After the port, **zero `{{…}}` tokens may remain** in any ported file content.

##### FR-B9-2-003 — the Kotlin package directory is wrapper-side, not overlay-side
`android/app/src/main/kotlin/{{reverse_domain_path}}` is a **directory name**, not file
content, and `overlay.sh` can neither substitute it nor relocate a directory. The new
wrapper MUST perform the relocation after the overlay render, reproducing the semantics
of `bin/forge-init-mobile-only.sh:136-146`. `overlay.sh` MUST NOT be modified by this
brick.

##### FR-B9-2-004 — byte-equivalence of the `app` surface
Rendering the ported plan and rendering the current bespoke wrapper, with identical
`--project-name` / `--reverse-domain`, MUST produce **byte-identical** `app`-surface
trees. Asserted by `diff -r` over two tmpdirs, ignoring only files this brick
deliberately adds. **This is the acceptance criterion of the whole port** — a claim of
equivalence is not acceptable in its place.

##### FR-B9-2-005 — a real `scaffold-plan.yaml`
`.forge/templates/archetypes/mobile-pwa-first/scaffold-plan.yaml` MUST exist and carry
`archetype` / `version` / `templates[]` (each with `source`, `target`, `substitute`),
parity with `event-driven-eu/scaffold-plan.yaml`. It MUST cover **both** surfaces.

##### FR-B9-2-006 — a `scaffold-manifest.yaml` is emitted
A render MUST produce `<target>/.forge/scaffold-manifest.yaml` (archetype version,
plan SHA, template-set SHA), which the bespoke `mobile-only` renderer never wrote.
This is the reason ADR-B9-2-002 chose the full port: `a7`, `b8-10`, `b8-12`, `b8-15`,
`b6-8`, `b7-7`, `c1` and `scaffolder` harnesses all key off that manifest.

##### FR-B9-2-007 — gated wrapper
`bin/forge-init-mobile-pwa-first.sh` MUST follow the ADR-B7-2-007 gated-real-body
pattern: read the schema's `stage`/`scaffoldable`, and while `candidate` refuse with
exit 3, a structured `[REFUSAL …]` on stderr and **zero filesystem writes**. The gate
opens with no edit to the wrapper when B.9.11 promotes.

#### Cluster 2 — The `web-pwa` surface (FR-B9-2-010 → 015)

##### FR-B9-2-010 — Qwik City skeleton, minus the backend client
The `web-pwa/` subtree MUST provide the B.8.9 build/config spine — `package.json`,
`vite.config.ts`, `tsconfig.json`, `qwik.env.d.ts`, `.nvmrc`, `README.md`,
`src/root.tsx`, `src/entry.ssr.tsx`, `src/routes/index.tsx`. It MUST NOT include
`src/lib/connect-client.ts` nor any Connect-ES dependency: there is no backend layer.

##### FR-B9-2-011 — web app manifest
A manifest MUST be scaffolded with at minimum `name`, `short_name`, `start_url`,
`display`, `theme_color`, `background_color` and at least one icon entry, sufficient
for Android/desktop installability.

##### FR-B9-2-012 — Service Worker + offline shell
A Service Worker MUST be scaffolded and registered, and MUST serve a navigable offline
shell. **BDD-required** (FR-B9-2-030).

##### FR-B9-2-013 — Web Push registration, client side only
Client-side push subscription MUST be scaffolded. A push **server** MUST NOT be —
it implies a backend this archetype does not have. VAPID key provenance MUST be
documented as an adopter responsibility, not scaffolded (→ ADR-B9-2-005).

##### FR-B9-2-014 — verify-then-pin LIVE, no inherited pins
Every `web-pwa` dependency version MUST be resolved live at `/forge:implement`.
`web-frontend.yaml`'s recorded pins are past their declared `P30D` cadence and MUST
NOT be copied on trust. The Qwik peer range vs Vite 8 MUST be re-checked specifically.

##### FR-B9-2-015 — no state-management alternative
The `web-pwa` surface MUST NOT introduce a Flutter state-management library. Article
VI.3 is Flutter-scoped and is not extended to this surface (the B.9.1 F7 correction).

#### Cluster 3 — Dispatch registration and the coupled flips (FR-B9-2-020 → 023)

##### FR-B9-2-020 — dispatch key
`.forge/scaffolding/dispatch-table.yml` MUST gain a top-level `mobile-pwa-first:` key
(`name`, `scaffolder`, `description`, `signals`, `since`). The `mobile-only:` entry and
its `status: legacy_alias` / `target:` / `migration:` fields MUST be preserved.

##### FR-B9-2-021 — the refusal moves 2 → 3
With the key registered, `forge init --archetype mobile-pwa-first` MUST refuse with
**exit 3** (`init.ts:238`, no scaffoldable version) instead of exit 2 (dispatch gate).
Nothing may be rendered while the schema is `candidate`.

##### FR-B9-2-022 — flip the two coupled b9-1 assertions, in this change
`b9-1.test.sh` **T-022** (asserts no `mobile-pwa-first:` key) and **T-L2-001** (asserts
exit 2) MUST both be updated here. B.9.1 recorded this coupling explicitly; leaving
either unflipped turns the b9-1 suite red.

##### FR-B9-2-023 — schema stays candidate
`.forge/schemas/mobile-pwa-first/2.0.0.yaml` MUST remain `stage: candidate` /
`scaffoldable: false`. Promotion is B.9.11's (ADR-B9-1-002).

#### Cluster 4 — Standards (FR-B9-2-030 → 031)

##### FR-B9-2-030 — the PWA concerns get a standard
Service Worker, Web Push/VAPID, manifest and offline shell MUST be governed by a
standard — either a PWA section added to `web-frontend.yaml` or a new role-named
manifest (→ ADR-B9-2-004). B.9.1 recorded them as `delivered_by: B.9.2`; that
forward-pointer MUST be resolved here.

##### FR-B9-2-031 — lifecycle bookkeeping
Any standard created or bumped MUST carry the 8-field frontmatter contract and get a
`.forge/standards/REVIEW.md` entry. If `web-frontend.yaml`'s pins are refreshed, its
`last_reviewed` MUST be updated and the ledger MUST say whether the live versions
matched or drifted.

## MODIFIED Requirements

### MODIFIED FR-B9-1-031: the four PWA components now name a standard

<!-- Modified by b9-2-web-pwa (2026-07-29). Original from b9-1-schema (committed d333bac). -->

- **WAS** (b9-1): "Service Worker, Web Push (VAPID), `manifest.json` and the offline
  shell have **no standard today**. They MUST be referenced as `delivered_by: B.9.2`
  with no inline pin and no invented standard name."
- **NOW**: all four MUST carry `standard: pwa.yaml` and MUST NOT carry
  `delivered_by`. The gap the original recorded is closed by this change
  (ADR-B9-2-004), so the forward-pointer would otherwise become a stale record
  pointing at work that has shipped.
- **Why an amendment and not a satisfied deferral**: unlike NFR-B9-1-002 (which
  carried its own sunset clause — *"the code is 2 … until a later brick registers a
  dispatch key, at which point it becomes 3"*) and FR-B9-1-041 (a scope constraint on
  B.9.1 that explicitly delegated the act to "B.9.2/B.9.11 territory"), FR-B9-1-031
  carried **no** sunset clause. Left unamended it would be literally false in the
  archive. Recorded here per the `b6-8-example` precedent, which amended `FR-CI-012`
  across change boundaries the same way.
- **Test impact**: `b9-1.test.sh` T-020 is re-tagged from FR-B9-1-031 to
  **FR-B9-2-030**, which is the requirement it now serves. T-022 and T-L2-001 keep
  their original tags — those FRs were satisfied-as-delegated, not amended.

### BDD Acceptance Criteria (Article II)

```gherkin
Scenario: the PWA remains usable offline
  Given a scaffolded mobile-pwa-first project with the web-pwa surface built
  And the application has been loaded once while online
  When the network becomes unavailable
  And the user navigates to the application
  Then the offline shell is served
  And no browser network-error page is shown

Scenario: the PWA is installable on Android and desktop
  Given a scaffolded mobile-pwa-first project with the web-pwa surface served over HTTPS
  When a supporting browser evaluates the web app manifest
  Then the manifest declares name, short_name, start_url, display and at least one icon
  And the browser reports the application as installable

Scenario: a candidate archetype refuses cleanly instead of half-rendering
  Given the mobile-pwa-first schema is stage candidate
  And the archetype is registered in the dispatch table
  When a user runs forge init --archetype mobile-pwa-first
  Then the command exits 3
  And an actionable refusal is written to stderr
  And no project directory is created
```

### Non-Functional Requirements

##### NFR-B9-2-001 — `overlay.sh` untouched
This brick MUST NOT modify `.forge/scripts/scaffolder/overlay.sh`. It is shared by
three archetypes and 8+ harnesses; the Kotlin relocation belongs in the wrapper
(FR-B9-2-003).

##### NFR-B9-2-002 — `mobile-only` untouched
No edit to `.forge/templates/archetypes/mobile-only/**`,
`bin/forge-init-mobile-only.sh`, or the `mobile-only:` dispatch entry.

##### NFR-B9-2-003 — zero regression
`verify.sh`, `constitution-linter.sh` and the sibling suites (`b9-1`, `scaffolder`,
`a7`, `b5`, `t5-1`) MUST show no new FAIL. Baseline at the time of writing:
verify.sh **573 PASS / 0 FAIL / 1 WARN**; linter **OVERALL PASS**.

##### NFR-B9-2-004 — CI budget in lockstep
Registering `b9-2.test.sh` MUST respect the NFR-CI-002 ceiling of **420** lines on
`.github/workflows/forge-ci.yml` (currently 412). If it overflows, the ceiling is
asserted in `b6-8`, `c1`, `t5-1` and `t5-otel-live-run` and they bump together.

##### NFR-B9-2-005 — harness level split
`b9-2.test.sh` L1 MUST be hermetic (no network, no Docker, no npm install). The
byte-equivalence render (FR-B9-2-004) runs at L1 — it needs only bash + rsync. Any
`npm install` / build leg MUST be L2 opt-in.

---

## ADRs (seeded — resolved at `/forge:design`)

| ADR | Question | Status |
|-----|----------|--------|
| **ADR-B9-2-001** | How much of the B.8.9 skeleton to reuse | Lean: spine yes, `connect-client.ts` no |
| **ADR-B9-2-002** | Renderer scope | **DECIDED 2026-07-28** — full plan, both surfaces, `overlay.sh` |
| **ADR-B9-2-003** | `web-frontend.yaml` pin handling after the cadence lapse | Lean: verify LIVE, then bump or refresh `last_reviewed` with a ledger entry |
| **ADR-B9-2-004** | PWA concerns: extend `web-frontend.yaml` vs a new `pwa.yaml` | Lean: extend |
| **ADR-B9-2-005** | Web Push scope without a backend | Lean: client-side only |
| **ADR-B9-2-006** | *(new)* Kotlin relocation in the wrapper vs restructuring the Android template to avoid a placeholder directory | Open — the second option would remove the need for post-overlay work entirely |

## Acceptance Criteria

1. `b9-2.test.sh` GREEN at `--level 1`; the byte-equivalence diff is empty.
2. `forge init --archetype mobile-pwa-first` exits 3, renders nothing.
3. `b9-1.test.sh` GREEN with T-022 and T-L2-001 flipped.
4. `verify.sh` and `constitution-linter.sh` show no new FAIL.
5. `mobile-only` scaffolds byte-identically to before.
6. No `{{…}}` token remains in any ported file.
7. Every `web-pwa` pin resolved live, with evidence recorded.
