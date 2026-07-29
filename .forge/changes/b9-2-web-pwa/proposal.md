# Proposal: b9-2-web-pwa

<!-- Created: 2026-07-27 -->
<!-- Schema: default -->
<!-- Audit: B.9.2 (docs/new-archetypes-plan.md §5.2 — web-pwa/ Qwik subfolder) -->

## Problem

B.9.1 declared the `web-pwa` layer (path `web-pwa/`, agent Iris-Web) but shipped no
templates for it, which is exactly why `mobile-pwa-first / 2.0.0` is `stage: candidate`
/ `scaffoldable: false`. This brick renders that layer: a Qwik City PWA with a Service
Worker, a web app manifest, an offline shell and Web Push (VAPID) — the channel
`docs/ARCHITECTURE-TARGET.md` §6.3 prescribes as the default for Web, Android and
desktop, with the native Flutter `app` surface as the iOS fallback when push is
critical.

**Ground truth (re-read live 2026-07-27, Article III.4):**

- **The B.8.9 Qwik skeleton is reusable in shape, not wholesale.**
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/frontend/web-public/` is 10
  files: `package.json` / `vite.config.ts` / `tsconfig.json` / `qwik.env.d.ts` /
  `.nvmrc` / `README.md` / `src/{root,entry.ssr}.tsx` / `src/routes/index.tsx` /
  `src/lib/connect-client.ts`. **`connect-client.ts` MUST NOT be copied**: it wires a
  Connect-ES v2 transport to a backend, and `mobile-pwa-first` has **no backend layer**
  — that is the whole basis of B.9.1's `layer_profile: client-only`. Copying it would
  reintroduce, at the template level, exactly the fiction ADR-B9-1-001 refused at the
  schema level.

- **`mobile-only` is the ONLY archetype with no `scaffold-plan.yaml`.**
  `bin/forge-init-mobile-only.sh:113-122` rolls its own `rsync -a --delete-excluded`
  plus a `*.tmpl` sed-substitute-and-rename loop. `full-stack-monorepo` (2 plans),
  `ai-native-rag` and `event-driven-eu` all render through
  `.forge/scripts/scaffolder/overlay.sh`. Template volume to port: **48 files, 40 of
  them `.tmpl`**.

  **The deciding evidence** (established live, and the reason the original framing of
  Q-002 was wrong): the bespoke wrapper writes **no `scaffold-manifest.yaml`** (0
  occurrences), while `overlay.sh` writes one carrying the archetype version, a plan
  SHA and a template-set SHA — and **8 harnesses depend on that manifest**:
  `a7.test.sh` (`forge upgrade`), `b8-10` / `b8-12` / `b8-15` (flagship migration +
  upgrade matrix), `b6-8`, `b7-7`, `c1`, `scaffolder`. B.9.9 *is* a migration script
  and B.9.11 *is* a promotion gate, so rendering through the bespoke wrapper would
  make `mobile-pwa-first` inherit `mobile-only`'s exclusion from all of it.

- **`web-frontend.yaml`'s pins are past their own declared review cadence.**
  Frontmatter says `version: 1.0.0`, `last_reviewed: 2026-06-03`,
  `expires_at: 2027-06-03`; `pin_review_cadence` declares **`qwik: P30D`**,
  `qwik_city: P30D`, `vite: P30D`. Today is **54 days** after `last_reviewed` — the
  per-pin cadence has lapsed by 24 days. The standard is **not** EXPIRED (the 12-month
  `expires_at` is far off), so B.9.2 cannot treat it as a clean pin source: it must
  **verify-then-pin LIVE** (mandatory anyway under Article III.4 and the T5.3.2 /
  b8-coroot lesson) and then decide whether to bump `web-frontend.yaml`'s
  `last_reviewed`, which is a standards-lifecycle event requiring a `REVIEW.md` ledger
  entry (→ ADR-B9-2-003).
  Note `vite: "7.3.5"` is an **exact** pin, excluded from Vite 8 by Qwik 1.20.0's peer
  range `>=5 <8`; whether that still holds is a live question, not an assumption.

- **`bin/forge-review-standards.sh` does not catch this.** Run live: it reports
  `80 standards, status CLEARED` (13 FRESH, 3 STRUCTURAL, 64 NO-FRONTMATTER). It scans
  `.md` standards' frontmatter and does **not** evaluate `pin_review_cadence` on the
  `.yaml` manifests. So the lapse above is invisible to the K.5 tooling. Recorded here;
  fixing the tool is **not** this brick's scope.

- **No standard governs the PWA concerns.** `web-frontend.yaml` covers the Qwik City
  surface and says nothing about Service Workers, Web Push / VAPID, `manifest.json` or
  the offline shell (confirmed: zero occurrences). B.9.1 recorded them as
  `delivered_by: B.9.2` with no invented name. This brick must either extend
  `web-frontend.yaml` or create a new role-named standard (→ ADR-B9-2-004).

- **Dispatch key — maintainer decision 2026-07-27.** The `mobile-pwa-first:` key is
  added **by this brick**, not by a separate `b9-2a` mirroring `b7-2a`. Consequence:
  `forge init --archetype mobile-pwa-first` moves from **exit 2** (dispatch gate,
  `init.ts:210-217`) to **exit 3** (`init.ts:238`, no scaffoldable version — the schema
  stays `candidate` until B.9.11). **`b9-1.test.sh` T-022 and T-L2-001 are coupled to
  this and MUST be flipped in this same change**; b9-1 documented the coupling
  precisely so it could not be missed.

## Solution

Render the `web-pwa` layer as a Qwik City PWA template subtree, register the archetype
in the dispatch table, and flip the two coupled b9-1 assertions. The archetype stays
`candidate` / `scaffoldable: false` — promotion remains B.9.11's (ADR-B9-1-002).

Decisions reserved for `/forge:design` (ADRs); leanings stated:

- **ADR-B9-2-001 — how much of the B.8.9 skeleton to reuse.** Lean: reuse the
  build/config spine (`package.json`, `vite.config.ts`, `tsconfig.json`,
  `qwik.env.d.ts`, `.nvmrc`, `root.tsx`, `entry.ssr.tsx`, `routes/index.tsx`) and
  **omit `connect-client.ts`** entirely.
- **ADR-B9-2-002 — rendering path. DECIDED 2026-07-28 (maintainer, Q-002).**
  Author a **full `scaffold-plan.yaml` covering both surfaces**: port the 48
  `mobile-only` files into plan entries and add the new `web-pwa/` ones alongside.
  One renderer (`overlay.sh`), and `mobile-pwa-first` emits a `scaffold-manifest.yaml`
  from day one — so B.9.9 (migration) and B.9.11 (promotion) inherit no debt.
  *The original framing — "needs a check that overlay.sh can target a subfolder" —
  was a misconception, retained here as a record: `overlay.sh` is plan-driven and
  every `templates[]` entry declares its own `target` path (42 of event-driven-eu's
  48 entries already write into subdirectories). Targeting `web-pwa/` was never in
  question; the real question was renderer scope.*
  **Cost to control**: the port MUST be verified byte-for-byte against the current
  bespoke output (render both ways into tmpdirs, `diff -r`) — mechanical, and it
  belongs in `b9-2.test.sh` as a load-bearing assertion, not as a claim.
- **ADR-B9-2-003 — `web-frontend.yaml` pin handling.** Lean: verify-then-pin LIVE at
  `/forge:implement`; if the live versions differ from the recorded pins, bump the
  standard with a `REVIEW.md` entry; if they match, still refresh `last_reviewed` and
  say so in the ledger.
- **ADR-B9-2-004 — where the PWA concerns are standardised.** Lean: extend
  `web-frontend.yaml` with a PWA section rather than create a fourth web standard,
  since it is already role-named and Qwik-agnostic. Alternative: a dedicated
  `pwa.yaml`. Decide with the live evidence.
- **ADR-B9-2-005 — Web Push / VAPID scope.** Lean: ship the client-side registration
  and manifest only; a push *server* implies a backend this archetype does not have.
  Where VAPID keys come from is an adopter concern to document, not to scaffold.

## Scope In

- `.forge/templates/archetypes/mobile-pwa-first/2.0.0/web-pwa/**` (Qwik City + Service
  Worker + manifest + offline shell).
- **The `app` surface port (ADR-B9-2-002)**: the 48 `mobile-only` template files
  carried into `.forge/templates/archetypes/mobile-pwa-first/2.0.0/` and expressed as
  `scaffold-plan.yaml` entries, so one `overlay.sh` render produces both surfaces and
  emits a `scaffold-manifest.yaml`. `mobile-only`'s own tree stays byte-untouched —
  this is a copy-forward, not a move.
- **A byte-equivalence gate** in `b9-2.test.sh`: render the ported plan and the
  current bespoke wrapper into two tmpdirs and `diff -r` the `app` surface. The port
  is only correct if that diff is empty.
- Dispatch-table registration of `mobile-pwa-first:` + the scaffolder wrapper
  (`bin/forge-init-mobile-pwa-first.sh`, overlay-driven).
- Flipping `b9-1.test.sh` T-022 and T-L2-001 (coupled — exit 2 → 3).
- Standard work for the PWA concerns (ADR-B9-2-004) + any `web-frontend.yaml` pin
  refresh with its `REVIEW.md` entry.
- New harness `b9-2.test.sh`.

## Scope Out (Explicit Exclusions)

- **Shared OIDC templates** (Flutter `AuthGateway` + TS client) — B.9.3. This brick
  ships no auth wiring.
- **Decision-tree prose** in `docs/ARCHETYPES.md` — B.9.4.
- **Hera bloc generators** — B.9.5. **CI `pwa-deploy` job** — B.9.7.
- **Snapshot tarball** — B.9.8. **Migration script** — B.9.9. **MIGRATION-PATHS** —
  B.9.10. **Promotion flip** — B.9.11 (the archetype stays candidate here).
- **Any edit to `mobile-only`** — the legacy alias stays byte-equivalent.
- **Fixing `forge-review-standards.sh`** to evaluate `pin_review_cadence` on `.yaml`
  manifests — recorded above as a real gap, but K.5 territory, not B.9.2's.

## Impact

- **Users**: `forge init --archetype mobile-pwa-first` starts refusing with exit 3
  instead of 2 — a more accurate refusal ("known archetype, no scaffoldable version")
  but still a refusal; nothing renders until B.9.11 promotes. `mobile-only` adopters
  are unaffected.
- **Technical**: first templates under the new archetype; the dispatch table gains a
  key; `b9-1.test.sh` changes two assertions.
- **Risk**: the `web-frontend.yaml` pin lapse means live versions may have moved.
  Vite 8 compatibility with the Qwik 1.x peer range is the specific thing to check.

## Constitution Compliance

- **Article I**: `b9-2.test.sh` RED before any template lands.
- **Article III.4**: no pin written before `/forge:implement` resolves it live. The
  cadence lapse, the `connect-client.ts` exclusion, the bespoke-renderer finding and
  the review-standards blind spot are all recorded, not smoothed over.
- **Article IV**: additive; `mobile-only` untouched.
- **Article VI**: the native `app` surface is not modified here.
- **Article XII**: no amendment.

## Open Questions (seed)

- **Q-001** — how much of the B.8.9 skeleton to reuse, and confirmation that
  `connect-client.ts` is excluded (→ ADR-B9-2-001).
- **Q-002** — ~~`overlay.sh` vs extending the bespoke renderer~~ **ANSWERED
  2026-07-28**: full `scaffold-plan.yaml` covering both surfaces (→ ADR-B9-2-002).
  Decided on the `scaffold-manifest.yaml` evidence — the bespoke wrapper emits none,
  and 8 harnesses including `a7` and the B.8 migration/upgrade suite depend on it.
- **Q-003** — `web-frontend.yaml` pin refresh + whether the bump is a version bump or
  only a `last_reviewed` refresh (→ ADR-B9-2-003).
- **Q-004** — extend `web-frontend.yaml` vs a new `pwa.yaml` (→ ADR-B9-2-004).
- **Q-005** — Web Push scope without a backend (→ ADR-B9-2-005).
