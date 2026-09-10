# Design — `b9-8-snapshot`

## Repack, not rebuild — and the measurement that decided it

`forge-snapshot.sh build` captures the framework's owned paths **as of now**. For a
*new* version that is exactly right. For an *existing* archive it is destructive:

```
extracted mobile-only/1.0.0.tar.gz, compared its 219 real files to today's tree
  identical to today : 169
  DIFFERENT from today:  50
  no longer exist    :   0
```

Those 50 are the era state. A merge BASE that has been silently refreshed makes
`forge upgrade` diff against a baseline the adopter never had — a wrong answer
delivered confidently, which is worse than macOS litter.

So the archive is repacked member-by-member: drop the 299 `._*` members and the
`LIBARCHIVE.xattr.com.apple.*` pax headers, copy every other member's content and
**original** metadata verbatim. Deliberately no mtime/uid normalisation — that is
what a *build* does, and this is not one.

### The proof is in the transform, not after it

The repack script extracts both archives and compares a SHA-256 per real member:

```
  real files before/after: 219 / 219
  MISSING after repack   : 0
  CONTENT CHANGED        : 0
  PROOF OK: every real file byte-identical, no pax header, no AppleDouble
```

Run twice, byte-identical output (NFR-B98-003). 465 148 → 433 915 bytes.

### A count that was wrong until it was checked

The AppleDouble total is **299**, not the 298 first reported. `grep -c '/\._'`
misses `._.` — the resource fork of the root directory `.`, which has no `/` before
it. The repack counts by basename, which is why the discrepancy surfaced at all.

## Where the guards live

`forge-ci.yml` sits at **419 lines against a 420 cap** (NFR-CI-002). A new harness
would consume the last line, so both guards go into already-registered harnesses
that own the right territory:

| guard | harness | why there |
|---|---|---|
| `mobile-only/1.0.0` frozen + AppleDouble-free | `b4.test.sh` | b4 owns `mobile-only` and already references this tarball at `:45` |
| `mobile-pwa-first/2.0.0` present + manifest matches | `b9-2.test.sh` | registered, owns the archetype |

Both assert `sha256sum -c` against the committed manifest — the drift check the
flagship has had since B.8.2 and `mobile-only` never did.

## Mutation probes

| probe | expected | result |
|---|---|---|
| append a byte to the frozen tarball | b4 RED "FROZEN SNAPSHOT DRIFTED" | fired |
| remove `1.0.0.sha256` | b4 RED "no .sha256 manifest" | fired |
| corrupt `2.0.0.sha256` | b9-2 RED "does not match its manifest" | fired **on the second attempt** |

The first attempt at the third probe used `sed 's/^./f/'` on a hash that already
began with `f` — a no-op that left the test green and looked like a test failure.
Recorded because a probe that does not mutate is indistinguishable from a guard that
does not guard.

## What is NOT fixed here

`forge-snapshot.sh` still emits no `.sha256` (`grep -c sha256` → 0) while
`upgrade-policy.md:189` requires one. Both manifests in this brick were written by
hand. Maintainer chose to keep the brick narrow; `open-questions.md` Q-001.
