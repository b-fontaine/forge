#!/usr/bin/env python3
"""Surgically repack mobile-only/1.0.0.tar.gz: drop the macOS AppleDouble members
and the Apple xattr pax headers, keep every real member byte-identical.

NOT a rebuild. forge-snapshot.sh would capture today's framework; 50 of the 219 real
files differ from today, and those 50 carry the era state that makes this archive a
valid 3-way-merge BASE (ADR-B98-001).
"""
import hashlib, sys, tarfile, io, gzip, os

SRC = ".forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz"
OUT = sys.argv[1] if len(sys.argv) > 1 else SRC + ".repacked"

def is_appledouble(name):
    base = os.path.basename(name)
    return base.startswith("._")

# ── read every member, recording content hashes for the before/after proof ──
kept, dropped = [], []
before = {}
with tarfile.open(SRC, "r:gz") as tf:
    for m in tf.getmembers():
        if is_appledouble(m.name):
            dropped.append(m.name)
            continue
        data = tf.extractfile(m).read() if m.isfile() else b""
        if m.isfile():
            before[m.name] = hashlib.sha256(data).hexdigest()
        kept.append((m, data))

print(f"  members kept   : {len(kept)}")
print(f"  members dropped: {len(dropped)}  (AppleDouble)")

# ── write the new archive: same members, same metadata, no pax xattrs ──
buf = io.BytesIO()
with tarfile.open(fileobj=buf, mode="w", format=tarfile.GNU_FORMAT) as out:
    for m, data in kept:
        ti = tarfile.TarInfo(name=m.name)
        # Preserve the ORIGINAL metadata — this is a repack, not a normalisation.
        ti.size, ti.mtime, ti.mode = m.size, m.mtime, m.mode
        ti.type, ti.linkname = m.type, m.linkname
        ti.uid, ti.gid = m.uid, m.gid
        ti.uname, ti.gname = m.uname, m.gname
        # pax_headers deliberately NOT copied: that is where
        # LIBARCHIVE.xattr.com.apple.provenance lives.
        out.addfile(ti, io.BytesIO(data) if m.isfile() else None)

raw = buf.getvalue()
gz = io.BytesIO()
# mtime=0 so the gzip header carries no wall-clock stamp (determinism, NFR-B98-003).
with gzip.GzipFile(fileobj=gz, mode="wb", mtime=0) as g:
    g.write(raw)
open(OUT, "wb").write(gz.getvalue())
print(f"  written        : {OUT} ({len(gz.getvalue())} bytes)")

# ── PROOF: every real member is byte-identical, and none was lost ──
after = {}
with tarfile.open(OUT, "r:gz") as tf:
    names = set()
    for m in tf.getmembers():
        names.add(m.name)
        assert not is_appledouble(m.name), f"AppleDouble survived: {m.name}"
        assert not (m.pax_headers or {}), f"pax headers survived on {m.name}"
        if m.isfile():
            after[m.name] = hashlib.sha256(tf.extractfile(m).read()).hexdigest()

missing = set(before) - set(after)
changed = [n for n in before if n in after and before[n] != after[n]]
print(f"  real files before/after: {len(before)} / {len(after)}")
print(f"  MISSING after repack   : {len(missing)}")
print(f"  CONTENT CHANGED        : {len(changed)}")
assert not missing, sorted(missing)[:5]
assert not changed, changed[:5]
print("  PROOF OK: every real file byte-identical, no pax header, no AppleDouble")
