# Open Questions: b6-8-example

<!-- Article III.4 anti-hallucination protocol. Genuine ambiguities are -->
<!-- recorded here rather than guessed. Resolved questions move to the    -->
<!-- design ADRs; unresolved ones BLOCK implementation per CLAUDE.md.     -->
<!-- All questions below are RESOLVED (this change is archived).          -->

## Q-1 — Render the example via the real `forge init` CLI, or via `overlay.sh` (as b7-7 did)? (RESOLVED → ADR-B6-8-001)

**Context.** `b7-7-example` rendered `forge-rag-example/` via
`overlay.sh` directly, because `ai-native-rag` was still
`stage: candidate` / `scaffoldable: false` at b7-7's creation time — its
`forge init` path refused with exit 3 (ADR-B7-7-001). b6-8's situation
is different: `event-driven-eu/1.0.0` is ALREADY `stage: stable` /
`scaffoldable: true`, promoted by `b6-7-harness`.

Two options:
- **(A) Render through the real `forge init --archetype event-driven-eu`
  CLI** — the public adopter flow, now that the archetype is promoted.
- **(B) Render via `overlay.sh` directly** — mirror b7-7 verbatim.

**Resolution → ADR-B6-8-001: Option A.** The archetype is scaffoldable,
so render through the real CLI. This is a *stronger* demonstration than
b7-7 could give: it proves `forge init` really scaffolds the promoted
archetype end-to-end, not just that the internal renderer works. Verified
LIVE: `node cli/dist/index.js init forge-eda-example --archetype
event-driven-eu --org io.forge.example --force` rendered 48 templates +
the scaffold-manifest, exit 0. The example's top-level README is then
REPLACED by the navigation README (FR-EDAEX-002), so the archetype
template's stale "candidate" README caveat is never committed.

## Q-2 — Which demo is the multi-layer (Janus) one, given the archetype has no live frontend layer? (RESOLVED → ADR-B6-8-002)

**Context.** NFR-EDAEX-005 + the c1/b7-7 precedents want ≥ 1 multi-layer
demo (≥ 2 layers → Janus, FR-GL-015). b7-7's multi-layer demo was
`[backend, frontend]` (its Qwik UI). But `event-driven-eu`'s `frontend`
layer is a single DEFERRED `ops-console` surface (ADR-B6-1-004) — there
is no web UI to demonstrate.

Options: (a) force a synthetic frontend demo (against the deferred-layer
decision); (b) make the multi-layer demo `[backend, infra]`.

**Resolution → ADR-B6-8-002: Option (b).** demo-003 (the Temporal saga)
is `[backend, infra]` — the saga naturally spans the `saga` crate
(backend) AND the Temporal cluster substrate it runs on (infra). ≥ 2
layers → Janus → per-layer designs/tasks (FR-GL-016). demo-001/002 stay
single-layer backend.

## Q-3 — 3 archived demos, or 3 archived + 1 `specified` (mirroring c1)? (RESOLVED → ADR-B6-8-003)

**Context.** §6.1 / §0.13 says "3 demos". c1 shipped 3 archived + 1
`specified` to illustrate the in-flight `[NEEDS CLARIFICATION]` state;
b7-7 shipped exactly 3 archived (ADR-B7-7-003).

**Resolution → ADR-B6-8-003: exactly 3 archived** (mirror b7-7). The
in-flight `specified` state is already demonstrated by
`forge-fsm-example`'s demo-004 (shared machinery). A future
`b6-8-followup` may add an event-driven-specific `specified` demo.
