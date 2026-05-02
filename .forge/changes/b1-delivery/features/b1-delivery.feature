# <!-- Audit: B.1.9 + B.1.12 + B.1.14 (b1-delivery, Phase 8.3) -->
# BDD acceptance criteria for the full-stack-monorepo archetype's
# delivery surface : per-layer CI gates, Kustomize overlays, and
# the local OTel + SigNoz observability stack. Mirrors AC-001,
# AC-002, AC-006, AC-007, AC-008 from .forge/changes/b1-delivery/specs.md.

Feature: full-stack-monorepo delivery surface
  As an adopter who scaffolds a project via
    /forge:init --archetype full-stack-monorepo
  I want the CI gates, K8s overlays, and observability stack to
    work end-to-end the moment the project is generated
  So that I can focus on product code rather than rebuild the
    deployment surface from scratch.

  Background:
    Given a project freshly scaffolded via "/forge:init --archetype full-stack-monorepo"

  Scenario: AC-001 — backend workflow ignores out-of-scope changes
    Given a pull request that touches only "frontend/lib/main.dart"
    When the pull request is opened
    Then the "forge-backend.yml" workflow runs
    But every job in "forge-backend.yml" reports "skipped"
    And the workflow status is "PASS" so branch protection is satisfied

  Scenario: AC-002 — backend workflow blocks merge on a clippy warning
    Given a pull request that introduces a "clippy::needless_clone" warning in "backend/crates/domain/src/lib.rs"
    When the pull request is opened
    Then the "forge-backend.yml" workflow runs
    And the "cargo clippy --workspace --all-targets -- -D warnings" step fails
    And the pull request is reported as failing the required "forge-backend" check

  Scenario: AC-006 — Kustomize overlays render and validate strictly
    Given the scaffolded project's "infra/k8s/" tree is unmodified
    When I run "kustomize build infra/k8s/overlays/dev"
    Then the command exits 0
    And the rendered YAML declares the namespace "<project-name>-dev"
    And the rendered image newTag matches "dev-latest"
    When the same is repeated for "overlays/staging" and "overlays/prod"
    Then both also exit 0
    And "staging" pins the image to a tag matching "sha-"
    And "prod" pins the image to a tag matching "v[0-9]"
    And the rendered YAML for every overlay passes "kubeconform --summary --strict"
    And the "prod" overlay declares a "HorizontalPodAutoscaler" with minReplicas=3, maxReplicas=10, CPU averageUtilization 70

  Scenario: AC-007 — `task dev` boots the local observability stack
    Given a clean machine with Docker Compose v2 ≥ 2.1.0
    When I run "task dev"
    Then "docker compose -f docker-compose.dev.yml up -d --wait" reports every service healthy
    And "fsm-otel-collector" is reachable on "localhost:4317" (gRPC)
    And "fsm-otel-collector" is reachable on "localhost:4318" (HTTP)
    And "fsm-signoz-frontend" is reachable on "http://localhost:3301"
    And the OTel collector logs show successful export to "fsm-signoz-query"
    And the wall-clock time is ≤ 90 seconds (NFR-015)

  Scenario: AC-008 — scaffolded apps trace to the local stack out of the box
    Given the scaffolded project running under "task dev"
    When the backend is hit by "curl http://localhost:8080/health"
    Then a span appears in the SigNoz UI under the service name "<project-name>-backend" within 30 seconds
    And the span's "service.name" resource attribute equals "<project-name>-backend"
    And the span's "deployment.environment" resource attribute equals "dev"
