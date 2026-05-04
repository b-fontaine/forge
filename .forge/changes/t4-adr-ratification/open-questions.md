# Open Questions — t4-adr-ratification

## Q-001: Should the linter rule `no-state-management-alternatives` be enabled at v0.4.0 or deferred to B.8?

- **Status**: answered
- **Raised in**: proposal.md (Scope In, ADR-006 ratification)
- **Raised on**: 2026-05-04
- **Raised by**: @bfontaine (drafted via session 2026-05-04)

### Question

The new `state-management.yaml` standard ships a `forbidden:` list with
`flutter_riverpod`, `riverpod`, `provider`, `get`, `getx`, `mobx`,
`flutter_mobx`, `states_rebuilder`. Two options for activation policy :

- **Option A** : ship the linter rule disabled by default (`enforcement: warn`),
  activate as `enforcement: error` when the flagship migration B.8 lands in
  T6. Pro : zero breakage for current `mobile-only / 1.0.0` adopters who
  may experiment with Riverpod. Con : the standard is "documented but
  not enforced" for ~6 months.
- **Option B** : ship the linter rule enabled at `enforcement: error` immediately
  in this change. Pro : alignment between standard and enforcement is
  immediate. Con : every existing project running `forge verify` post-upgrade
  fails if any forbidden import is present.

### Resolution

- **Resolved on**: 2026-05-04
- **Decision**: Option A — `enforcement: warn` shipped in this change ; transition to `enforcement: error` deferred to B.8 (T6).
- **Rationale**: zero breakage for v0.3.0 adopters at upgrade time. The standard is documented and discoverable via `forge verify` warnings during the T5 window, giving adopters six months to remediate before the hard gate lands with the flagship migration. Aligns with the additive-first / breaking-second migration strategy from `docs/new-archetypes-plan.md` §4.1.

## Q-002: Should `mobile-only` legacy alias resolution lazy-redirect to `mobile-pwa-first` schema in v2 or stay as a separate stub schema?

- **Status**: answered
- **Raised in**: proposal.md (Scope In, archetype.schema.json v2)
- **Raised on**: 2026-05-04
- **Raised by**: @bfontaine

### Question

`archetype.schema.json` v2 needs to accept `mobile-only` as a valid value for
backwards compatibility with `@sdd-forge/cli@0.3.0` users. Two options :

- **Option A** (alias) : v2 schema enum is `[full-stack-monorepo, mobile-pwa-first,
  event-driven-eu, ai-native-rag, rust-cli-tui, mobile-only]` and the
  scaffolder logic at `bin/forge-init-mobile-only.sh` is preserved untouched
  until T8 (B.9 ships the rename + migration script).
- **Option B** (stub) : v2 schema enum is `[full-stack-monorepo,
  mobile-pwa-first, event-driven-eu, ai-native-rag, rust-cli-tui]` strict,
  and a separate "legacy" schema enum file accepts `mobile-only`.

### Resolution

- **Resolved on**: 2026-05-04
- **Decision**: Option A — v2 enum accepts the 6 values (5 canonical + `mobile-only` legacy alias), single schema file, no separate "legacy" stub.
- **Rationale**: keeps the schema surface flat ; one file is canonical. The legacy alias gets a `description:` field in the JSON schema flagging it as deprecated and pointing to `mobile-pwa-first`. Migration via B.9 (T8) issues a deprecation warning at `forge init --archetype mobile-only` time without breaking any existing scaffold. Avoids the proliferation of "legacy v1 schema" files that becomes a maintenance debt.

## Q-003: Should ADR ratification specs include a content-hash of `docs/ARCHITECTURE-TARGET.md` to detect drift?

- **Status**: answered
- **Raised in**: proposal.md (Risk level mitigation)
- **Raised on**: 2026-05-04
- **Raised by**: @bfontaine

### Question

The 10 ADR sections in `specs.md` each cite line ranges from
`docs/ARCHITECTURE-TARGET.md`. If that document is later edited (which it
will be — at minimum the date stamp updates), the cross-references rot.
Two options :

- **Option A** : store a `sha256` content hash of `docs/ARCHITECTURE-TARGET.md`
  in `specs.md` frontmatter ; `t4.test.sh` recomputes the hash and FAILs
  if drifted. Forces a re-review at every architecture-doc edit. Pro :
  zero rot tolerance. Con : painful for trivial fixes (typos, formatting).
- **Option B** : store only the **file path + line ranges**, accept manual
  audit at re-edit time (no automated drift detector). Pro : low friction.
  Con : line ranges silently rot.

### Resolution

- **Resolved on**: 2026-05-04
- **Decision**: Option A — sha256 hash stored in `specs.md` frontmatter, `t4.test.sh` enforces the match, escape hatch script `bin/forge-rehash-architecture-doc.sh` recomputes the hash after a human-reviewed edit and updates the frontmatter.
- **Rationale**: zero-rot tolerance is preferable for a ratification artefact where drift would silently invalidate the entire change's traceability. The escape hatch (`bin/forge-rehash-architecture-doc.sh`) keeps the friction acceptable : trivial typo fixes are rehashed in one command + a CHANGELOG note. Documented as a standard pattern in `.forge/standards/global/source-document-pinning.md` (new) so future changes that ratify external documents follow the same convention.
