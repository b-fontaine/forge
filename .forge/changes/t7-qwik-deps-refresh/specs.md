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

---

## Non-Functional Requirements

### NFR-T7QD-001 — no downgrade to clear an advisory

`npm audit fix --force` proposes qwik-city 1.16.1. Moving *below* the pinned line to
satisfy a scanner trades a known CVE for an unknown regression and a standard violation.

### NFR-T7QD-002 — every version comes from a resolve

`npm outdated` / `npm view` on a real tree, not from memory. Three of its four
suggestions were rejected on evidence.

### NFR-T7QD-003 — guards mutation-proven

---

## ADRs

### ADR-T7QD-001 — override the transitive floor, do not move the pinned line

**Context.** Three HIGH advisories reach the surface through qwik-city's own dependency
chain. npm's remedy is a qwik-city downgrade.

**Decision.** `overrides: { "sharp": "^0.35.4" }`.

**Rationale.** The vulnerability is in `sharp`, not in qwik-city; 0.35.4 exists and is
compatible. Overriding fixes the actual defect and leaves the framework's pinned line
where `web-frontend.yaml` puts it. Downgrading would satisfy the scanner by moving two
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
