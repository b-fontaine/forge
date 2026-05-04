# Source-document pinning

> **Audit**: T.4 (t4-adr-ratification, FR-T4-DOC-002). Codifies the convention
> introduced by Q-003 of `t4-adr-ratification` to detect drift in external
> source documents that a Forge change ratifies.

## Purpose

Some Forge changes ratify decisions taken in **external source documents**
(architecture audits, RFCs, post-mortems) rather than originating the
decisions themselves. The classic example is `t4-adr-ratification` which
ratifies the 10 ADRs of `docs/ARCHITECTURE-TARGET.md`.

When a Forge change cites such a document by **line range**, those line
ranges silently rot the moment the document is edited (typo fix, formatting,
date stamp update). To prevent silent rot, Forge requires that every
source-ratifying change pins the document via a **sha256 hash** in its
`specs.md` Source Document table, with a deterministic drift gate.

## Convention

A change MUST follow this convention iff it ratifies decisions taken in
a markdown document under `docs/`. Specifically :

1. **Source Document table** in `specs.md` opens the file with :

   ```markdown
   ## Source Document

   | Field          | Value                                                              |
   |----------------|--------------------------------------------------------------------|
   | **Path**       | `docs/<doc>.md`                                                    |
   | **Line count** | <integer>                                                          |
   | **sha256**     | `<64-char hex>`                                                    |
   | **Last verified** | <ISO-8601>                                                      |
   | **Drift gate** | `<harness>::<test_name>`                                           |
   | **Rehash escape hatch** | `bin/forge-rehash-<doc-slug>.sh`                          |
   ```

2. **Drift gate** : the change's harness includes a test that recomputes
   `shasum -a 256 <doc>` and FAILs if the result differs from the pinned
   value. For `t4-adr-ratification`, the gate is
   `t4.test.sh::_test_t4_023`.

3. **Rehash escape hatch** : a script `bin/forge-rehash-<doc-slug>.sh`
   that :
   - Recomputes the sha256.
   - Updates the `| **sha256** | ... |` line in `specs.md`.
   - Appends a dated entry to `REHASH-LOG.md` (in the change directory)
     documenting **when**, **by whom**, and **old/new hashes**.
   - Prints old + new hashes for audit.
   - Supports `--dry-run` for inspection without mutation.

4. **Reviewer attestation** : when running the rehash script, the
   maintainer attests that the edit did NOT materially change any
   ratified Decision / Context / Consequences block. Material edits
   require a fresh Forge change that supersedes parts of the original
   ratification.

## When this convention applies

| Type of change                                                           | Apply convention ? |
|--------------------------------------------------------------------------|--------------------|
| Ratifies an architecture audit (e.g. ARCHITECTURE-TARGET.md)             | YES                |
| Ratifies a post-mortem report                                            | YES                |
| Ratifies an external standard (cited verbatim in specs)                  | YES                |
| Implements a feature with original specs (no source document)            | NO                 |
| Refactors code without specs change                                      | NO                 |
| Updates a Forge-internal standard YAML                                   | NO (governed by `standards-lifecycle.md` instead) |

## Non-goals

- This convention is **not** a general-purpose document-tracking system.
  Its scope is bounded to changes that **ratify external decisions**.
- It does not version the source document — the document is single-version
  per change. Subsequent material changes to the document spawn new Forge
  changes.
- It does not replace `forge upgrade` 3-way merge for adopters. Source
  documents under `docs/` participate in `forge upgrade` like any other
  framework-owned path declared in `framework-owned-paths.yml`.

## Open questions

None at ratification time. If a future change introduces a multi-document
ratification (e.g. ratifies both an audit and a roadmap), this convention
will need extension — at which point a new Forge change must amend this
standard.
