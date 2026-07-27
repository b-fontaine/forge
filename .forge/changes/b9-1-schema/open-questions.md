# Open Questions — b9-1-schema

<!--
Per `.forge/standards/global/open-questions.md` (Article III.4 mechanisation).
Q-NNN sequential, never reused. Resolved questions are kept indefinitely.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: How does a backend-less archetype satisfy the `{backend, frontend, infra}` layer invariant?

- **Status**: answered
- **Raised in**: proposal.md, specs.md (FR-B9-1-012, FR-B9-1-014, ADR-B9-1-001)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

`check_versioned_schema_siblings` (`.forge/scripts/validate-foundations.sh:436-438`)
hard-requires every versioned archetype schema to declare layers including
`backend`, `frontend` **and** `infra`. `mobile-pwa-first` is by construction a
client-only archetype — its predecessor `mobile-only` is described verbatim as
*"No backend, no infrastructure, no BaaS"*. Its two real surfaces are the native
Flutter app and the Qwik `web-pwa/` channel.

Three candidate resolutions:

- **(a) Stub layers** — declare `backend` + `infra` as deferred/empty. Cheapest, but
  violates FR-B9-1-012 and hands every downstream B.9 brick two layer ids that
  scaffold nothing.
- **(b) Narrow validator relaxation** — introduce an explicit discriminator (e.g.
  `layer_profile: multi-layer | client-only`) defaulting to today's enforced
  behaviour, and require the triple only for `multi-layer`. Honest and
  backward-compatible, but edits the **B.8.3.b-owned shared validator** and therefore
  cascades to `b8-3b.test.sh` plus any sibling harness asserting the current KO
  string. The full cascade must be enumerated in `design.md` first.
- **(c) Stay out of the versioned family** — keep the legacy `schema.yaml` shape only.
  Forfeits the versioned scaffolder routing that B.9.8 (snapshot) and B.9.11
  (promotion flip) depend on.

**Leaning: (b).** This is a maintainer decision, not a self-approvable one: it
determines whether B.9.1 remains purely additive or touches shared infrastructure
used by three other archetypes.

### Resolution

- **Resolved on**: 2026-07-27
- **Decision**: **(b) — narrow validator relaxation.** Introduce `layer_profile:`
  with values `multi-layer` (the **default**, preserving today's enforced behaviour
  byte-for-byte) and `client-only`. The `{backend, frontend, infra}` requirement is
  enforced only for `multi-layer`; `client-only` keeps the non-empty-`layers` rule and
  the full per-layer contract (`id` / `path` / `fr_id_prefix` / `primary_agent`).
  `mobile-pwa-first / 2.0.0` declares two real layers — `app` (Flutter native, Hera)
  and `web-pwa` (Qwik City, Iris-Web).
- **Rationale**: (a) would have violated FR-B9-1-012 and handed every downstream B.9
  brick two layer ids that scaffold nothing; (c) would have forfeited the versioned
  scaffolder routing that B.9.8 and B.9.11 depend on. (b) keeps the schema honest
  while leaving all three existing versioned archetypes bit-identical in meaning.
- **Blast radius (established live, 2026-07-27)** — narrower than feared, because
  `validate-foundations.sh` contains **two independent layer checks**, not one:
  - **`:125` — `FR-GL-001`**, on the *canonical* `schema.yaml` (legacy family).
    Message: `layers must include at least backend, frontend, infra`. Asserted by
    `foundations.test.sh:140` (`test_schema_layers_under_three_fails`).
    **NOT touched** — `mobile-pwa-first/2.0.0.yaml` is a versioned file.
  - **`:436-438` — `check_versioned_schema_siblings`**, on `X.Y.Z.yaml` siblings.
    Message: `layers must include backend, frontend, infra`. **No harness asserts
    this literal string** (searched across all 76 suites). This is the only
    *enforcement* site the relaxation changes; the patch has **two hunks** in total —
    this block, and the `OK:` line (`:458` → `:469`) which gains `profile={...}`
    (prefix-safe for its one consumer, `b8-3b.test.sh:112` `grep -qF`).
  - `b6-1` / `b7-1` / `b8-3` `.test.sh` reference the triple in **T-008 header
    comments** and assert it against *their own* schemas, which keep all three
    layers ⇒ unaffected.
  - `b6-8` / `b7-7` / `c1` `.test.sh` run **independent** Python layer checks against
    example projects, not the validator ⇒ unaffected.
  - `b8-3b.test.sh` (12 L1 tests) exercises the versioned validator itself and MUST be
    re-run; `_test_b83b_l1_005_canonical_still_pass` and the negative cases are the
    ones to watch.
  - ~~**Mirror sync: 7 copies**~~ — **corrected at implementation 2026-07-27**: only
    **1 committed file** changes. `cli/assets/` is gitignored (`npm run bundle`
    output); the 5 copies under `examples/` are 396-line B.1-baseline scaffolded
    artefacts that never contained `check_versioned_schema_siblings` and must NOT be
    synced. See design.md ADR-B9-1-001 §Consequences.

## Q-002: Which brick owns the candidate→stable promotion flip?

- **Status**: answered
- **Raised in**: proposal.md, specs.md (ADR-B9-1-002)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

B.6 and B.7 both put the flip in their harness brick (`b6-7-harness`, `b7-6-harness`),
with the reference example following afterwards. B.9's plan (§5.2) lists the harness
as B.9.11 — last. Confirm the flip belongs to B.9.11, and that B.9.8 (snapshot
tarball) runs before it rather than after.

### Resolution

- **Resolved on**: 2026-07-27
- **Decision**: the flip belongs to **B.9.11**; **B.9.8 runs before it** (ADR-B9-1-002).
- **Rationale**: the snapshot tarball is an input to the promotion gate, matching
  B.6.7 / B.7.6 exactly. Every sibling brick asserting `candidate` will need updating
  at the flip — the `b7-6` cascade lesson applies verbatim.

## Q-003: Is the PWA-vs-native channel decision a schema phase or a design constraint?

- **Status**: answered
- **Raised in**: specs.md (FR-B9-1-022, ADR-B9-1-003)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

ARCH §6.3 prescribes: PWA for Web|Android, native iOS fallback when push is critical.
Does that become a distinct `channel-decision` phase in the schema's phase chain, or a
constraint attached to the existing `design` phase? The prose decision tree itself is
B.9.4's deliverable either way.

### Resolution

- **Resolved on**: 2026-07-27
- **Decision**: a **distinct `channel-decision` phase, placed between `specs` and
  `features`** (ADR-B9-1-003).
- **Rationale**: BDD scenarios differ by channel (PWA install-prompt vs native
  push-permission), so the channel must be fixed before `features` authors them —
  attaching it to `design` would make `features` guess. B.6.1 set the precedent by
  adding `event-design` / `saga-orchestration` on the same reasoning.

## Q-004: Layer identity and forward mapping of `mobile-only`'s single `app` layer

- **Status**: answered
- **Raised in**: specs.md (FR-B9-1-042, ADR-B9-1-004)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

What are the layer ids for the two surfaces, and how does `mobile-only`'s single
`- id: app / path: .` map forward onto them? `bin/forge-migrate-mobile-pwa.sh` (B.9.9)
must honour the mapping when it adds `web-pwa/` to an existing `mobile-only` install
without touching the native tree.

### Resolution

- **Resolved on**: 2026-07-27
- **Decision**: layers are **`app`** (path `.`, `FR-APP-`, Hera) and **`web-pwa`**
  (path `web-pwa/`, `FR-PWA-`, Iris-Web). `mobile-only`'s `- id: app / path: .`
  maps **1:1** onto `app` — same id, same path (ADR-B9-1-004).
- **Rationale**: the 1:1 mapping makes B.9.9's migration **purely additive** — it
  creates `web-pwa/` and rewrites nothing in the native tree, which is exactly the
  property plan §5.2 asks of B.9.9. Keeping `app` at path `.` also means `mobile-only`
  adopters see no path churn.

## Q-005: Deferred Service Worker / Web Push / VAPID standard gap

- **Status**: answered
- **Raised in**: specs.md (FR-B9-1-031, ADR-B9-1-005)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

`web-frontend.yaml` v1.0.0 (B.8.9) governs the Qwik City surface but says nothing about
Service Workers, Web Push/VAPID, `manifest.json` or the offline shell. Confirm these
are referenced as `delivered_by: B.9.2` with no inline pin and no invented standard
name, rather than being folded into `web-frontend.yaml` by B.9.1.

### Resolution

- **Resolved on**: 2026-07-27
- **Decision**: **reference-only**, `delivered_by: B.9.2`, no inline pin, and
  `web-frontend.yaml` is **not** edited by B.9.1 (ADR-B9-1-005).
- **Rationale**: folding PWA concerns into `web-frontend.yaml` is a decision that
  needs live evidence about Service Worker / VAPID tooling, which only B.9.2's
  verify-then-pin pass will have. Inventing a standard name here would violate
  Article III.4.
