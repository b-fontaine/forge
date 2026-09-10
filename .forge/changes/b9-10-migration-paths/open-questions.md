# Open questions — `b9-10-migration-paths`

## Q-001 — `web-pwa/` is outside `framework-owned-paths.yml`, for every project

`mobile-pwa-first / 2.0.0` ships a `framework-owned-paths.yml` that is **byte-identical**
to `mobile-only`'s (`sha256 a9a7921ea57e14c213661efd310dcb38b711b5db4355d7e189a5ba5007edf22a`)
and contains zero occurrences of `web-pwa`. So `forge upgrade`'s 3-way merge never
carries a framework-side improvement to the Qwik surface into an adopter project.

Not a migration defect — a migrated tree is byte-identical to a native render, so it
inherits exactly the native behaviour. It is an **archetype** gap that predates B.9.9
and B.9.10 alike.

Documented in the new section rather than patched: widening framework ownership changes
what every future `forge upgrade` writes into adopter projects, which needs a RED-first
brick of its own and has a snapshot consequence. A doc brick that edits a scaffolded
template is a doc brick that shipped an unreviewed behavioural change.

**Where it belongs:** B.9.11 already has to touch this archetype for the promotion
flip. Whether to widen ownership at the same time is a maintainer call — owning the
subtree means adopters get framework fixes and lose their edits to those files.

## Q-002 — the T.5 section sits in the wrong document by this brick's own boundary

`ADR-B910-002` says same-archetype version-to-version belongs in `MIGRATIONS.md`. The
T.5 Connect-codegen additive is same-archetype and lives here.

It is **not** moved. `constitution-linter.sh:1196` emits a live
`transport-codegen-coverage` WARN pointing adopters at this file, and `NFR-B910-004`
froze the section for that reason. The index table's `kind` column records the anomaly
in the open rather than hiding it behind a footnote.

Resolving it properly means moving the section *and* repointing the linter *and*
checking no adopter-facing text still cites the old location — a small change with
three coupled edits, which is a brick, not a paragraph.

## Q-003 — `T-028` pins the document to a statement B.9.11 will falsify

The battery requires the section to contain `candidate` and `B.9.11`, because today a
reader must be told that `forge init --archetype mobile-pwa-first` refuses while this
script succeeds.

After B.9.11 promotes the schema to `stable`, that paragraph becomes **wrong**, and
`T-028` will keep passing — it asserts presence, not truth. The guard cannot detect
its own obsolescence.

So B.9.11 must, in the same change: rewrite the **Status** paragraph of the B.9 section,
and drop the `candidate` / `B.9.11` rows from `T-028`'s needle battery (adjusting the
anti-vacuity count from 11). Recorded here because the promotion brick's own checklist
does not yet mention this document.
