# Open Questions — j8-janus-rules

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: SBOM tooling — handcraft Python inline vs shell-out to cyclonedx plugins?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-J8-073 / NFR-J8-005
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

CycloneDX 1.5 SBOM generation needs to walk Cargo / npm / pubspec
lockfiles and emit components. Two strategies :

- **Option A — Handcraft** : Python 3 inline parses each lockfile
  format directly (TOML stdlib for Cargo, JSON stdlib for npm,
  PyYAML for pubspec) and emits the minimum-viable CycloneDX 1.5
  JSON by hand. **No new external deps** (NFR-J8-005).
- **Option B — Shell out** : invoke `cargo cyclonedx` (Rust plugin),
  `cyclonedx-npm` (npm plugin), and the pubspec equivalent.
  Adopters must install these — adds a dependency surface.

Lean **A** for NFR-J8-005 self-imposed "no new deps" + because
the CycloneDX 1.5 mandatory fields are simple enough to handcraft
(bomFormat, specVersion, serialNumber, version, metadata.timestamp,
components[]). Resolve at design time after a quick read of the
CycloneDX 1.5 spec § "Mandatory fields".

### Resolution

- **Resolved on**: 2026-05-10 (via `design.md` ADR-J8-001)
- **Decision**: **Option A — handcraft via Python 3 inline**.
  Truly mandatory fields are `bomFormat`, `specVersion`, `version`
  (3 fields) ; we ship a richer minimum
  (+ `serialNumber`, `metadata.timestamp`, `metadata.tools`,
  `metadata.component`, `components[]`). Output via
  `json.dumps(..., sort_keys=True, indent=2)` for determinism ;
  XML via `xml.etree.ElementTree`.
- **Rationale**: Context7 review of `/cyclonedx/cyclonedx-python-lib`
  (2026-05-10) confirmed the minimum-viable CycloneDX 1.5 JSON
  fits comfortably in handcraft territory. Adopters who need
  richer SBOM features (license enrichment, vulnerability
  cross-refs, dependency graph beyond direct deps) run upstream
  tooling on the generated baseline. Zero new external dep
  preserves NFR-J8-005.

---

## Q-002: `--eu-tier` flag default — none vs T2?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-J8-042
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

When `forge init` runs without `--eu-tier`, two defaults are
plausible :

- **Option A — No default** : behaviour identical to today
  (FR-J8-042 / NFR-J8-002). Backward compat preserved. T1 / T2 / T3
  refusals only fire when the flag is explicit.
- **Option B — T2 default** : the recommended posture per
  `docs/ARCHITECTURE-TARGET.md` §10. Forces self-host
  recommendations on every new scaffold ; existing adopters may be
  surprised by previously-silent rules now firing as warnings.

Lean **A** for backward compat. A `--eu-tier` reminder warning
could be emitted to stderr when the flag is absent and no
`.forge/.forge-tier` file is present in the target tree, but this
is informational not blocking. Resolve at design.

### Resolution

- **Resolved on**: 2026-05-10 (via `design.md` ADR-J8-002)
- **Decision**: **Option A — no default**. When the flag is
  absent : `FORGE_EU_TIER=` empty ; wrappers gate their tier
  blocks on `[ -n "$FORGE_EU_TIER" ]`. NFR-J8-002 backward compat
  preserved.
- **Soft warning** : when `--eu-tier` is absent AND
  `.forge/.forge-tier` not found in the target tree, the CLI
  emits a single-line `[INFO: --eu-tier not set ...]` to stderr.
  Suppressible via `FORGE_EU_TIER_QUIET=1`.
- **Rationale**: Discoverability of the new flag without forcing
  immediate adoption. The `.forge-tier` file is a self-silencing
  signal — once written by a tier-aware init, the warning is gone.

---

## Q-003: Refusal exit code — 3 (policy) vs 4 (collision)?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-J8-023
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

Existing exit codes in the Forge CLI surface :
- `forge-snapshot.sh` : 0 / 2 (usage) / 3 (regex mismatch) / 4
  (target collision build / target missing extract) / 5 (missing
  tool).
- `validate-change-yaml.sh` : 0 / 1 (invalid) / 2 (usage).
- `validate-standards-yaml.sh` (J.7) : 0 / 1 (FAIL) / 2 (usage).

J.8 needs an exit code distinct from "invalid input" (1) and
"usage" (2) to signal "policy refusal" (request was syntactically
valid but the policy refuses it). Candidates :
- **3** : already used by `forge-snapshot.sh` for "regex mismatch"
  (a different domain). Re-using as "policy refusal" in the
  forge-init wrapper family is OK (different binary).
- **4** : already used for "I/O collision" in `forge-snapshot.sh`.
  Re-using would conflate domains.

Lean **3**. Document the convention in a future
`global/cli-exit-codes.md` standard (not in scope here). Resolve
at design.

### Resolution

- **Resolved on**: 2026-05-10 (via `design.md` ADR-J8-003)
- **Decision**: Refusal exit code is **3** (policy violation),
  distinct from `1` (invalid input) and `2` (usage). Cross-domain
  reuse with `forge-snapshot.sh::3` (regex mismatch) acceptable —
  per-binary semantics. A future `global/cli-exit-codes.md`
  standard will lock the convention repo-wide ; out of scope here.
- **Rationale**: CI scripts can grep `exit 3` to detect policy
  refusals specifically (vs generic failures). Matches the
  "structured stderr line + structured exit code" pattern that
  Article V (audit trail) wants.
