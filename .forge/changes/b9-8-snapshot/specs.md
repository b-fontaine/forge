# Specs — `b9-8-snapshot`

**Namespace** : `FR-B98-*`, `NFR-B98-*`, `ADR-B98-*`.

---

## Functional Requirements

### FR-B98-001 — the mobile-pwa-first 2.0.0 snapshot exists

`.forge/scaffold-snapshots/mobile-pwa-first/2.0.0.tar.gz` MUST exist, be a valid
gzip tarball, and be produced by `forge-snapshot.sh build mobile-pwa-first 2.0.0`
— not by hand, so it inherits the script's determinism guarantees
(ADR-B8-OBI-011).

### FR-B98-002 — every snapshot this brick touches has a `.sha256`

Both `mobile-pwa-first/2.0.0` and `mobile-only/1.0.0` MUST carry a committed
sibling `<version>.sha256`. `upgrade-policy.md:189` requires it; `forge-snapshot.sh`
emits none, so this brick writes them.

### FR-B98-003 — the repack removes AppleDouble and nothing else

After repacking `mobile-only/1.0.0.tar.gz`:

- zero members matching `._*` (298 before)
- zero `LIBARCHIVE.xattr.com.apple.*` extended headers
- the **219 real files are byte-identical** to the pre-repack archive, proven by
  extracting both and comparing every file — not by trusting the tool

### FR-B98-004 — a drift harness on both frozen tarballs

A test MUST fail if either tarball's sha256 stops matching its committed manifest.
This is the guarantee the freeze exists to give, and the flagship has had it since
B.8.2 (`b8-2.test.sh`); `mobile-only` never did.

### FR-B98-005 — the freeze is recorded where the policy expects it

`upgrade-policy.md` documents the flagship freeze (B.8.2, 2026-05-30). The
`mobile-only/1.0.0` freeze MUST be recorded alongside it, closing ADR-B8-2-004's
forward pointer.

### FR-B98-006 — CHANGELOG entry

Including the fact that BASE recovery for `mobile-only` adopters stops restoring
298 macOS files.

---

## Non-Functional Requirements

### NFR-B98-001 — the flagship freeze is untouched

`full-stack-monorepo/1.0.0.tar.gz` and its `.sha256` must not change.
`b8-2.test.sh` fails if they drift — that harness staying green is the check.

### NFR-B98-002 — era state is preserved

The repacked `mobile-only/1.0.0` must still contain the 50 files that differ from
today's tree. A repack that "helpfully" refreshed them would destroy the merge
BASE, which is the whole reason a rebuild was rejected.

### NFR-B98-003 — determinism

The repack must be reproducible: running it twice on the same input yields
identical bytes. Otherwise the `.sha256` pins an accident.

---

## ADRs

### ADR-B98-001 — repack, never rebuild

**Context.** `mobile-only/1.0.0.tar.gz` is half AppleDouble litter and has no
manifest. The obvious move is `forge-snapshot.sh build`.

**Decision.** Surgical repack: drop `._*` members and Apple xattr headers, keep
every real member byte-identical.

**Rationale, measured not assumed.** 50 of the 219 real files differ from today's
tree. A rebuild would capture 2026-09 framework state under a `1.0.0` label, so
`forge upgrade` would three-way-merge against a baseline no adopter ever had. The
litter is cosmetic; a wrong BASE is not.

**Consequence.** The archive changes bytes exactly once, before it is frozen —
which `upgrade-policy.md` permits only because it is not yet frozen. After this
brick, it is immutable.

### ADR-B98-002 — the snapshot is a framework capture, and the docs should say so

`<archetype>/<version>` reads as "a snapshot of that archetype at that version".
It is not: `forge-snapshot.sh` resolves `framework-owned-paths.yml` and never looks
at an archetype. Two snapshots taken minutes apart under different archetype labels
are near-identical, and `ai-native-rag/1.0.0.tar.gz` demonstrably contains
`.forge/schemas/full-stack-monorepo/2.0.0.yaml`.

This misreading cost real time in this session — it produced the belief that a
2.0.0 snapshot was blocked on a render path. The freeze note added by FR-B98-005
states what the archive actually holds.
