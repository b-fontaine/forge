# Open Questions — b8-coroot-rehost

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN is sequential
per change, zero-padded to 3 digits, never reused.
-->

## Q-001: `versions.*` v-prefix convention in `observability.yaml`

- **Status**: answered
- **Raised in**: `.forge/changes/b8-coroot-rehost/specs.md` FR-B8-COR-032
- **Raised on**: 2026-05-24
- **Raised by**: maintainer (b8-coroot-rehost specify pass)

### Question

`observability.yaml::versions.coroot` is bumped to `"1.20.2"` (v-prefix
mandatory on GHCR per verify-then-pin evidence). The sibling field
`versions.beyla` stays `"2.0.1"` (no v-prefix, Docker Hub tolerates both).
This introduces within-file heterogeneity. Three options surface :

- (a) **v-prefix coroot only**, document the heterogeneity inline as a
  YAML comment. Cheapest. No impact on `b8-obi-refresh` ADRs.
- (b) **v-prefix all `versions.*`**, cosmetically bump `beyla` to
  `"v2.0.1"`. Crosses the trio-coupling boundary (NFR-B8-COR-008) ; would
  pre-empt `b8-obi-refresh`'s standard-bump scope.
- (c) **Drop v-prefix at template-render time** via a helper that strips
  the leading `v` when emitting Helm/Kustomize image specs that don't
  accept it. Most invasive ; adds template-rendering surface.

### Resolution

- **Resolved on**: 2026-05-24, **inverted 2026-05-25 during `/forge:implement`**
- **Decision**: Option **none of the above** — uniform no-v-prefix across
  `versions.*`. See **ADR-B8-COR-001** in `design.md` (rewritten 2026-05-25)
  + `evidence.md` § 1 (inverted transcripts).
- **Rationale**: The premise that GHCR forces v-prefix was a
  verify-then-pin mis-read introduced during `/forge:explore`
  (background-task outputs mis-labelled). At `/forge:implement` Phase 6
  the L2 manifest-pull fixture failed on `ghcr.io/coroot/coroot:v1.20.2`
  ("manifest unknown") and passed on the unprefixed `1.20.2`. The true
  GHCR convention for this image accepts the unprefixed form — same as
  Docker Hub does for `grafana/beyla:2.0.1`. **No within-file
  heterogeneity exists** ; `versions.*` is uniformly non-v-prefixed.
  The three original options (a/b/c) all addressed a false dilemma.
  Trio-coupling enforcement still holds — `b8-obi-refresh` remains
  free to choose its own pin convention. Lesson institutionalised :
  L2 manifest-pull fixture caught the inversion before archive ;
  Article III.4 (Anti-Hallucination) discipline upheld via
  verify-then-pin pass at implementation time, not assumption at
  exploration time.

---

## Q-002: Optional `coroot_registry` explicit field in `observability.yaml`

- **Status**: answered
- **Raised in**: `.forge/changes/b8-coroot-rehost/specs.md` FR-B8-COR-033
- **Raised on**: 2026-05-24
- **Raised by**: maintainer (b8-coroot-rehost specify pass)

### Question

Should `observability.yaml` gain a top-level (or nested under `versions:`)
`coroot_registry: "ghcr.io/coroot/coroot"` field? Two options :

- (a) **Add the field** — explicit registry signal for adopters and
  audit tooling. Costs one frontmatter field, one schema-test-coverage
  pass.
- (b) **Don't add** — the registry is implicit in the rendered
  `image:` line in the templated manifest. Standard frontmatter stays
  minimal.

### Resolution

- **Resolved on**: 2026-05-24
- **Decision**: Option (b) — do not add an explicit registry field.
  See **ADR-B8-COR-002** in `design.md`.
- **Rationale**: Single source of truth — the registry already appears
  in the rendered manifest's `image:` line. Adding a duplicate signal
  in the standard creates a drift surface exactly of the kind
  `j7-validate-standards-yaml` was created to police. Forward
  precedent : if a future cross-component pattern emerges, a later
  amendment can codify it.

---

## Q-003: Coroot 1.4 → 1.20 ConfigMap schema diff

- **Status**: answered
- **Raised in**: `.forge/changes/b8-coroot-rehost/specs.md` NFR-B8-COR-006
- **Raised on**: 2026-05-24
- **Raised by**: maintainer (b8-coroot-rehost specify pass)

### Question

Sixteen minor versions of upstream Coroot evolution lie between the
currently-shipped `1.4.4` and the target `1.20.2`. Atlas MUST surface
evidence during `/forge:design` confirming the existing forge-templated
Coroot manifests still deserialise against `1.20.2`. Three resolution
options :

- (a) **Grep-only** — read the Coroot CHANGELOG between 1.4.x and
  1.20.x for ConfigMap field changes ; trust upstream OSS-stability
  norms.
- (b) **Manifest-pull L2 fixture** — pull `ghcr.io/coroot/coroot:1.20.2`
  and inspect its `--help` / built-in schema. Already implemented at
  spec FR-B8-COR-072 / L2 fixture as the existence check ; extend to
  capture config-deserialisation check.
- (c) **Sample-apply on kind** — run `kind create cluster`, apply the
  templated manifest with the new pin, observe Coroot container logs
  for any schema-rejection or deprecation warning. Most empirical but
  highest test-infrastructure cost (kind on CI runner).

### Resolution

- **Resolved on**: 2026-05-24
- **Decision**: Options (a) + (b) combined ; defer (c) to
  `b8-signoz-unified` design. See **ADR-B8-COR-003** in `design.md`.
- **Rationale**: Templated ConfigMap surface is only 5 fields (listen,
  data_dir, otel.{grpc,http}.listen, integrations.collector_endpoint).
  CHANGELOG grep covers field-rename detection ; L2 manifest-pull
  fixture extended with `--help | grep -q -- --config` confirms the
  `--config` arg flag remains valid. Kind cluster spin-up cost is
  prohibitive for an infra-only template change ; B.8.8 trio sibling
  `b8-signoz-unified` is the natural venue for kind-based testing
  (5-service compose + K8s translation).

---

## Q-004: K3-RULE-001 jurisdiction posture for Coroot

- **Status**: answered
- **Raised in**: `.forge/changes/b8-coroot-rehost/specs.md` NFR-B8-COR-007
- **Raised on**: 2026-05-24
- **Raised by**: maintainer (b8-coroot-rehost specify pass)

### Question

Coroot Inc is US-incorporated (to be evidence-verified). K3-RULE-001 (T3
forbidden if US-jurisdiction publisher) applies on the CI/EE distinction
+ data-plane behavior. Four possible outcomes :

- (a) **T1/T2 OK, T3 candidate-substitution-flag** — Coroot CE OSS,
  runs entirely on adopter infra, no upstream phone-home → CE is safe
  for T1/T2 ; T3 flags it as a "candidate-substitution" without
  forbidding. Likely outcome.
- (b) **T1/T2 OK, T3 introduces new K3-RULE-EXT-NNN** — formalise
  the candidate-substitution flag as an explicit Demeter rule
  extending K3-RULE-001 with the "no upstream phone-home in CE"
  carve-out.
- (c) **All tiers OK** — Coroot CE evidence so strong that even T3
  posture accepts it ; no new rule. Less likely if K3-RULE-001 is
  read strictly.
- (d) **All tiers forbidden** — Coroot CE forbidden across all tiers
  ; this sub-change pivots from "rehost" to "substitute-candidate
  exercise". Significant scope creep.

### Resolution

- **Resolved on**: 2026-05-24
- **Decision**: Option (a) — T1/T2 OK, T3 candidate-substitution flag
  documented in `observability.yaml::rationale`, no new K.3 rule in
  this sub-change. See **ADR-B8-COR-004** in `design.md`.
- **Rationale**: K3-RULE-001 is a publisher-jurisdiction rule
  targeting services that ingest adopter data into US-jurisdiction
  infrastructure. Coroot CE OSS does not do that — it runs entirely
  on adopter infra under Apache-2.0 with no upstream phone-home
  (evidence collected in `evidence.md` during `/forge:implement`).
  Trio-coupling enforcement (NFR-B8-COR-008) forbids touching K.3
  standards from a B.8.8 sub-change. The precedent established :
  OSS-US-publishers with CE-no-phone-home get a `rationale` flag,
  not a `forbidden:` list entry. If `b8-signoz-unified` or a future
  US-OSS-observability arrival triggers pattern recurrence, a K.3
  amendment can codify the precedent then.
