# Tasks (infra layer): demo-003-rate-limit

<!-- Layer: infra -->
<!-- TDD-ordered (structural validation = tests). All marked [x] post-archive. -->

## Phase 1: Kong plugin declaration

- [x] **RED** — Add a structural assertion in
  `c1.test.sh` (or a dedicated `infra` harness) that verifies
  `infra/kong/kong.yml.example` contains a service `greeter`
  with a route, and a `rate-limiting` plugin entry on that
  route with `config.minute == 10`. Run — fail (no plugin yet).
  [Story: FR-IN-001]
- [x] **GREEN** — Update `infra/kong/kong.yml.example` :
  - Add a `services:` entry `greeter` pointing at
    `grpc://fsm-backend:9090`.
  - Add a `routes:` entry under that service for path
    `/greeting.v1.GreeterService/*`.
  - Add a `plugins:` entry under that route :
    `name: rate-limiting`, `config.minute: 10`,
    `config.policy: local`, `config.fault_tolerant: true`.
  Run — pass. [Story: FR-IN-001]

## Phase 2: Compose validation

- [x] Run `docker compose -f docker-compose.dev.yml config` to
  confirm the compose still parses cleanly with the updated
  Kong config (no implicit dependency on the plugin).
- [x] `bash .forge/scripts/verify.sh` infra section green
  (kong.yml YAML parse OK).

## Phase 3: BDD scenarios

- [x] `features/rate_limit.feature` covers within-threshold +
  above-threshold + tracing-event scenarios. Steps not yet
  runtime-wired (require a live Kong instance) ; documented
  for adopter inspection only.
