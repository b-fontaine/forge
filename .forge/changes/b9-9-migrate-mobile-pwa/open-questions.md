# Open questions — `b9-9-migrate-mobile-pwa`

## Q-001 — the migrated project targets a schema that is still `candidate`

`mobile-pwa-first / 2.0.0` is `stage: candidate` / `scaffoldable: false` until B.9.11.
So this script writes `archetype_version: 2.0.0` into a manifest for a schema that
`forge init` still refuses to scaffold, and `forge upgrade` would resolve against.

Not a defect of this brick — the migration is what B.9.11 will promote — but it means
the script should not be advertised to adopters before the promotion lands. The
Phase-0 banner says `(candidate; the schema gate is B.9.11)` so anyone running it
sees that.

## Q-002 — the manifest's `scaffold_plan_sha` is the filtered plan's

A migrated project's manifest records the hash of the 25-entry migration plan, not the
73-entry archetype plan a fresh `forge init` would record. That is accurate — it
records what was rendered — but it means the two manifests are not comparable by that
field, and any future drift check keyed on it must know which path produced the tree.

## Q-003 — derivation reads two files, and trusts their format

`sed` on `pubspec.yaml`'s `name:` and on `build.gradle.kts`'s `namespace = "..."`.
Both hold for anything the mobile-only scaffolder produced, and an adopter who
reformatted either gets a clean exit 7 rather than a wrong substitution.

What is *not* covered: an adopter whose Gradle sets `namespace` via a variable rather
than a literal. They would see exit 7 with a message naming the file, which is
actionable, but the script cannot migrate them without a flag it deliberately does not
have (ADR-B99-002). If that shape shows up in practice, the answer is probably to read
`applicationId` as a fallback rather than to widen the ABI.
