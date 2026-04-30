# Design (infra layer): demo-003-rate-limit

<!-- Layer: infra -->
<!-- Audit: C.1 — per-layer design under Janus orchestration -->

## Cross-Layer References

This is the **infra half** of demo-003-rate-limit. The backend
half lives at `design-backend.md`.

Cross-layer FRs :
- `FR-IN-001` — Kong rate-limit plugin (this layer's only FR).
- `FR-BE-001` — backend handler instrumentation (drives the
  observation of the rate-limit hits).

## Architecture Decisions

### ADR-IN-001: `rate-limiting` plugin with `policy: local`, threshold 10/min

**Context.** Kong offers two rate-limit policies : `local`
(in-memory per Kong node) and `cluster` (Cassandra/Postgres
backed). The example deployment is single-node Kong from
`docker-compose.dev.yml`. `cluster` would require a counter
backend.

**Decision.**

- Use `policy: local` for the demo. Adopters scaling to multiple
  Kong nodes MUST switch to `cluster` (documented as a future
  follow-up in `infra/kong/kong.yml.example` comment).
- Threshold : `minute: 10`. Illustrative — production thresholds
  depend on the consumer SLO.
- `fault_tolerant: true` so a Kong process restart does not
  punish current callers ; the counter restarts cleanly.

**Consequences.**

- ✅ Self-contained for the demo — no external dependency.
- ⚠️ Counter is per-node ; horizontal scale forces the policy
  switch. Documented.
- ✅ Fault tolerance default reflects the audit's preference for
  graceful degradation.

### ADR-IN-002: Plugin declared at the route level, not the service level

**Context.** Kong plugins can be declared at four scopes : global,
service, route, consumer. The Greeter has one route today ; a
service-level scope would also work.

**Decision.** Declare at the **route level** for the demo, with
a comment explaining that service-level scoping is acceptable
once the Greeter ships multiple routes (e.g. v2 alongside v1).
The route-level scope makes the demo's intent unambiguous : the
plugin protects this specific endpoint.

**Consequences.**

- ✅ Unambiguous intent.
- ⚠️ Adopters adding more routes for the same service must
  remember to attach the plugin per-route ; the comment flags
  this.

## Standards Applied

- `infra/kong.md` — declarative configuration only ; no Admin
  API curl scripts.
- `infra/docker-compose.md` — Kong runs in the `fsm-` service
  prefix in the example's `docker-compose.dev.yml`.

✅ Infra constitutional gate green.
