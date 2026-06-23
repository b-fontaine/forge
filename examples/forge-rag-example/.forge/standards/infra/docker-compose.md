<!-- Audit: B.1.5 (part of b1-foundations) -->
<!-- Stage: draft -->

# Docker Compose (local dev)

This standard applies only when `.forge.yaml` declares `schema: full-stack-monorepo`. It governs the **local development** compose stack exclusively — integration tests use a separate `docker-compose.e2e.yml`, and production workloads run on Kubernetes (see `infra/k8s.md`, forthcoming). The goal is to provide reproducible local stacks that faithfully mirror the production service topology without incurring Kubernetes overhead during inner-loop development. Reproducibility here means that any developer, on any machine, running `task dev:up` obtains an identical service graph with deterministic hostnames and startup ordering.

## Service naming (fsm-*)

All services declared in the compose file MUST carry the `fsm-` prefix (standing for **full-stack-monorepo**). This convention prevents hostname and network collisions when a developer runs multiple Forge-scaffolded monorepos concurrently on the same Docker daemon.

Three canonical services are REQUIRED in every full-stack-monorepo compose stack:

- `fsm-backend` — the primary application backend (Rust gRPC service or equivalent).
- `fsm-kong` — the API gateway (Kong), handling REST↔gRPC transcoding per Article VIII.1.
- `fsm-db` — the relational datastore (Postgres or a project-approved equivalent).

Two optional observability services MAY be added when the team opts into local observability:

- `fsm-otel-collector` — OpenTelemetry collector receiving OTLP from all services.
- `fsm-signoz` — SigNoz all-in-one, consuming from the collector.

```yaml
# docker-compose.dev.yml — service naming skeleton
services:
  fsm-db:
    image: postgres:16-alpine

  fsm-backend:
    build: ./backend

  fsm-kong:
    image: kong:3-alpine

  # Optional — opt-in only
  fsm-otel-collector:
    image: otel/opentelemetry-collector-contrib:latest

  fsm-signoz:
    image: signoz/signoz:latest
```

## Réseau unique (fsm-dev)

Every service in the stack MUST be attached to a single named network called `fsm-dev`. Relying on Docker Compose's implicit default `bridge` network is FORBIDDEN.

**Rationale**: A named network provides deterministic hostname resolution (each service is reachable by its service name as a DNS hostname within the network), explicit service discovery, and isolation from other compose stacks running simultaneously on the same machine. The default bridge network is shared and its hostname behaviour changes between Docker Engine versions; `fsm-dev` is unambiguous.

The `fsm-dev` network MUST be declared at the top-level `networks:` key and referenced explicitly in every service's `networks:` block:

```yaml
# docker-compose.dev.yml — network declaration
networks:
  fsm-dev:
    driver: bridge

services:
  fsm-db:
    image: postgres:16-alpine
    networks:
      - fsm-dev

  fsm-backend:
    build: ./backend
    networks:
      - fsm-dev

  fsm-kong:
    image: kong:3-alpine
    networks:
      - fsm-dev
```

No service MAY omit the `networks:` block. A service without an explicit network attachment is a constitutional violation (Article VIII.5 — infrastructure as code, no implicit shared state).

## Healthchecks obligatoires

Every service MUST declare a `healthcheck:` block. Acceptable probe mechanisms include:

- HTTP probe via `curl` or `wget` (for HTTP-speaking services).
- `pg_isready` (for Postgres).
- A custom shell command that exits `0` only when the service is ready to accept traffic.

The bare list form of `depends_on` is BANNED:

```yaml
# FORBIDDEN — does not wait for readiness
depends_on:
  - fsm-db
```

`depends_on` MUST use the extended form with `condition: service_healthy`:

```yaml
# REQUIRED — waits for the healthcheck to pass
depends_on:
  fsm-db:
    condition: service_healthy
```

**Rationale**: Race conditions at startup are the single most frequent cause of flaky local-dev loops and flaky integration tests. A backend that starts before Postgres is ready will fail its first migration and leave the developer stack in an inconsistent state. The extended `depends_on` form eliminates this class of failure entirely.

The following snippet shows a complete `fsm-db` healthcheck and a `fsm-backend` that correctly waits for it:

```yaml
# docker-compose.dev.yml — healthcheck example
services:
  fsm-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    networks:
      - fsm-dev
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 10s

  fsm-backend:
    build: ./backend
    env_file: .env
    networks:
      - fsm-dev
    depends_on:
      fsm-db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s

networks:
  fsm-dev:
    driver: bridge
```

Note: per Article VIII.3, base images SHOULD be distroless or alpine variants. The `postgres:16-alpine` and `kong:3-alpine` images satisfy this requirement. Custom service images MUST use multi-stage builds and a distroless or alpine final stage.

## Variables d'env (.env.example versionné)

Secrets and runtime configuration are managed through two files with strictly separate roles:

**`.env.example`** (committed to the repository):
- Lists every environment variable consumed by any compose service.
- All values MUST be stubs or placeholders (e.g., `DB_PASSWORD=changeme`, `API_KEY=your-api-key-here`).
- NEVER contains real credentials, tokens, or secrets — not even values that "look fake" but happen to be real.
- This file is part of the project's API to contributors: it documents the full set of required variables.

**`.env`** (gitignored):
- Contains local developer values, loaded via the `env_file: .env` directive on each service.
- MUST be listed in `.gitignore`. Any commit containing a `.env` file is a constitutional violation.

**The co-commit rule**: any new environment variable added to a compose service MUST appear in `.env.example` in the same commit. This rule will be enforced by a pre-commit hook delivered under `b1-delivery` milestone G.2.

A lightweight CI check SHOULD parse the compose file for `${VAR}` substitution patterns and assert that every referenced variable is present as a key in `.env.example`. This prevents silent breakage when a variable is added to the compose file but forgotten in `.env.example`:

```yaml
# .env.example — fully documented, never real values
DB_USER=forge
DB_PASSWORD=changeme
DB_NAME=forge_dev
DB_PORT=5432

BACKEND_PORT=8080
KONG_ADMIN_PORT=8001
KONG_PROXY_PORT=8000

OTEL_EXPORTER_OTLP_ENDPOINT=http://fsm-otel-collector:4317
```

**Warning**: never use inline `environment:` with hardcoded values — even values that appear harmless or fake leak into the git log and Docker image layer history, where they may be extracted by future tooling or collaborators.

```yaml
# FORBIDDEN — hardcoded inline value
environment:
  DB_PASSWORD: supersecret123

# REQUIRED — reference only, value lives in .env
env_file: .env
```

## Interdiction docker-compose.yml non suffixé

The compose file governing local development MUST be named `docker-compose.dev.yml`. A bare `docker-compose.yml` at the repository root is FORBIDDEN.

Additional compose stacks are allowed, each with an explicit, descriptive suffix:

| Stack | File name |
|---|---|
| Local development | `docker-compose.dev.yml` |
| End-to-end / integration tests | `docker-compose.e2e.yml` |
| Local observability | `docker-compose.obs.yml` |
| Load testing (if applicable) | `docker-compose.load.yml` |

**Rationale**: In a monorepo, multiple compose stacks coexist over time. An unsuffixed `docker-compose.yml` is ambiguous: running `docker-compose up` with no `-f` flag causes Docker Compose to pick it up automatically, potentially starting the wrong stack. For example, a developer intending to run e2e tests may inadvertently start the dev stack — or vice versa — leading to port conflicts, unexpected data mutations, and hard-to-diagnose failures. Explicit suffixes force the developer to invoke stacks through named Taskfile aliases, eliminating accidental cross-stack starts.

All compose invocations MUST go through Taskfile aliases (delivered by `b1-scaffolder`). Direct `docker-compose` calls on the command line are SHOULD NOT be used:

```yaml
# Taskfile.yml — compose stack aliases (excerpt)
tasks:
  dev:up:
    desc: Start the local development stack
    cmd: docker-compose -f docker-compose.dev.yml up --build -d

  dev:down:
    desc: Stop the local development stack
    cmd: docker-compose -f docker-compose.dev.yml down

  e2e:up:
    desc: Start the end-to-end test stack
    cmd: docker-compose -f docker-compose.e2e.yml up --build -d

  e2e:down:
    desc: Stop the end-to-end test stack
    cmd: docker-compose -f docker-compose.e2e.yml down

  obs:up:
    desc: Start the local observability stack
    cmd: docker-compose -f docker-compose.obs.yml up -d

  obs:down:
    desc: Stop the local observability stack
    cmd: docker-compose -f docker-compose.obs.yml down
```

---

**Constitutional references**:

- **Article VIII** (Infrastructure mandates) — reproducibility, explicit dependencies, and no implicit shared state underpin every rule in this standard. The `fsm-dev` network, named file suffixes, and committed `.env.example` are direct expressions of these principles.
- **Article VIII.3** (Minimal runtime) — each service image MUST use a distroless or alpine base image for its production/runtime stage. Multi-stage Dockerfiles are required; build-time tools MUST NOT be present in the final image layer.
- **Article VIII.5** (Infrastructure as Code) — all compose configuration is version-controlled. No manual edits to running containers. Drift from the committed compose file is a constitutional violation.
