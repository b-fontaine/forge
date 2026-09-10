# Proposal — `b9-8-snapshot`

Two deliverables, one of which the plan does not mention.

## 1. The snapshot the plan asks for

`.forge/scaffold-snapshots/mobile-pwa-first/2.0.0.tar.gz`, built by
`forge-snapshot.sh build mobile-pwa-first 2.0.0`, plus the sibling `.sha256`
manifest `upgrade-policy.md` requires.

**A snapshot is not a render.** Worth stating up front because the name misleads:
`forge-snapshot.sh` tars the *framework's own owned paths*
(`.forge/framework-owned-paths.yml` — `.forge/standards/**`, `.claude/agents/**`,
`docs/GUIDE.md`, …), to serve as the BASE side of `forge upgrade`'s 3-way merge.
It renders nothing and reads no archetype template. The `<archetype>/<version>`
path is a **label** recording *when* the capture was taken, which is why
`ai-native-rag/1.0.0.tar.gz` already contains
`.forge/schemas/full-stack-monorepo/2.0.0.yaml`.

So the render-path questions that surrounded B.9.8 never applied to it.

## 2. The freeze the plan forgot, which an ADR already assigned here

`.forge/specs/b8-legacy-snapshot.md:37` — **ADR-B8-2-004**: *"flagship-only;
`mobile-only/1.0.0` freeze is B.9."* B.8.2 froze the flagship and explicitly
deferred this one. It has been open since 2026-05-30.

Its current state:

| | |
|---|---|
| `.sha256` manifest | **absent** — so it has never been formally frozen |
| total entries | 598 |
| of those, macOS AppleDouble `._*` | **298** |
| extended headers | `LIBARCHIVE.xattr.com.apple.provenance` throughout |

Half the archive is macOS resource-fork litter, built with BSD tar before the
determinism patch (ADR-B8-OBI-011, 2026-05-29). BASE recovery would restore
`./._LICENSE`, `./._.mcp.json` and 296 others into an adopter's project.

`b4.test.sh:257-264` is the only consumer: it asserts existence, size, and that
`file -b` says gzip/tar. It does **not** pin the bytes.

### Rebuilding it is not an option, and that had to be measured

`forge-snapshot.sh build` captures the framework **as of today**. Extracted the
snapshot and compared its 219 real files against the current tree:

```
  identical to today : 169
  DIFFERENT from today:  50
  no longer exist    :   0
```

50 files carry era state. Rebuilding would silently replace them with 2026-09
versions, which is precisely the wrong thing for a merge BASE — it would make
`forge upgrade` compute diffs against a baseline the adopter never had.

### So: surgical repack, then freeze (maintainer, 2026-09-10)

Strip **only** the 298 `._*` members and the Apple extended headers; keep all 219
real files byte-for-byte, verified by comparing extracted trees before and after.
Then write the `.sha256` and a drift harness.

This is the last moment it can be done: `upgrade-policy.md` forbids rebuilding a
tarball once frozen, and the freeze is what this brick delivers.

## Scope

**In:** the `mobile-pwa-first/2.0.0` snapshot + manifest; the surgical repack of
`mobile-only/1.0.0` + manifest + drift harness; harness registration.

**Out:** teaching `forge-snapshot.sh` to emit `.sha256` itself. It emits none today
(`grep -c sha256` → **0**) while `upgrade-policy.md:189` requires the manifest —
which is why three of four snapshots lack one. Maintainer decision to keep this
brick narrow; recorded as `open-questions.md` Q-001.

## Negative scope

MUST NOT touch `full-stack-monorepo/1.0.0.tar.gz` or its `.sha256` (frozen at
B.8.2, guarded by `b8-2.test.sh`), any archetype template, or the 219 real files
inside the repacked archive.
