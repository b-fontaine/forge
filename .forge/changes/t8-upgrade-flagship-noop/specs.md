# Specs — `t8-upgrade-flagship-noop`

**Namespace** : `FR-T8UFN-*`, `NFR-T8UFN-*`, `ADR-T8UFN-*`.

FR-T8UFN-001 to -005 are the brick as proposed. FR-T8UFN-006 to -009 come from its
independent review (evidence P-8): they fix defects the review found on the same driver
path, three of them present before this brick.

---

## Functional Requirements

### FR-T8UFN-001 — a copied framework declaration is not an archetype declaration

Archetype mode MUST be entered only when the scaffold plan selected for the project's
`archetype_version` renders `.forge/framework-owned-paths.yml` itself, meaning one of its
`templates:` entries has that `target:`. A project whose file is a copy of the framework's
root declaration MUST keep the framework path. This holds whether the copy is exact, came
from an older framework, or was edited by the adopter. It is the case for every flagship
render (`init.sh:208`) in both 1.0.0 and 2.0.0.

A plan that cannot be parsed MUST be reported on stderr; the project then keeps the
framework path. A plan that parses but does not render the declaration (the flagship) is
not an error and stays silent.

### FR-T8UFN-002 — the flagship's upgrade is not a silent no-op

On a fresh `full-stack-monorepo` 2.0.0 render, `forge upgrade` MUST NOT report skipped
paths. The expected result is the one the pre-`473cd36` driver gave on the same tree:
framework mode, 548 unchanged, 8 conflicts, exit 8. Per FR-T8UFN-008, the manifest is NOT
updated. The 8 conflicts are a defect (Q-005), but a visible one.

### FR-T8UFN-003 — RIGHT reproduces the wrapper's path relocation

A `{{reverse_domain_path}}` directory under `android/app/src/main/kotlin/` in the render
MUST be relocated to the reverse domain's path, as `bin/forge-init-mobile-pwa-first.sh`
step 3 does. The reverse domain is validated first, in ASCII, and nothing is created or
moved when it is refused. No path in a rendered RIGHT or BASE may keep a `{{…}}`
placeholder in its name. No plan may place a placeholder anywhere else in a `target:`
path. On a fresh `mobile-pwa-first` render the upgrade MUST report `files skipped: 0`, with
`PlayIntegrityService.kt` among the paths it compares.

### FR-T8UFN-004 — a declared path the render cannot produce is reported

In archetype mode, stderr MUST report how many of the paths resolved from the project's
declaration are absent from the rendered RIGHT, in a real run as well as a dry one and
outside `--verbose`. With `--verbose` exactly those paths are listed, shell-escaped
(`%q`), because they are the target's own file names. The upgrade is **not** refused for
them (ADR-T8UFN-003).

### FR-T8UFN-005 — the records this falsifies are corrected

Plan §0.19 and FR-T8UAS-001 ("the flagship keeps the old behaviour"), the rationale of
ADR-T8UAS-001, the diagnosis in `t8-upgrade-archetype-surface` Q-002, and the CHANGELOG
entry for that brick MUST be corrected where they are stated.

### FR-T8UFN-006 — `archetype_version` must be SemVer before it becomes a path

`archetype_version` comes from the target's manifest and goes into the plan path
(`scaffold-plan-<version>.yaml`) and into the snapshot path (`<version>.tar.gz`).
`_a7_check_version_compat` compares only the first dot-field, so `2.0.0.d/../../x` got
through. A version that is not SemVer (ASCII, `X.Y.Z[-pre][+build]`) MUST make the
upgrade refuse with exit 2 and name the field. The plan-selection helper MUST refuse it as
well.

### FR-T8UFN-007 — an invalid archetype name never reaches the snapshot path

`ee9a745` gated `archetype` in archetype mode only. A name that gate refused dropped back
to framework mode, and there the RAW value was still joined into
`.forge/scaffold-snapshots/<archetype>/<version>.tar.gz` and handed to `tar`. A tarball
planted at the end of that path became BASE. The same name gate MUST apply before the
snapshot path is built, and a refused name means no snapshot BASE is read.

### FR-T8UFN-008 — a conflicted run does not update the manifest (FR-UP-007)

FR-UP-007 lets the manifest record only a successful run: exit 0, or 8 with `--force`. A
real run that ends with conflicts and without `--force` MUST leave `archetype_version`,
`template_set_sha` and `upgrade_history` untouched, and MUST say so on stderr.

### FR-T8UFN-009 — an upgrade leaves no temporary tree behind

Every temporary tree created by `_a7_main` (the extracted snapshot, the rendered RIGHT,
the rendered BASE) MUST be removed when it exits.

---

## Non-Functional Requirements

### NFR-T8UFN-001 — no forge-ci.yml line

The new cells go into `a7.test.sh`, which CI already runs.

### NFR-T8UFN-002 — the other archetypes are untouched, measured

`ai-native-rag`, `event-driven-eu` and `default` MUST give the same counts and the same
exit codes before and after this change on a fresh render. For the first two, a real
conflicted run no longer stamps the manifest; that change is FR-T8UFN-008, required by
FR-UP-007.

### NFR-T8UFN-003 — guards mutation-proven

Every cell that tests a behaviour change MUST be RED against the driver it replaces
before it goes GREEN. The two guard cells that pin existing behaviour
(`test_archetype_plan_selection_is_versioned` for its selection half,
`test_every_plan_placeholder_path_is_relocated`) have no RED to show. They MUST instead be
shown to fail under a mutation. Every probe names the defect it catches.

---

## ADRs

### ADR-T8UFN-001 — the plan must render the declaration; supersedes ADR-T8UAS-001's rationale

**Context.** ADR-T8UAS-001 chose "the archetype has a plan and the project has the file".
Its rationale assumed only `default` carries a copy of the framework's declaration. Every
flagship render carries one too, and the flagship has a plan.

**Decision.** Keep both conditions and add a third: the plan that `_a7_render_archetype`
would select for this project has a `templates:` entry whose `target:` is
`.forge/framework-owned-paths.yml`. That plan is `scaffold-plan-<version>.yaml`, else
`scaffold-plan.yaml`, through the shared helper `_a7_archetype_plan`.

**Alternatives rejected.**
- *Compare the project's file with the framework's root file.* This breaks as soon as the
  root file changes, or the adopter edits their copy: the flagship falls back into
  archetype mode. `test_copied_framework_declaration_is_not_archetype_mode` fails under
  exactly that implementation (evidence P-9).
- *Render first, then check whether RIGHT contains the declaration.* The meaning is the
  same, but detection would then happen inside `_a7_main`, after an expensive render, and
  `_a7_project_archetype` could no longer be unit-tested.
- *The ADR-014 union.* ADR-014 says the project file should hold "the union" of the
  framework's paths and the archetype's. That is the designed end state. But it also
  changes `mobile-pwa-first`'s surface, and giving the other archetypes a declaration is
  Q-005 of `t8-upgrade-archetype-surface`. The decision here follows ADR-014's intent
  (the declaration comes from the archetype's template) without its union.

**Consequence.** A project enters archetype mode because its template ships a declaration,
not because some file happens to sit at that path. The flagship returns to framework mode.

### ADR-T8UFN-002 — reproduce the wrapper's relocation exactly, not a generalisation of it

**Decision.** `_a7_relocate_kotlin_package` performs the wrapper's relocation, at the same
place: `android/app/src/main/kotlin/{{reverse_domain_path}}` becomes the reverse domain
with `.` replaced by `/`. The reverse domain is first checked against overlay.sh's pattern
in Python with `re.ASCII`. Under a UTF-8 locale, a bash `[[ =~ ]]` range accepts `é` or
`ß`, which made the outcome depend on `LC_ALL`.

**Rationale.** RIGHT is only correct if it matches what the wrapper produced. A broader
rule would relocate directories the wrapper leaves alone, and RIGHT would then diverge the
other way. `test_every_plan_placeholder_path_is_relocated` checks **every** scaffold plan,
not just `mobile-pwa-first`'s, and fails if a `target:` puts a placeholder anywhere except
that directory. A future template that does so fails this cell instead of being skipped in
silence on every upgrade.

### ADR-T8UFN-003 — report an unproducible path, do not refuse on it

**Context.** A declared path can be present in the project and absent from the render for
three reasons: the render is unfaithful (a defect, as here), the framework stopped
shipping the file, or a glob matched a file the adopter created.

**Decision.** Always report the count on stderr, in dry and real runs alike. List the paths
under `--verbose`, escaped. Then carry on. The existing guard still refuses when the
surface hashes nothing (FR-T8UAS-009).

**Rationale.** The second and third cases are legitimate; refusing on them would block
valid upgrades. The failure these records measured was not that the run continued. It was
that 548 paths disappeared into a counter nobody reads. A ratio threshold would be
arbitrary, and FR-T8UFN-001 removes the cause that threshold would be guessing at.
