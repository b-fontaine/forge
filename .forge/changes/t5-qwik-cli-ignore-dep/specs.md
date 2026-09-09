# Specs — `t5-qwik-cli-ignore-dep`

**Namespace** : `FR-T5QCI-*`, `NFR-T5QCI-*`, `ADR-T5QCI-*`.

Consolidated target on archive : `.forge/specs/b8-9-qwik-web-public.md`
(`web-frontend.yaml` is that spec's territory).

---

## Functional Requirements

### FR-T5QCI-001 — every scaffolded Qwik surface declares `ignore`

Every `package.json.tmpl` under `.forge/templates/` that declares
`@builder.io/qwik` as a dependency MUST also declare `ignore` in its
`devDependencies`.

Stated over the **set of Qwik surfaces**, not over an enumeration of the three
that exist today: a fourth surface added later inherits the requirement without
an edit here. Today the set is exactly:

- `archetypes/full-stack-monorepo/2.0.0/frontend/web-public/package.json.tmpl`
- `archetypes/ai-native-rag/1.0.0/frontend/web-public/package.json.tmpl`
- `archetypes/mobile-pwa-first/2.0.0/web-pwa/package.json.tmpl`

### FR-T5QCI-002 — the pin lives in the standard

`.forge/standards/web-frontend.yaml` MUST carry `ignore` in its `versions:`
block, with the pinned value and a comment stating that it is a workaround for
an undeclared dependency in `@builder.io/qwik`, not a Forge design choice.

The templates MUST agree with the pinned value. The standard is the single
source of truth for Qwik-surface pins (ADR-B89-005).

### FR-T5QCI-003 — the workaround is legible at the use site

Each of the three `package.json.tmpl` files MUST carry, in its `_audit` block, a
line naming the upstream cause (undeclared `ignore` in `@builder.io/qwik`'s
published `dependencies`) and the condition under which the entry may be dropped
(upstream declaring it).

Rationale: a bare `"ignore": "7.0.9"` in a devDependencies block is
indistinguishable from a real project dependency. Without the note, the correct
future action — delete it — is unavailable without re-deriving this whole
investigation.

### FR-T5QCI-004 — standard version bump and ledger

`web-frontend.yaml` MUST bump `1.1.0` → `1.2.0` (additive: one pin added, no pin
changed, no rule added) and MUST gain an append-only `REVIEW.md` row dated
2026-09-09.

### FR-T5QCI-005 — sweeping harness guard

`.forge/scripts/tests/b8-9.test.sh` MUST gain a test that **discovers** Qwik
surfaces by grep rather than listing them, and fails if any discovered surface
omits `ignore`, or if the standard omits the pin, or if a template's pin
disagrees with the standard's.

The test MUST also fail if **zero** surfaces are discovered — a discovery-based
assertion that finds nothing otherwise passes vacuously, which is the
`_test_f3_011` lesson from this same session.

### FR-T5QCI-006 — CHANGELOG entry

`CHANGELOG.md` MUST carry a `t5-qwik-cli-ignore-dep` entry under `[Unreleased]`,
stating that the flagship's shipped web build was affected.

---

## Non-Functional Requirements

### NFR-T5QCI-001 — no new transitive dependency

The added package MUST install zero transitive dependencies, verified live at
implement. `ignore@7.0.9` : MIT, `added 1 package`.

### NFR-T5QCI-002 — harness budget

The new test MUST stay within `b8-9.test.sh`'s existing L1 budget (≤ 2 s, zero
net / Docker / npm). It is a grep over template files; no install occurs.

### NFR-T5QCI-003 — no CI registration cost

The guard MUST land in an **already-registered** harness. `forge-ci.yml` is at
418 lines against a 420 cap asserted in five harnesses plus two docs
(NFR-CI-002); registering a new harness would force a lock-step bump across all
seven for a two-line defect fix. `b8-9.test.sh` is registered at
`forge-ci.yml:121` and owns `web-frontend.yaml`, so it is the correct home on
ownership grounds as well as cost.

### NFR-T5QCI-004 — the fix is proven by execution, not by grep

The L1 guard asserts declaration. Declaration is not proof the build works.
Implementation MUST additionally record a live `npm install && npm run build`
reaching exit 0 in a rendered tree, as evidence — the L1 test alone would have
passed against a wrong pin.

---

## ADRs

### ADR-T5QCI-001 — declare the missing dependency; do not re-script `build`

**Context.** `@builder.io/qwik@1.20.0` (npm `latest`) omits `ignore` from its
declared dependencies while its CLI bundle requires it at load. Every `qwik`
subcommand is dead in every Forge-scaffolded surface.

**Decision.** Add `ignore` as a `devDependency` of each Qwik surface, pinned in
`web-frontend.yaml`.

**Alternatives rejected.**

- *Bump qwik.* No fixed release exists — 1.20.0 is `latest` (verified live
  2026-09-09). Not an option, not merely a worse one.
- *Recompose `build` from `vite`.* Fixes one script, changes its meaning
  (the CLI orchestrates client + SSR + types as one step), and leaves `preview`
  and the `qwik` passthrough dead. It also converts a temporary upstream bug
  into a permanent divergence from the framework's documented scripts.

**Consequences.** We carry a dependency we do not use directly. Mitigated by
FR-T5QCI-003 (the note that says when to delete it). If upstream declares
`ignore`, our entry becomes redundant but harmless — npm dedupes it.

### ADR-T5QCI-002 — one sweeping guard, not three per-archetype copies

**Context.** The defect spans three archetypes, each with its own harness
(`b8-9`, `b7-*`, `b9-2`). The obvious move is a test in each.

**Decision.** A single discovery-based test in `b8-9.test.sh`, keyed on the
standard rather than on the archetype.

**Rationale.** Three copies assert the three surfaces that exist and are silent
about the fourth. The property that actually matters — *a surface that uses
Qwik declares what the Qwik CLI needs* — is a property of the standard, and
`b8-9` is where the standard lives. The sweep catches a future surface for free;
three enumerations would not.

**Consequence.** A `mobile-pwa-first` defect is now asserted by a harness named
for B.8.9. Accepted: the alternative is triplicated logic that drifts. The test
name and comment say so explicitly.
