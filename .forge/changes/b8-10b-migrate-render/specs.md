# Specs — `b8-10b-migrate-render`

**Namespace** : `FR-B810B-*`, `NFR-B810B-*`, `ADR-B810B-*`.
Consolidated target on archive : `.forge/specs/migrate-flagship.md` (or the b8-10
consolidated spec, whichever holds `FR-B810-*`).

---

## Functional Requirements

### FR-B810B-001 — no `.tmpl` file reaches the adopter

After a full migration of a rendered `full-stack-monorepo / 1.0.0` project, **zero**
files with a `.tmpl` extension exist in the target, excluding the framework's own
`.forge/templates/**` mirror (which legitimately contains templates).

Stated as an absolute over the target tree rather than over a list of 36 known
files: a future addition to the `2.0.0/` tree must inherit the guarantee without an
edit here.

### FR-B810B-002 — no unsubstituted placeholder reaches the adopter

No file written by the migration may contain `<project-name>`, `<reverse-domain>`,
`<root-module>` or `<project_name_snake>`, under the same exclusion as
FR-B810B-001.

### FR-B810B-003 — substitution values come from the adopter's manifest

The values MUST be read from the target's `.forge/scaffold-manifest.yaml`
(`project_name`, `reverse_domain`, `root_module`). The script's ABI stays
`--target`-only (NFR-B810B-002).

If the manifest is missing or lacks a required key, the migration MUST refuse with
the existing precondition exit code **7** and a message naming the missing key —
never substitute an empty string. An empty substitution produces a file that looks
rendered and is silently wrong, which is worse than the current defect because it
is invisible.

### FR-B810B-004 — no file shadows an already-rendered sibling

The migration MUST NOT create `X.tmpl` beside an existing `X`. Currently 9 do,
including `CLAUDE.md`, `README.md`, `Taskfile.yml` and `docker-compose.dev.yml` —
the four files an adopter is most likely to open first.

Once FR-B810B-001 holds, such a file is instead a merge candidate against the
existing `X` and goes through `_a7_classify` / `_a7_three_way_merge` like every
other overlapping path. That is a behavioural change and is the point: those nine
files were never merged, only dropped alongside.

### FR-B810B-005 — the harness inspects real output

`b8-10.test.sh` MUST gain a test that runs a **real** (non-dry-run) migration into a
temporary rendered project and asserts FR-B810B-001, FR-B810B-002 and FR-B810B-004
against the resulting tree.

The existing `_test_b810_l2_001_live_dry_run` stays. It is not a substitute: a
dry-run cannot observe output, which is exactly how this defect survived.

Level assignment is a design question (Q-003) — a real migration needs a rendered
1.0.0 project, which needs `flutter` and `cargo`.

### FR-B810B-006 — the stale banner is corrected

`bin/forge-migrate-flagship.sh:175` prints
`to version: 2.0.0 (scaffoldable: false until B.8.14)`. B.8.14 shipped on
2026-06-05 and `.forge/schemas/full-stack-monorepo/2.0.0.yaml:47` declares
`scaffoldable: true`. The banner MUST state the real current state.

### FR-B810B-007 — the runbook matches the delivered behaviour

`docs/MIGRATIONS.md` MUST describe what the adopter actually receives. Today `:95`
promises `no-web → Qwik web-public → frontend/web-public/` with no indication that
the surface arrives unrendered.

---

## Non-Functional Requirements

### NFR-B810B-001 — one render engine

The fix MUST NOT introduce a second implementation of placeholder substitution.
`overlay.sh` owns rendering semantics — `<project-name>`, `<reverse-domain>`,
`<root-module>`, `<project_name_snake>` — and a divergent copy in the migrate
script would drift silently.

This mirrors `ADR-B810-001`'s own governing principle for the merge engine ("no
second merge engine ... the script body contains no `git merge-file` call of its
own"), applied to rendering. How it is honoured is Q-001.

### NFR-B810B-002 — the ABI does not widen

`forge-migrate-flagship.sh` keeps `--target` as its only required flag. No
`--project-name` / `--org` may be added: every documented invocation and the
`docs/MIGRATIONS.md` runbook depend on the current shape.

### NFR-B810B-003 — idempotence survives

`docs/MIGRATIONS.md:80` states re-running produces no further changes. Re-running
the migration after this fix MUST still converge — the second run must classify the
now-rendered files as `unchanged`, not re-render and re-merge them.

This is the requirement most likely to break under a naive fix, because rendering
changes the bytes the classifier compares.

### NFR-B810B-004 — the frozen 1.0.0 base is untouched

No change to `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` or its
`.sha256`. `b8-2.test.sh` fails if it drifts.

---

## ADRs

### ADR-B810B-001 — refuse rather than substitute empty

Recorded here rather than left to implementation because the failure is silent.
A missing `project_name` in the manifest could be handled three ways: substitute
empty, leave the placeholder, or refuse. The first two produce a tree that looks
migrated. Refusing with exit 7 is the only option an adopter can act on. See
FR-B810B-003.

### ADR-B810B-002 — the nine shadowed files become merge candidates

Making `X.tmpl` render to `X` means nine files that previously landed beside an
existing file now collide with it, and therefore enter the 3-way merge. Adopters who
already ran the migration have both copies on disk.

The migration is documented as additive and idempotent; turning a silent drop into a
real merge is a behavioural change that MUST be called out in `docs/MIGRATIONS.md`
and the CHANGELOG, including what an already-migrated adopter should delete.
