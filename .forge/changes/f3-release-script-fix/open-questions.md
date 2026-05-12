# Open Questions — f3-release-script-fix

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Old script handling — delete vs symlink

- **Status**: answered
- **Raised in**: mission spec ; proposal.md
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The mission spec offers two options for the old
`scripts/release-v0.3.0.sh` file once the new generic
`scripts/release.sh` ships :

- **Option A — Delete**. Simpler. Clean diff. No backward-compat
  surface. Anyone who had `scripts/release-v0.3.0.sh` pinned in
  their tooling (CI, runbook) will hit a `No such file or
  directory` error.
- **Option B — Symlink**. `scripts/release-v0.3.0.sh →
  release.sh`. Preserves the old invocation path. Adds a stale
  marker that future-maintainers might forget to clean up. The
  symlink would point to a script whose default behaviour now
  REQUIRES `--version 0.3.0` to behave like the old one, so a
  literal `bash scripts/release-v0.3.0.sh` invocation fails
  anyway (missing `--version`).

Lean **A — delete**, because B's compat win is illusory : the new
script refuses to run without `--version`, so the symlink would
fail with a usage error anyway. The clearer break is preferable.

### Resolution

**Resolved by ADR-F3-001** in `design.md`. Decision : **Option A —
delete the old file**. The new script's required `--version` flag
means a symlink would fail with the same usage error a missing-
file error would produce ; the symlink adds clutter without compat
value.

---

## Q-002: `cli/assets/scripts/` template handling

- **Status**: answered
- **Raised in**: mission spec
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The mission brief states that `cli/assets/scripts/release-v0.3.0.sh`
is a "shipped artefact" emitted into adopter repos by `forge init`,
byte-identical (or close) to the maintainer-side script, and that
its contents should be updated to mirror the new generic script
while keeping the filename for backward-compat.

Investigation on 2026-05-12 :

- `find cli/assets -type d -maxdepth 4` returns
  `cli/assets/scripts` → **does not exist**.
- `find . -name "release-v0.3.0.sh"` returns exactly **one** path
  : `scripts/release-v0.3.0.sh` (maintainer-side, this repo's root).

The mission brief acknowledges this possibility ("If during the
work you discover that the cli/assets/ copy is NOT shipped to
adopters … surface it via `[NEEDS CLARIFICATION:]` instead of
guessing. Do not delete it without explicit confirmation.").

So : the file the brief asks us to update **does not exist**.
There is nothing to update, nothing to keep, nothing to delete.

### Resolution

**Resolved by ADR-F3-002** in `design.md`. Decision : the
`cli/assets/scripts/` template is **out of scope for F.3**
because it does not exist in the current tree (verified
2026-05-12). The script is currently maintainer-side only. If
a future change ships a release helper to adopters as part of
`forge init`, that change owns creating the template AND the
versioning policy for it.

No `[NEEDS CLARIFICATION:]` inline marker is needed — the
question has been definitively answered : there is no template,
so there is nothing to touch in F.3.

---

## Q-003: Flag form — `--version <X.Y.Z>` vs `--bump <level>`

- **Status**: answered
- **Raised in**: mission spec
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The mission spec offers two flag forms for the release-version
mechanism :

- **Option A — `--version <X.Y.Z>`**. Explicit ; matches `git
  tag` mental model ; trivial validation
  (`^[0-9]+\.[0-9]+\.[0-9]+$`).
- **Option B — `--bump <patch|minor|major>`**. Implicit ;
  requires the script to read `VERSION`, compute the next
  semver, and rewrite `VERSION`. More complex ; can mismatch
  with the CHANGELOG that the maintainer already pinned by
  hand.

Trade-off : Option B is more automation-friendly *if* the
maintainer never writes the CHANGELOG by hand (i.e., if a tool
generates it). Forge's current GOVERNANCE.md § Release Process
step 1 says the maintainer **archives the change first** (which
writes a sealed `## [X.Y.Z]` block in CHANGELOG.md), then the
script picks up the already-pinned version. So the version is
pinned BEFORE the script runs ; the script just needs to be
told which version to use.

### Resolution

**Resolved by ADR-F3-003** in `design.md`. Decision : **Option A
— `--version <X.Y.Z>`**. The CHANGELOG and VERSION files are
manually pinned by the maintainer at archive time per
GOVERNANCE.md ; the script's job is to **verify** that what's
pinned matches what's being released, not to **decide** the next
version. `--version <X.Y.Z>` is the simpler, more explicit form.

---

## Q-004: OTP fallback chain — order and prompt UX

- **Status**: answered
- **Raised in**: mission spec
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The mission spec sketches a three-tier OTP fallback :

- Explicit flag `--otp <6-digits>` (preferred).
- Interactive `read -sp` from stdin if absent AND stdin is a TTY.
- Env-var `NPM_OTP` if both above are absent.

Order : flag → TTY → env-var. Prompt UX : `read -sp` hides the
input ; should we also offer an option to skip (leave OTP blank)
in case the maintainer disabled 2FA temporarily ?

### Resolution

**Resolved by ADR-F3-004** in `design.md`. Decision : the order
is **flag → TTY → env-var**, fail loudly with exit 2 + a clear
message if all three are absent AND `--skip-npm` is not set AND
`--dry-run` is not set. Empty TTY input is treated as "no OTP
supplied" and exits 2 (we do NOT support a "no OTP" mode silently
— if 2FA is off, the maintainer can pass `--otp ""` explicitly,
which the validator rejects ; or run with `--skip-npm` and publish
manually).
