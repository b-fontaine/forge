# Open questions — `b9-8-snapshot`

## Q-001 — `forge-snapshot.sh` does not emit the manifest its own policy requires

`grep -c sha256 bin/forge-snapshot.sh` → **0**. `upgrade-policy.md:189` requires a
committed sibling `<version>.sha256` for a frozen tarball. Every manifest in the repo
is therefore hand-written, which is why three of the four snapshots had none before
this brick.

Out of scope by maintainer decision (2026-09-10), to keep the brick narrow. It stays
a cause rather than a symptom: the next snapshot will lack a manifest unless whoever
builds it remembers.

## Q-002 — two snapshots still have no manifest

`ai-native-rag/1.0.0` and `event-driven-eu/1.0.0`. Neither is a declared freeze
target — no migration crosses them yet — so `upgrade-policy.md`'s freeze rules do not
bite. They are unpinned rather than in violation.

Worth resolving alongside Q-001, since one loop over the snapshot directory would
close both.

## Q-003 — `b4.test.sh:257-264` asserts a size band, not the bytes

The pre-existing snapshot test checks existence, a size range, and `file -b`. The
repack changed the size by ~31 KB and it still passed, which means that test would
not have noticed a rebuild either. It is now backed by the sha256 guard added here;
the size band is left as-is rather than tightened, since the manifest supersedes it.
