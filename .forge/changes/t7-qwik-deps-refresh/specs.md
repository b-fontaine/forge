# Specs — `t7-qwik-deps-refresh`

**Namespace** : `FR-T7QD-*`, `NFR-T7QD-*`, `ADR-T7QD-*`.

---

## Functional Requirements

### FR-T7QD-001 — the rendered surface has no known vulnerability

`npm audit` on a freshly rendered `web-pwa/` MUST report zero advisories. Achieved with
`overrides: { "sharp": "^0.35.4" }` — the first release outside `<=0.35.4-rc.0`.

### FR-T7QD-002 — the pins that move, move to a verified version

`typescript ^7.0.2`, `@types/node ^24.13.4`, `vite-tsconfig-paths ^6.1.1`, each proven
by `npm install` + `tsc --noEmit` + `qwik build` on a real render.

### FR-T7QD-003 — the pins that must not move, do not

`vite` stays **exactly** `=7.3.6` (qwik 1.20.0 peers `">=5 <8"`); `@builder.io/qwik`,
`@builder.io/qwik-city` and `oauth4webapi` are already at their maximum; the `ignore`
devDependency stays until upstream declares it.

### FR-T7QD-004 — `@types/node` tracks the pinned runtime

It MUST match `.nvmrc`'s major. npm latest (26.5.1) describes a runtime this surface
does not run on.

### FR-T7QD-005 — `b9-2::T-037` guards all four

Parsed JSON, never text: the manifest's own `_audit` block discusses every one of these
strings, and a textual grep would read that prose as the assertion.

### FR-T7QD-006 — CHANGELOG

### FR-T7QD-007 — every Qwik template carries the sharp override

`ai-native-rag/1.0.0/frontend/web-public/package.json.tmpl` and
`full-stack-monorepo/2.0.0/frontend/web-public/package.json.tmpl` MUST declare
`overrides: { "sharp": "^0.35.4" }`, like `web-pwa`. `npm audit --audit-level=high` on a
freshly rendered `ai-native-rag` `frontend/web-public/` MUST exit 0.

### FR-T7QD-008 — the sibling templates honour the standard's exact vite pin

Both sibling templates MUST pin `vite` to `=7.3.6`, the value `web-frontend.yaml`
declares, and their `README.md.tmpl` pin tables MUST say the same.

### FR-T7QD-009 — `web-frontend.yaml` owns the sharp floor

`versions.sharp` records the override floor (`0.35.4`), with its removal trigger in the
adjacent comment and a `pin_review_cadence` entry. The standard moves `1.2.0` → `1.3.0`
(additive: one pin, no rule), `last_reviewed` is refreshed, and `REVIEW.md` gains the
ledger row `b8-9::T-008` requires for the declared version.

### FR-T7QD-010 — `b8-9::T-014` guards every Qwik template against the standard

Discovery, not enumeration (ADR-T5QCI-002): every `package.json.tmpl` under
`.forge/templates` that installs `@builder.io/qwik` or `@builder.io/qwik-city`, in
`dependencies` or `devDependencies`; a discovered file that installs neither is reported,
not skipped silently. For each, on **parsed JSON**:
`overrides.sharp` MUST equal `^` + the standard's `versions.sharp`, and
`devDependencies.vite` MUST equal `=` + the standard's `versions.vite`. The standard's
values MUST be read from inside its `versions:` block only. Where the surface's `README.md.tmpl` has a pin table — recognised by its `| Resource | Pin |`
header, not by the rows under test — it MUST carry exactly one `vite` row and one `sharp`
row (resource cell matched with backticks stripped), and each row's **Pin cell** — not the
whole row — MUST state the standard's value (FR-T7QD-008). Anti-vacuity: zero discovered surfaces,
an unreadable pin, or zero README pin rows checked across all surfaces, FAILS.

### FR-T7QD-011 — the records name every surface

The CHANGELOG `[Unreleased]` Security entry MUST name all three Qwik surfaces, state
which were reachable through `forge init` in 0.5.1, and give existing `ai-native-rag`
projects the manual workaround. The roadmap's verification-gap row and plan §0.15 MUST
stop describing the fix as web-pwa-only.

---

## Non-Functional Requirements

### NFR-T7QD-001 — no downgrade to clear an advisory

`npm audit fix --force` proposes qwik-city 1.16.1. Moving *below* the pinned line to
satisfy a scanner trades a known CVE for an unknown regression and a standard violation.

### NFR-T7QD-002 — every version comes from a resolve

`npm outdated` / `npm view` on a real tree, not from memory. Three of its four
suggestions were rejected on evidence.

### NFR-T7QD-003 — guards mutation-proven

### NFR-T7QD-004 — no forge-ci line spent

The extension's guard lives in `b8-9.test.sh`, already registered. `forge-ci.yml` stays
at its current line count; the ~19 lines under `NFR-CI-002` remain B.3's.

---

## ADRs

### ADR-T7QD-001 — override the transitive floor, do not move the pinned line

**Context.** Two HIGH `sharp` advisories reach the surface through qwik-city's own dependency
chain. npm's remedy is a qwik-city downgrade.

**Decision.** `overrides: { "sharp": "^0.35.4" }`.

**Rationale.** The vulnerability is in `sharp`, not in qwik-city; 0.35.4 exists and is
compatible. Overriding fixes the actual defect and leaves the framework's pinned line
where `web-frontend.yaml` puts it. Downgrading would satisfy the scanner by moving four
minors backwards through code nobody has evaluated.

**Consequence.** The override must be revisited when qwik-city ships a vite-imagetools
that depends on sharp >=0.35.4 itself — stated in the manifest so whoever reads it next
knows when it becomes dead weight.

### ADR-T7QD-002 — "up to date" means current for the pinned runtime

**Context.** `npm outdated` reports `@types/node` 22 → 26.5.1.

**Decision.** `^24.13.4`, matching `.nvmrc`.

**Rationale.** A types package describes a runtime. Pinning types for node 26 in a
surface that runs node 24 makes the compiler agree to APIs that will not exist. Latest
is the right answer for a library and the wrong one for `@types/*`.

**Consequence.** `@types/node` now moves when `.nvmrc` does, and T-037 fails if they
drift apart — which turns a silent mismatch into a red test.

### ADR-T7QD-003 — the override floor belongs to the standard, not to each manifest

**Context.** The first pass kept `web-frontend.yaml` out of scope because none of its
pins moved. The reopened scope puts the same override on three surfaces, and the audit
that reopened it found two of them already out of step with the standard's vite pin —
per-manifest literals drift.

**Decision.** `web-frontend.yaml` `versions.sharp: "0.35.4"` is the single source; each
surface writes `^` + that value; `b8-9::T-014` compares each surface to the standard,
never to a second literal.

**Rationale.** This is exactly how the `ignore` workaround is already held
(`versions.ignore` + `b8-9::T-013`): a workaround pin with a documented removal
trigger and a review cadence, owned by the standard that pins Qwik for all surfaces.
Holding the same class of pin two different ways would be the inconsistency.

**Consequence.** Raising or dropping the floor is a standard change (BDFL merge,
`REVIEW.md` row) applied to every surface in lock-step, and T-014 fails on any surface
left behind. `b9-2::T-037` keeps its own `>= 0.35.4` check on `web-pwa`; the two agree
today and T-014 is the one that follows the standard.
