# Open questions — `t8-example-tree-pins`

## Q-001: No guard checks that an example still matches the template it was rendered from

- **Status**: open
- **Raised in**: `design.md § "What stays out, and why"`
- **Raised on**: 2026-09-16
- **Raised by**: @bfontaine

### Question

This brick closes the *pin* half: `b8-9::T-013`/`T-014` now hold every example manifest
and its README pin table to `web-frontend.yaml`. Nothing holds the other ~50 files.

`.forge/specs/example-reference.md` NFR-EX-001 already specifies the missing check —
re-render from the plan with `SOURCE_DATE_EPOCH` pinned and compare — and marks it "L3
opt-in via `--require-external-tools`", a flag `forge-ci` never passes. So the
specification exists, the harness hook exists, and the assertion has never run.

That is how `connect-client.ts` (Q-006 of `t7-qwik-deps-refresh`) sits byte-identical and
broken in both template and example: no parity guard, and the pin guard does not look at
source files.

## Q-002: The example's `scaffold-manifest.yaml` records a `template_set_sha` nothing verifies

- **Status**: open
- **Raised in**: `evidence.md § P-1`
- **Raised on**: 2026-09-16
- **Raised by**: @bfontaine

### Question

`examples/forge-rag-example/.forge/scaffold-manifest.yaml:8` carries
`template_set_sha: 711bd87f0428…` and `scaffold_date: 2026-06-23`. The template set has
moved since (this brick moved it again). No harness recomputes or compares it, so the
field records a provenance that is already false and cannot fail.

Either it becomes a checked claim — which requires deciding what the sha covers and
re-stamping it on every template change that reaches an example — or it should be
documented as a birth record, not a live one. Not decided here.

## Q-003: Unsubstituted `<project-name>` placeholders ship inside rendered example files

- **Status**: open
- **Raised in**: `evidence.md § P-1`
- **Raised on**: 2026-09-16
- **Raised by**: @bfontaine

### Question

Found while sweeping for drift, verified on three files:

```
examples/forge-fsm-example/infra/k8s/base/README.md:1  # Kubernetes manifests for `<project-name>`
examples/forge-rag-example/shared/protos/buf.yaml      # Buf module configuration for <project-name>'s proto contracts.
examples/forge-rag-example/shared/protos/buf.gen.yaml  # same class, found with the whole-tree render (see evidence P-1)
```

Both trees ship in the npm tarball. Care is needed before sweeping: many `<project-name>`
hits under `examples/` are legitimate — the example trees carry their own
`.forge/templates/` copy, and `examples/forge-rag-example/README.md:34` mentions the
placeholders while documenting the reproduction recipe. Only occurrences in *rendered*
files are defects.

A render-parity guard (Q-001) would catch this class; a placeholder-leak grep scoped to
rendered paths would catch it cheaply on its own.

## Q-004: `forge-fsm-example` drifts from a 1.0.0 render on more than the pins

- **Status**: open
- **Raised in**: `proposal.md § Scope`
- **Raised on**: 2026-09-16
- **Raised by**: @bfontaine

### Question

Reported by the investigation lane, not re-measured here: roughly ten of its rendered
files differ from an overlay render of `full-stack-monorepo` 1.0.0. Some drift is
expected (the example predates the 2.0.0 brick and carries hand-written navigation), but
it has never been adjudicated into an allowed-drift list. Blocks Q-001's parity guard
from covering that tree until someone decides which differences are intentional.

## Q-005: The examples rules are strict by design, and a future example may argue with them

- **Status**: open
- **Raised in**: `evidence.md § P-9`
- **Raised on**: 2026-09-22
- **Raised by**: @bfontaine

### Question

Review round 2 made two cases fatal under `examples/`: a manifest that mentions Qwik
without declaring it, and a checked surface whose sibling README exposes no pin table.
Both are deliberate — a silent skip is what let the shipped render drift twice — but both
are strict:

- an npm-workspaces root that legitimately hoists the pins would fail the first rule until
  someone decides how a hoisted example declares its surfaces;
- an example rendered from a template whose README has no pin table (`mobile-pwa-first`'s
  `web-pwa` is one today) would fail the second.

Neither shape exists in the repository now. Recorded so that whoever meets one reads this
instead of loosening the guard by reflex — ADR-T8ETP-001's consequence is that such a case
is argued about, not silenced.

## Q-006: `bin/forge-questions.sh` silently reports nothing across the whole repository

- **Status**: open
- **Raised in**: `evidence.md § P-10`
- **Raised on**: 2026-09-22
- **Raised by**: @bfontaine

### Question

`bash bin/forge-questions.sh` — the F.1 discovery tool, whose whole purpose is to surface
undecided items — prints **zero lines** on this repository, while dozens of real open
questions exist.

Its awk parser requires `^## Q-NNN: ` (colon) plus `- **Raised on**:` and
`- **Raised by**:`, exactly as `global/open-questions.md § Question Schema` prescribes.
Almost every `open-questions.md` in `.forge/changes/` uses `## Q-NNN — title` (em dash)
and omits the two `Raised` fields, so every one of them is invisible to the tool.

This brick's own file was reformatted to the schema so it is at least discoverable, which
is why the tool now returns something. Converting the rest is a separate brick, and the
real fix is a guard: `verify.sh`'s Open Questions Gate counts `Status: open` but never
checks that a question is *parseable*, so a file the tool cannot read passes today.
