# Specs — `b9-9-migrate-mobile-pwa`

**Namespace** : `FR-B99-*`, `NFR-B99-*`, `ADR-B99-*`.

---

## Functional Requirements

### FR-B99-001 — the script exists with the sibling ABI

`bin/forge-migrate-mobile-pwa.sh --target <dir> [--dry-run] [--force]`, executable,
`set -euo pipefail`, exit envelope **0 / 2 / 5 / 7 / 8** matching
`forge-migrate-flagship.sh`.

### FR-B99-002 — it refuses anything that is not a mobile-only install

Preflight MUST exit **7**, naming what is wrong, when the target: has no
`pubspec.yaml`; has no `android/app/build.gradle.kts` to derive the domain from; or
already carries `web-pwa/`.

The last is the interesting one — a target that already has the surface is not a
migration candidate, and silently proceeding would be the "clobber the adopter's
work" failure this repo has already paid for once.

### FR-B99-003 — substitution values are derived from the project

`project_name` from `pubspec.yaml`'s `name:`; `reverse_domain` from
`android/app/build.gradle.kts`'s `namespace`. A `mobile-only` install has **no**
`scaffold-manifest.yaml`, so there is nothing to read them from.

If either cannot be derived, exit **7** naming which — never substitute an empty
string (the `b8-10b` ADR-B810B-001 precedent: an empty substitution produces a file
that looks rendered and is silently wrong).

### FR-B99-004 — rendered, never copied

The 25 additive entries MUST be produced through `overlay.sh`. No `.tmpl` file and no
unsubstituted `<project-name>` / `<reverse-domain>` may reach the target.

### FR-B99-005 — additive only, verified against the source tree

After a migration, every file that existed before MUST be byte-identical. Asserted by
hashing the target's tree before and after and comparing, not by inspecting the
script.

### FR-B99-006 — the additive set is derived, not duplicated

The entries come from the archetype's own `scaffold-plan.yaml`, filtered to
`target` under `web-pwa/` plus the two root additions. A second hand-maintained list
would drift — the reason `b8-10b` needed a coverage guard.

A test MUST assert the filter yields exactly the 25 entries, and that the archetype
plan has no other `web-pwa/` target.

### FR-B99-007 — collision refusal

If any file the migration would write already exists, exit **8** listing them, unless
`--force`. `--dry-run` prints the plan and writes nothing.

### FR-B99-008 — the migrated project gets a manifest

`.forge/scaffold-manifest.yaml` recording `archetype: mobile-pwa-first`,
`archetype_version: 2.0.0` and the derived values — so a subsequent `forge upgrade`
has the metadata a `mobile-only` install never had.

### FR-B99-009 — CHANGELOG + harness registration

---

## Non-Functional Requirements

### NFR-B99-001 — the native tree is untouched

No file under `lib/`, `ios/`, `android/`, `test/`, nor `pubspec.yaml`, may change.
This is FR-B99-005 stated as the property that matters to an adopter.

### NFR-B99-002 — no new dependency

`bash`, `python3`, `git` only — the sibling scripts' floor.

### NFR-B99-003 — idempotence is refusal, not convergence

Re-running MUST exit 8 (or 7 for the `web-pwa/` preflight), not silently re-render.
An additive migration that runs twice has nothing to converge to; the honest
behaviour is to stop.

---

## ADRs

### ADR-B99-001 — no 3-way merge engine

**Context.** `forge-migrate-flagship.sh` sources `forge-upgrade.sh`'s `_a7_*` library.
The obvious move is to mirror it.

**Decision.** Additive copy with collision refusal; no merge engine.

**Rationale.** Measured: the migration adds 26 files and modifies **zero**
(`ADR-B9-1-004` predicted it; the diff confirms it). A merge engine would exist for a
case that cannot arise on a pristine install. On a diverged one — the adopter wrote
their own `web-pwa/` — merging framework templates into their work is worse than
refusing and letting them decide.

**Consequence.** No `.merge-conflicts` ledger, no BASE extraction, so the frozen
`mobile-only/1.0.0` snapshot is not read by this script. It remains the reverse target
for `forge upgrade`, which is what B.9.8 froze it for.

### ADR-B99-002 — derive from the project, do not widen the ABI

`--target` stays the only required flag, matching the sibling. The values come from
`pubspec.yaml` and `build.gradle.kts` rather than from flags or a manifest.

Beyond consistency: a derived value tracks the adopter. If they changed their
`applicationId` after scaffolding, a stored manifest value would be stale and a flag
would be a chance to typo it; the Gradle file is what their build actually uses.
