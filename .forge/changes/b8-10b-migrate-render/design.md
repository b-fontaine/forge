# Design — `b8-10b-migrate-render`

## Q-001 resolved: (a) delegate to `overlay.sh` — maintainer, 2026-09-09

### ADR-B810B-003 — the merge RIGHT becomes a rendered tree, not the template tree

**Context.** `TPL_20` (`:48`) points at the raw `2.0.0/` template tree, so the
3-way merge's RIGHT side is a set of `.tmpl` files with live placeholders. Any fix
must render them without duplicating `overlay.sh`'s substitution semantics
(NFR-B810B-001).

**Decision.** Render the 2.0.0 set into a `mktemp -d` via `overlay.sh`, then run the
existing `_a7_*` merge with that rendered directory as RIGHT.

**Feasibility established by execution, not assumed** (2026-09-09):

```
$ bash .forge/scripts/scaffolder/overlay.sh --target <tmp> \
      --project-name probeapp --reverse-domain com.p.x --plan _probe-plan.yaml
exit=0 ; overlay.sh: 2 templates rendered
$ find <tmp> -type f
.forge/scaffold-manifest.yaml
frontend/web-public/package.json
frontend/web-public/README.md
$ grep -n probeapp <tmp>/frontend/web-public/README.md
3:# Qwik web-public surface for `probeapp` (2.0.0 candidate)
```

Three facts this settles:

1. **A `templates:`-only plan is accepted.** `official_scaffolders` is `init.sh`'s
   concern; `overlay.sh` does not require it. So the migration plan can list files
   and nothing else.
2. **Output is already in adopter layout.** The plan's `target:` field does the
   `2.0.0/` strip, so `_b810_map_relpath` becomes an identity function and the
   prefix-stripping logic at `:227-230` is retired rather than patched.
3. **`overlay.sh` writes `.forge/scaffold-manifest.yaml` into the temp dir.** That
   file must be excluded from the merge — the adopter's own manifest is authoritative
   and is updated separately by the existing `_a7_append_upgrade_history` path.
   Missing this would overwrite the adopter's `upgrade_history` with an empty one.

**Consequences.** One renderer, identical to fresh-init by construction rather than
by discipline. The cost is a new committed artefact — the migration plan — which is
also most of what Q-002 would need if fresh-init coverage is ever decided.

## The new artefact

`.forge/templates/archetypes/full-stack-monorepo/migration-plan-2.0.0.yaml`, listing
all 36 files of the `2.0.0/` tree with `substitute: true`.

Named `migration-plan-` rather than `scaffold-plan-` deliberately: it is not a
`forge init` input, and a third `scaffold-plan-*.yaml` in that directory would invite
exactly the confusion this session already hit once — reading a plan's existence as
proof that something invokes it.

`overlay.sh:136` resolves a bare `--plan` name under the archetype root, so the file
sits beside the two scaffold plans and is passed by name.

### Why all 36 and not the 13 already in `scaffold-plan-2.0.0.yaml`

The migration's contract (`docs/MIGRATIONS.md:95`) is that the adopter receives the
web-public surface, Zitadel and pgvector. Those are precisely the files absent from
the scaffold plan. Reusing `scaffold-plan-2.0.0.yaml` would render 13 files and
silently drop the 23 the migration exists to deliver.

## Substitution inputs

Read from the target's `.forge/scaffold-manifest.yaml`: `project_name`,
`reverse_domain`, `root_module`. Missing key ⇒ exit 7, naming the key
(FR-B810B-003 / ADR-B810B-001). The ABI stays `--target`-only.

## Idempotence (NFR-B810B-003, the requirement most at risk)

Today the second run compares `.tmpl` bytes against `.tmpl` bytes and converges
trivially. After the fix, RIGHT is rendered output, so the second run compares
rendered bytes against the files the first run wrote — which are the same bytes,
provided rendering is deterministic for a fixed manifest. `SOURCE_DATE_EPOCH` is
already honoured (`b8-10.test.sh::_test_b810_l1_012`).

The risk is the manifest itself: if `overlay.sh`'s temp-dir manifest leaked into the
merge, each run would rewrite the adopter's manifest and never converge. Excluding it
(point 3 above) is what makes idempotence hold, so the second-run test is the
real guard, not a formality.

## Verification

| Layer | Asserts | Blind to |
|---|---|---|
| L1 synthetic | a hand-built target with a manifest and two files migrates to zero `.tmpl`, zero placeholders | whether a real 1.0.0 tree behaves the same |
| L2 real | full render → migrate → assert on the actual 36-file result | runs only where flutter+cargo exist |

Both, per Q-003. An L2-only test repeats the failure that hid this defect: `b8-10`'s
only live test is env-gated, and CI's `cli` job installs neither flutter nor buf, so
gated legs do not run there.

The L1 test must be mutation-probed against the **pre-fix** script: if it passes on
today's `cp`-based implementation, it does not test what it claims.

## Ordering (TDD)

1. L1 output test in `b8-10.test.sh`. Run against the **unfixed** script → must RED,
   naming `.tmpl` files.
2. `migration-plan-2.0.0.yaml` (all 36 entries).
3. Rewrite the RIGHT-selection: render via `overlay.sh` into `mktemp -d`, exclude the
   temp manifest, retire `_b810_map_relpath`.
4. Run → GREEN. Then the second-run idempotence assertion.
5. L2 real-migration test.
6. Banner `:175`; `docs/MIGRATIONS.md`; CHANGELOG including the already-migrated
   adopter note (Q-004).
7. Regression: `b8-10`, `b8-2` (frozen snapshot), `b9-2::T-010` (`overlay.sh`
   byte-unchanged — this change must not touch it), full sweep, both gates **after**
   the status flip.
