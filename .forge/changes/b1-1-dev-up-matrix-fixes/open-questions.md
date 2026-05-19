# Open Questions — b1-1-dev-up-matrix-fixes

<!--
Per `.forge/standards/global/open-questions.md`. Schema below
mirrors `f1-open-questions` FR-OQ-001..014. The change cannot
archive while any Q-NNN is `Status: open`.
-->

## Q-001: `image: scratch` replacement strategy

- **Status**: answered
- **Raised in**: specs.md FR-B1-DUM-002
- **Raised on**: 2026-05-19
- **Raised by**: bfontaine

### Question

The `fsm-backend` placeholder in
`.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl:60`
must become functional without forcing every adopter to immediately
edit the rendered file. Three options surface (plan §0.4) :

- **Option A** — Working stand-in image (`traefik/whoami` or
  equivalent, listening on :80 with 200 OK).
- **Option B** — Docker Compose `profiles: ["backend"]` opt-in.
- **Option C** — Commented `fsm-backend` block.

### Resolution

- **Resolved on**: 2026-05-19
- **Decision**: **Option A — `traefik/whoami:latest`** with
  `--port 8080` flag and healthcheck path adjusted from
  `/health` to `/`. See `design.md::ADR-B1-DUM-001`.
- **Rationale**: smoke must validate the full Compose wiring
  chain (env-file, port mapping, depends_on, healthcheck
  convergence) ; Options B and C skip the backend entirely from
  the default smoke. `traefik/whoami` is the canonical wiring
  placeholder, ~5 MB, verified publisher (Traefik Labs),
  responds 200 OK on `GET /`. Adopter migration = 1-line image
  swap + 1 healthcheck path. Option B (profiles) requires a
  Compose re-design that is explicitly scope-out for hygiene
  (deferred to B.8 / T6). Option C is brittle for adopters
  (forces uncomment + edit before smoke is runnable).

---

## Q-002: `version:` removal — bare delete vs schema header comment

- **Status**: answered
- **Raised in**: specs.md FR-B1-DUM-020
- **Raised on**: 2026-05-19
- **Raised by**: bfontaine

### Question

Compose v2 deprecates the top-level `version:` key. Strict delete
is fine, but should a 1-line comment explain why the key is gone
so an adopter does not "fix" it by re-adding `version: "3.X"` ?

- **Option A** — Bare delete.
- **Option B** — Delete + leave a 1-line `#` comment.

### Resolution

- **Resolved on**: 2026-05-19
- **Decision**: **Option B — bare delete + 1-line
  forward-defensive comment**. See `design.md::ADR-B1-DUM-002`.
- **Rationale**: the comment costs 1 line and prevents a future
  adopter from "fixing" the apparent omission by re-adding
  `version: "3.X"`. Compose v2 → v3 migration churn (2023–2024)
  left many engineers convinced the `version:` field is
  mandatory ; the comment is a forward-defensive footgun shield.
  Form :
  ```yaml
  # Compose v2 — no top-level `version:` key (deprecated 2024-01,
  # inferred from filename).
  ```

---

## Q-003: E2E cycle placement — Taskfile vs blocking e2e suite

- **Status**: answered
- **Raised in**: specs.md FR-B1-DUM-063
- **Raised on**: 2026-05-19
- **Raised by**: bfontaine

### Question

The `task dev:up` + `docker compose ps` + `task dev:down` cycle
assertion must live somewhere. Two locations :

- **Option A** — Keep in Taskfile `dev-up-matrix` (opt-in,
  current location).
- **Option B** — Promote to blocking step in
  `cli/test/e2e/archetypes-smoke.test.ts`.

### Resolution

- **Resolved on**: 2026-05-19
- **Decision**: **Option A — Taskfile-only**, with a parallel L2
  opt-in in the new `t5-3-1.test.sh` harness gated by
  `FORGE_B1DUM_DOCKER=1` AND `command -v docker`. See
  `design.md::ADR-B1-DUM-003`.
- **Rationale**: Option B adds Docker daemon dependency, image
  pulls, `up -d` wait, and `down` to every PR — empirically
  90–180 s wall-clock multiplied across the existing CI matrix.
  Cost-benefit is unfavourable for the regression class T5.3.1
  targets (already caught by the L1 grep tests). The L2 opt-in
  mirrors the precedent set by `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`
  (ADR-T5-OLR-005, ratified by Eris). Adopter projects inherit
  the Taskfile leg automatically when they run `task validate`.

---

## Q-005: SigNoz / OTel-collector image pins are rotting upstream

- **Status**: wontfix
- **Raised in**: evidence.md T-VAL-005 (L2 dry-run 2026-05-19)
- **Raised on**: 2026-05-19
- **Raised by**: bfontaine

### Question

The L2 dry-run (`FORGE_B1DUM_DOCKER=1 task dev:up`) on a freshly
scaffolded `full-stack-monorepo` after T5.3.1 fixes succeeds at
pulling `traefik/whoami:latest` (ADR-B1-DUM-001) and the postgres /
kong images, but fails on `signoz/frontend:0.55.1` :

```
Error response from daemon: manifest for signoz/frontend:0.55.1
not found: manifest unknown: manifest unknown
```

The pin was shipped by `t5-otel-stack` (archived 2026-05-10) and
has rotted upstream (image either retagged or removed from Docker
Hub between 2026-05-10 and 2026-05-19).

### Resolution

- **Resolved on**: 2026-05-19
- **Decision**: **wontfix in T5.3.1**. The proposal explicitly
  scope-outs SigNoz / OBI / Coroot / OTel-collector layout
  ("layout stays as shipped by T5 `t5-otel-stack` … T5.3.1 =
  template hygiene, not re-architecture B.8"). Image-pin refresh
  belongs in a separate change (`t5-otel-stack-image-refresh` or
  similar, pattern mirrors `t5-cargo-pin-refresh` Option B
  follow-on to `cli-trust-harness`). Tracked in
  `docs/new-archetypes-plan.md` §0.5 as a T5 follow-up candidate.
- **Rationale**: T5.3.1's L1 contract (9/9 GREEN) is met. L2 is
  opt-in and does not gate CI (ADR-B1-DUM-003 / precedent
  ADR-T5-OLR-005). L2 correctly captured the upstream blocker —
  which is the documented purpose of L2 — and the blocker is
  logged for the next focused change.

---

## Resolution summary

| ID    | Status   | Resolution                                                                       |
|-------|----------|----------------------------------------------------------------------------------|
| Q-001 | answered | **ADR-B1-DUM-001** — Option A `traefik/whoami:latest` + `--port 8080` + `/` probe |
| Q-002 | answered | **ADR-B1-DUM-002** — Option B bare delete + 1-line forward-defensive comment      |
| Q-003 | answered | **ADR-B1-DUM-003** — Option A Taskfile + L2 opt-in `FORGE_B1DUM_DOCKER=1`         |
| Q-005 | wontfix  | upstream `signoz/frontend:0.55.1` manifest gone — follow-up change candidate `t5-otel-stack-image-refresh` |
