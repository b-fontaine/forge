# Evidence — `b9-8-snapshot`

All probes 2026-09-10.

---

## P-1 — what a snapshot is, established before building one

`forge-snapshot.sh` resolves `.forge/framework-owned-paths.yml` and tars those paths.
It reads no archetype template and renders nothing. `<archetype>/<version>` is a
**label** for when the capture was taken — `ai-native-rag/1.0.0.tar.gz` contains
`.forge/schemas/full-stack-monorepo/2.0.0.yaml`, which follows from the definition.

Recorded first because the opposite reading had produced the belief that B.9.8 was
blocked on a 2.0.0 render path. It never was.

## P-2 — the freeze an ADR had already assigned here

`.forge/specs/b8-legacy-snapshot.md:37` — **ADR-B8-2-004**: *"flagship-only;
`mobile-only/1.0.0` freeze is B.9."* Open since 2026-05-30. §5.2 of the plan does not
mention it; the ADR does.

State on arrival:

| | |
|---|---|
| `.sha256` | absent — never formally frozen |
| entries | 598, of which **299** AppleDouble `._*` |
| headers | `LIBARCHIVE.xattr.com.apple.provenance` throughout |
| consumer | `b4.test.sh:257-264` — existence, size band, `file -b`; **not** the bytes |

## P-3 — a rebuild would have been wrong, and that was measured

```
extracted the archive, compared its 219 real files to today's tree
  identical to today : 169
  DIFFERENT from today:  50
  no longer exist    :   0
```

50 files carry era state. `forge-snapshot.sh build` captures the framework as of
today, so a rebuild would have replaced them with 2026-09 versions and made every
subsequent `forge upgrade` three-way-merge against a baseline no adopter ever had.
The litter is cosmetic; a wrong BASE is not.

## P-4 — the repack, and its proof

Member-by-member: drop `._*` and the Apple pax headers, copy everything else with
its **original** metadata (no mtime/uid normalisation — that is what a *build* does).

```
  members kept   : 299
  members dropped: 299  (AppleDouble)
  real files before/after: 219 / 219
  MISSING after repack   : 0
  CONTENT CHANGED        : 0
  PROOF OK: every real file byte-identical, no pax header, no AppleDouble
```

Deterministic: two runs produced byte-identical output (NFR-B98-003).
465 148 → 433 915 bytes. Script committed at `repack.py` so the transform is
auditable rather than described.

## P-5 — a count that was wrong until the tool disagreed with the grep

First reported as **298** AppleDouble entries, from `grep -c '/\._'`. The repack,
counting by basename, found **299**. The extra is `._.` — the resource fork of the
root directory `.`, which has no `/` before it.

Kept in the record because the two numbers disagreeing is what surfaced it; a
grep-only sweep would have left one member behind and the freeze would have pinned it.

## P-6 — the new snapshot

```
$ bin/forge-snapshot.sh build mobile-pwa-first 2.0.0
✓ snapshot built: … (553 files, 1138222 bytes gzipped, SOURCE_DATE_EPOCH=1788986605)
$ tar -tzf … | grep -c '\._'   → 0
```

Built on Linux through the Python tarfile path, so none of the macOS litter that
cost `mobile-only` a repack.

## P-7 — both manifests

Written by hand — `forge-snapshot.sh` emits none (`grep -c sha256` → **0**) while
`upgrade-policy.md:189` requires one. Both verify:

```
  1.0.0.tar.gz: OK
  2.0.0.tar.gz: OK
```

## P-8 — guards, and a probe that lied

Hosted in already-registered harnesses: `forge-ci.yml` is at **419 / 420** lines
(NFR-CI-002) and a new harness would have consumed the last one.

| probe | expected | result |
|---|---|---|
| append a byte to the frozen tarball | `b4` RED "FROZEN SNAPSHOT DRIFTED" | fired |
| delete `1.0.0.sha256` | `b4` RED "no .sha256 manifest" | fired |
| corrupt `2.0.0.sha256` | `b9-2` RED "does not match its manifest" | **fired on the second attempt** |

The first attempt at the third used `sed 's/^./f/'` against a hash that already began
with `f` — a no-op. The guard stayed green and looked like a guard that does not
guard. Re-done by overwriting the hash with zeros. A probe that does not mutate is
indistinguishable from a broken assertion, and this is the third time in this session
that distinction mattered.

## P-9 — regression

- `a7` (owns `upgrade-policy.md`'s sections), `b4`, `b9-2`, **`b8-2`** (the flagship
  freeze — must not drift), `b8-15`: all GREEN.
- `verify.sh` **623 / 0**; `constitution-linter.sh` **92 PASS / 0 FAIL, OVERALL
  PASS** — after the status flip.
- `shellcheck --severity=warning` over `.forge/scripts` and `bin`: clean.
- Full 80-entry CI matrix sweep: see `tasks.md` T5.2.

Negative scope: `full-stack-monorepo/1.0.0.tar.gz` and its `.sha256` byte-unchanged;
no archetype template touched.
