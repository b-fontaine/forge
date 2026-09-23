# Specs — `t8-upgrade-archetype-surface`

**Namespace** : `FR-T8UAS-*`, `NFR-T8UAS-*`, `ADR-T8UAS-*`.

---

## Functional Requirements

### FR-T8UAS-001 — an untouched archetype project upgrades cleanly

`forge upgrade` against a freshly rendered, unmodified archetype project MUST report zero
conflicts and exit 0. Today it reports 49 conflicts and exits 8 on a `mobile-pwa-first`
render.

### FR-T8UAS-002 — the project's declaration is what is merged

In archetype mode the owned set comes from `<target>/.forge/framework-owned-paths.yml`
(its `owned:` minus its `excluded:`), not from the framework's root manifest. A project
that declares `pubspec.yaml` and `web-pwa/package.json` MUST see those paths considered.

### FR-T8UAS-003 — RIGHT is rendered, never copied raw

RIGHT for an archetype path MUST be produced by rendering that archetype's current
template through `overlay.sh` with the project's own `project_name` / `reverse_domain` /
`root_module`. A raw `.tmpl` MUST NOT reach the target — the defect `b8-10b` fixed in the
migration driver, which shipped 36 `.tmpl` files with 24 unsubstituted placeholders.

### FR-T8UAS-004 — BASE is rendered from the snapshot when one exists

BASE MUST be rendered from the snapshot tarball's template tree for the project's
`from` version, so a file the adopter never touched classifies `upgraded` when the
framework moves it. With no snapshot, the documented 2-way fallback (FR-UP-003) applies
and an unchanged file still classifies `unchanged` because LEFT equals RIGHT.

### FR-T8UAS-005 — the framework's own paths stay out of an archetype project

In archetype mode the framework's root owned list MUST NOT be merged. `.claude/agents/*`,
`.forge/templates/**` and the rest belong to a Forge checkout, not to a rendered project.

### FR-T8UAS-006 — framework-shaped projects are unaffected

A project whose manifest names no archetype with a scaffold plan keeps today's behaviour
exactly. `a7.test.sh`'s existing cells MUST stay green unchanged.

### FR-T8UAS-007 — the rendered manifest never enters the merge

The render writes its own `.forge/scaffold-manifest.yaml`; it MUST be discarded before
comparison. Measured by `b8-10b`: without that, a target carrying an `upgrade_history`
loses it, and the clobber is near-invisible because the rendered manifest repeats the
same identity fields.

### FR-T8UAS-008 — the false claim is retracted

`t7-flutter-deps-refresh`'s "the bump now reaches existing projects" and "`pubspec.yaml`
… now framework-owned" are corrected where they are stated, and `t7-qwik-deps-refresh`
Q-007 is answered with the five mandated fields.

---

## Non-Functional Requirements

### NFR-T8UAS-001 — a failed render degrades, never destroys

If the archetype render fails, the upgrade MUST fall back to the existing framework-path
behaviour and say so — never proceed with an empty owned list, which would silently
report a clean upgrade having merged nothing.

### NFR-T8UAS-002 — no forge-ci.yml line

New cells live in `a7.test.sh`, already registered.

### NFR-T8UAS-003 — guards mutation-proven

Every new assertion RED before GREEN, each probe naming what it caught.

---

## ADRs

### ADR-T8UAS-001 — branch on "does this archetype have a plan", not on a project flag

**Context.** The driver must tell a framework-shaped project from a rendered one.

**Decision.** Archetype mode iff the manifest's `archetype` names a directory under
`.forge/templates/archetypes/` that has a `scaffold-plan*.yaml`, and the project ships
its own `.forge/framework-owned-paths.yml`.

**Rationale.** Both `default` and an archetype project carry a `.forge/` directory and an
owned-paths file, so the file's presence alone cannot discriminate — a default init copies
the framework's. The scaffold plan is what makes a render reproducible, and it is exactly
what archetype mode needs in order to produce RIGHT. `mobile-only` has a template dir but
no plan, and renders no manifest at all, so it never reaches this branch.

**Consequence.** An archetype that gains a plan later gains archetype mode with no edit
here. One that never has one keeps the framework path, which is what it has always had.

### ADR-T8UAS-002 — render BASE from the snapshot rather than trust the tarball layout

**Context.** BASE could be read straight out of the snapshot at `$base/$rel`.

**Decision.** Render it, through the same `overlay.sh` call used for RIGHT, against the
snapshot's extracted template tree.

**Rationale.** The snapshot is framework-shaped: it stores
`.forge/templates/archetypes/<a>/<v>/pubspec.yaml.tmpl`, not `pubspec.yaml`. Looking up an
adopter-layout path inside it silently finds nothing and degrades every file to a 2-way
conflict — the defect `forge-migrate-flagship` still has, where 1 of 36 paths resolves.
Rendering maps template layout to project layout the one way the project was built.

**Consequence.** BASE costs a second render. It buys the difference between "here are
your ten conflicts" and "ten files upgraded", which is the whole point of owning a path.
