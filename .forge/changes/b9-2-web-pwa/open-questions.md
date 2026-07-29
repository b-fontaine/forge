# Open Questions — b9-2-web-pwa

<!--
Per `.forge/standards/global/open-questions.md` (Article III.4 mechanisation).
Q-NNN sequential, never reused. Resolved questions are kept indefinitely.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: How much of the B.8.9 Qwik skeleton is reusable?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-2-001)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

`full-stack-monorepo/2.0.0/frontend/web-public/` is 10 files. Which port forward, given
that `mobile-pwa-first` has no backend layer?

### Resolution

- **Resolved on**: 2026-07-28
- **Decision**: port the build/config spine; then **three** targeted changes, not one
  omission — omit `src/lib/connect-client.ts`, **rewrite** `src/routes/index.tsx`,
  **prune** `@connectrpc/connect` + `@connectrpc/connect-web` from `package.json`
  (ADR-B9-2-001).
- **Rationale**: the exclusion is not a simple file drop. `index.tsx.tmpl:8` imports
  `sayHello` from the connect client and `package.json.tmpl:30-31` declares both
  Connect deps. Removing only the file would leave a broken import and two unused
  backend dependencies in a backend-less archetype.

## Q-002: Renderer scope — `overlay.sh` or the bespoke `mobile-only` renderer?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-2-002)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

Extend the self-contained `forge-init-mobile-only.sh` loop, or render through
`overlay.sh` — and if the latter, does the whole `app` surface port too?

### Resolution

- **Resolved on**: 2026-07-28 (maintainer)
- **Decision**: full `scaffold-plan.yaml` covering **both** surfaces, rendered by
  `overlay.sh` (ADR-B9-2-002).
- **Rationale**: the bespoke wrapper emits no `scaffold-manifest.yaml`; `overlay.sh`
  does, and 8 harnesses key off it (`a7`, `b8-10`, `b8-12`, `b8-15`, `b6-8`, `b7-7`,
  `c1`, `scaffolder`). B.9.9 is a migration script and B.9.11 a promotion gate, so the
  bespoke path would inherit `mobile-only`'s exclusion from all of it.
- **Note on the original framing**: this question was first written as "check that
  `overlay.sh` can target a subfolder", which was a misconception — `overlay.sh` is
  plan-driven and every entry declares its own `target` (42 of event-driven-eu's 48
  already write into subdirectories). Recorded rather than silently reworded.

## Q-003: What happens to `web-frontend.yaml`'s lapsed pin cadence?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-2-003)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

`pin_review_cadence` declares `P30D` for qwik/qwik_city/vite with
`last_reviewed: 2026-06-03` — lapsed. Does B.9.2 bump the standard's version, or only
refresh `last_reviewed`?

### Resolution

- **Resolved on**: 2026-07-28
- **Decision**: resolve versions **live at `/forge:implement`**, never at design. If
  they differ from the recorded pins → bump `versions:` + the standard's `version:`
  per SemVer + refresh `last_reviewed`. If they match → refresh `last_reviewed` only.
  **A `REVIEW.md` entry is appended either way**, stating which happened
  (ADR-B9-2-003).
- **Rationale**: the branch cannot be chosen before the live check exists; committing
  to either now would be exactly the unverified assertion Article III.4 forbids.
  Specifically flagged for the live pass: `vite: "7.3.5"` is an exact pin justified
  *solely* by Qwik's peer range excluding Vite 8 — if that range moved, the pin's
  justification is gone.

## Q-004: Where are the PWA concerns standardised?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-2-004)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

Extend `web-frontend.yaml` with a PWA section, or create a dedicated standard?

### Resolution

- **Resolved on**: 2026-07-28
- **Decision**: a **new role-named `.forge/standards/pwa.yaml`** (ADR-B9-2-004).
  **This reverses the lean recorded in the proposal** ("extend `web-frontend.yaml`");
  reading the file changed the answer.
- **Rationale**: `web-frontend.yaml` is a *framework-selection* standard — its payload
  is `default: qwik-city`, `alternatives:`, `forbidden: []` and the chosen framework's
  pins. PWA capability is **orthogonal to framework choice**: the same obligations
  apply under SvelteKit. Folding them in would give that file two responsibilities and
  make a SvelteKit adopter read Qwik-titled prose for rules that are not Qwik's. A
  separate role-named manifest matches the `gateway.yaml` / `identity.yaml` /
  `persistence.yaml` family.
- **Consequence**: B.9.1's four `delivered_by: B.9.2` forward-pointers must now name
  `pwa.yaml` (asserted by T-020).

## Q-005: What is the Web Push scope without a backend?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-2-005)
- **Raised on**: 2026-07-27
- **Raised by**: @bfontaine

### Question

How much of Web Push can an archetype with no backend legitimately scaffold?

### Resolution

- **Resolved on**: 2026-07-28
- **Decision**: **client side only** — service-worker push handling plus the
  subscription call. No push server, no VAPID key generator, no key storage. VAPID
  provenance is documented as an adopter responsibility in the `web-pwa` README and in
  `pwa.yaml` (ADR-B9-2-005).
- **Rationale**: a push server is a backend, and `layer_profile: client-only` is this
  archetype's defining constraint (ADR-B9-1-001). Scaffolding one would recreate at the
  template level the fiction B.9.1 refused at the schema level — the same error shape
  as copying `connect-client.ts`. A scaffolded project can receive push only once the
  adopter supplies a sender, and the README must say so plainly rather than imply
  a working end-to-end path.

## Q-006: Wrapper-side Kotlin relocation, or restructure the Android template?

- **Status**: answered
- **Raised in**: specs.md (→ ADR-B9-2-006)
- **Raised on**: 2026-07-28
- **Raised by**: @bfontaine

### Question

`android/app/src/main/kotlin/{{reverse_domain_path}}/` is a literal directory holding
`MainActivity.kt.tmpl` and `PlayIntegrityService.kt.tmpl`. `overlay.sh` substitutes only
in file **contents** (`:187-189`) and uses `entry['target']` literally, so a plan target
cannot be domain-derived. Do we relocate in the wrapper, or restructure the template
onto a fixed directory (legal in Kotlin, where package need not match path) and let the
`package` declaration carry the domain?

### Resolution

- **Resolved on**: 2026-07-28
- **Decision**: **relocate in the wrapper**, post-overlay, reproducing
  `bin/forge-init-mobile-only.sh:136-146`. `overlay.sh` is not modified
  (NFR-B9-2-001). Restructuring is rejected (ADR-B9-2-006).
- **Rationale — the decision is forced, not preferred.** FR-B9-2-004 requires the
  ported `app` surface to be byte-identical to the bespoke render. Restructuring
  changes the directory layout, so the equivalence diff could never be empty. The two
  requirements are incompatible, and byte-equivalence is the one protecting existing
  adopters. The restructuring remains technically viable and is recorded as
  out-of-scope for a later brick that could also re-baseline the expected output.
