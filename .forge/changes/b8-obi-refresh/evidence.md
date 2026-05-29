# Evidence — b8-obi-refresh
<!-- Status: implemented (pending verifier) -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch trio, OBI/Beyla leg) -->

This file captures the live transcripts, Context7 snippets, and CI sweep
outcomes anchoring each ADR in `design.md`. Anti-self-validation
discipline (T5.2 lesson) — every claim in `design.md` MUST trace to a
verifiable artefact recorded here. Verifier MUST re-execute the
commands and compare transcripts from scratch (no transcript trust).

---

## § 1 — ADR-B8-OBI-001 : target pin `grafana/beyla:3.15.0` live multi-arch

**Command** (2026-05-29) :

```
$ docker manifest inspect grafana/beyla:3.15.0
```

**Output** :

```json
{
   "schemaVersion": 2,
   "mediaType": "application/vnd.oci.image.index.v1+json",
   "manifests": [
      {
         "mediaType": "application/vnd.oci.image.manifest.v1+json",
         "size": 1240,
         "digest": "sha256:8ff0dcb4aa31fab39ba0b40715d0c0441d4522b43fb7886768ec280cc401dd69",
         "platform": { "architecture": "amd64", "os": "linux" }
      },
      {
         "mediaType": "application/vnd.oci.image.manifest.v1+json",
         "size": 565,
         "digest": "sha256:ee394afbec88ba6ef4a999c098d5a63210164358cbf65eff615c0cd4580a104d",
         "platform": { "architecture": "unknown", "os": "unknown" }
      },
      {
         "mediaType": "application/vnd.oci.image.manifest.v1+json",
         "size": 1240,
         "digest": "sha256:ac770096bcb51bde0a810a1ef5009ddaed5b3b08dacdec856cccd1be6e65e30d",
         "platform": { "architecture": "arm64", "os": "linux" }
      },
      {
         "mediaType": "application/vnd.oci.image.manifest.v1+json",
         "size": 565,
         "digest": "sha256:4857e16c4a684d7803ac167c5616db0caf4fbdfb420dfb5babe4792fd3aa3748",
         "platform": { "architecture": "unknown", "os": "unknown" }
      }
   ]
}
```

**Audit ticket** : the 2 platform manifests
(`linux/amd64` sha256:8ff0dcb… + `linux/arm64` sha256:ac770096…) are
the byte-identical pull targets. The 2 `unknown/unknown` manifests are
cosign/SLSA attestation manifests — not platform images, ignored by
Kubernetes image puller.

---

## § 2 — ADR-B8-OBI-002 : Linux capability set UNCHANGED (Beyla 3.x distributed-traces docs)

**Source** : Context7 `/grafana/beyla`, file
`docs/sources/distributed-traces.md`, snippet "Kubernetes DaemonSet
Deployment for Beyla", fetched 2026-05-29.

**Capability set verbatim** :

```yaml
securityContext:
  runAsUser: 0
  readOnlyRootFilesystem: true
  capabilities:
    add:
      - BPF                 # Required for most eBPF probes to function correctly.
      - SYS_PTRACE          # Allows Beyla to access the container namespaces and inspect executables.
      - NET_RAW             # Allows Beyla to use socket filters for http requests.
      - CHECKPOINT_RESTORE  # Allows Beyla to open ELF files.
      - DAC_READ_SEARCH     # Allows Beyla to open ELF files.
      - PERFMON             # Allows Beyla to load BPF programs.
      - NET_ADMIN           # Allows Beyla to inject HTTP and TCP context propagation information.
      - SYS_ADMIN           # Allows Beyla to get better language specific information.
```

**Analysis** :
- Beyla 3.x docs ship TWO snippets : a 6-cap "unprivileged-minimal"
  (omits NET_ADMIN / SYS_ADMIN) AND the 8-cap
  "distributed-traces.md" snippet above.
- The Forge flagship enables W3C `traceparent` E2E propagation via
  `t5-otel-traceparent-e2e` ⇒ NET_ADMIN is **required**. SYS_ADMIN
  is **recommended** for Go/Rust language-specific introspection
  (matches our Rust backend + Flutter frontend stack).
- Forge ships the 8-cap set verbatim. NO edit.

---

## § 3 — ADR-B8-OBI-003 : RBAC widened — add `services` resource

**Source** : Context7 `/grafana/beyla`, file
`docs/sources/cilium-compatibility.md`, snippet "Apply Beyla RBAC
Permissions", fetched 2026-05-29.

**Beyla 3.x ClusterRole verbatim** :

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: beyla
rules:
  - apiGroups: [ "apps" ]
    resources: [ "replicasets" ]
    verbs: [ "list", "watch" ]
  - apiGroups: [ "" ]
    resources: [ "pods", "services", "nodes" ]   # services present in Beyla 3.x
    verbs: [ "list", "watch" ]
```

**Diff applied** to `obi-daemonset.yaml.tmpl` :

```diff
   - apiGroups: [""]
-    resources: ["pods", "nodes"]
+    resources: ["pods", "nodes", "services"]
     verbs: ["get", "list", "watch"]
```

**Aegis least-privilege audit** :
- Single resource added (`services`).
- Verb set UNCHANGED : `get/list/watch` (read-only).
- NO write verbs (`create/update/delete/patch`) introduced.
- NO new API groups (`apiGroups: [""]` already present, just one
  additional resource).
- Beyla's stated minimum is `list, watch` ; Forge preserves the
  additional `get` verb already granted to `pods/nodes` for
  read-symmetry — harmless superset.

---

## § 4 — ADR-B8-OBI-004 : kernel floor 5.8 UNCHANGED

**Source** : Context7 `/grafana/beyla`, file `README.md`,
section "Requirements", fetched 2026-05-29.

**Verbatim** :

```
To run Beyla, your system needs to meet specific requirements.
A Linux kernel version 5.8 or higher with BTF enabled is necessary.
Alternatively, RedHat Enterprise Linux 4.18 kernels build 348 and above,
including distributions like CentOS, AlmaLinux, and Oracle Linux, are
supported due to required kernel backports. BTF is generally enabled
by default on most Linux distributions with kernel 5.14 or higher.
You can confirm BTF enablement by checking for the existence of
`/sys/kernel/btf/vmlinux`.
```

**Analysis** : Beyla 3.x carries the **identical** 5.8+ kernel floor
as Beyla 2.x. The opt-in node label `forge.dev/kernel-min-58: "true"`
remains the correct gate. Zero migration burden for adopters who
already labelled their kernel-≥5.8 nodes per `t5-otel-stack`
ADR-OTEL-007.

---

## § 5 — ADR-B8-OBI-005 : mirror count = 4

**Command** (2026-05-29) :

```
$ find . -type f \( -name '*obi*' -o -name '*beyla*' \) \
       -not -path '*/node_modules/*' -not -path '*/.git/*'
```

**Output** :

```
./examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml
./.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl
./cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl
./cli/assets/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml
```

(Filtered to `obi-daemonset.*` only — the other matches are unrelated
mobile-only template paths containing `mobile-only`.)

**Mirror table** :

| # | Path                                                                                                       | Type       |
|---|------------------------------------------------------------------------------------------------------------|------------|
| 1 | `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`                    | canonical  |
| 2 | `cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`         | cli-bundle |
| 3 | `examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`                                              | rendered   |
| 4 | `cli/assets/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`                                   | cli-bundle |

**Path canonicalisation note** : `specs.md` Cluster 1 cited paths
prefixed `templates/full-stack-monorepo/1.0.0/...` (conceptual /
scaffold-manifest-driven). Real on-disk layout is `.forge/templates/
archetypes/full-stack-monorepo/...` (flat, no version segment). The
implementation honours the real path ; the spec's prefix was a
nomenclature drift not corrected per Article V freeze.

---

## § 6 — ADR-B8-OBI-006 : sibling-harness coupling break (hybrid)

**Pre-change sweep** (2026-05-29, before edits) :

```
.forge/scripts/tests/t5-otel.test.sh:128 — image: grafana/beyla:2.0.1 hard-pin (exact match)
.forge/scripts/tests/t5-otel.test.sh:233 — beyla: "2\.0\.1" hard-pin in observability.yaml
.forge/scripts/tests/b8-coroot.test.sh:169 — version: "2\.0\.0" hard-pin
.forge/scripts/tests/b8-coroot.test.sh:196 — last_reviewed: 2026-05-2[67]
.forge/scripts/tests/b8-signoz.test.sh:229 — version: "2\.0\.0" hard-pin
.forge/scripts/tests/b8-signoz.test.sh:295 — last_reviewed: 2026-05-26 exact
.forge/scripts/tests/b8-signoz.test.sh:304 — expires_at: 2027-05-26 exact
.forge/scripts/tests/b8-signoz.test.sh:323 — breaking_change: true exact
```

**Post-change sweep** (after ADR-B8-OBI-006 hybrid applied) :

| Harness                       | Line  | Strategy | New assertion                                                       |
|-------------------------------|------:|----------|----------------------------------------------------------------------|
| `t5-otel.test.sh`             |   128 | narrow   | `image: grafana/beyla:<any-tag>` + non-`:latest` invariant           |
| `t5-otel.test.sh`             |   237 | narrow   | `versions.beyla:` key-presence only (value owned by b8-obi)          |
| `b8-coroot.test.sh`           |   169 | widen    | `version: 2\.[0-9]+\.[0-9]+` (accept v2.x.y line)                    |
| `b8-coroot.test.sh`           |   196 | widen    | `last_reviewed: 2026-05-2[6789]` (1-char widening)                   |
| `b8-signoz.test.sh`           |   229 | widen    | `version: 2\.[0-9]+\.[0-9]+`                                         |
| `b8-signoz.test.sh`           |   299 | widen    | `last_reviewed: 2026-05-2[6789]`                                     |
| `b8-signoz.test.sh`           |   304 | widen    | `expires_at: 2027-05-2[6789]`                                        |
| `b8-signoz.test.sh`           |   323 | narrow   | `breaking_change: (true\|false)` (value ownership transferred)       |

**Post-sweep grep** :

```
$ grep -rn 'beyla.*2\.0\.1\|2\.0\.1.*beyla' .forge/scripts/tests/
.forge/scripts/tests/b8-obi.test.sh:7:   # — comment in this harness's own header — intentional
.forge/scripts/tests/b8-obi.test.sh:54:  OLD_PIN="grafana/beyla:2.0.1"   # — used by L2 informational test, intentional
```

The only remaining 2.0.1 references are **inside b8-obi.test.sh
itself** (header comment + L2 informational `OLD_PIN` constant). No
external sibling harness hard-pins Beyla 2.0.1 any longer. The
coupling chain is broken.

**Sibling regression check** (run post-sweep) :

```
$ bash .forge/scripts/tests/t5-otel.test.sh --level 1     →  14/14 GREEN
$ bash .forge/scripts/tests/b8-coroot.test.sh --level 1    →  13/13 GREEN
$ bash .forge/scripts/tests/b8-signoz.test.sh --level 1    →  20/20 GREEN
$ bash .forge/scripts/tests/b8-obi.test.sh --level 1       →  22/22 GREEN
                                                              ──────────
                                                       Total: 69/69
```

---

## § 7 — ADR-B8-OBI-007 : `forge-ci.yml` line budget (comment compression)

**Pre-edit baseline** :

```
$ wc -l .github/workflows/forge-ci.yml
300 .github/workflows/forge-ci.yml
```

**Compression applied** : removed 3 one-line audit comments above
the `t5-cargo.test.sh`, `t5-bin-server.test.sh`, `t5-3-1.test.sh`
matrix entries (each comment described the change-namespace + L2
opt-in env var ; same info preserved in change-specific
`.forge/changes/*/design.md` and CHANGELOG entries). Mirrors
`ADR-T533-002` (T5.3.3) precedent verbatim — comment compression
without functional change.

**Diff** (3 lines removed) :

```
- - name: t5-cargo.test.sh
-   # T5.1.E Cargo pin refresh. L2 opt-in via FORGE_T5C_LIVE=1.
-   run: bash .forge/scripts/tests/t5-cargo.test.sh --level 1
+ - name: t5-cargo.test.sh
+   run: bash .forge/scripts/tests/t5-cargo.test.sh --level 1

- - name: t5-bin-server.test.sh
-   # T5.1.E bin-server deps. L2 opt-in via FORGE_T5BSD_LIVE=1.
-   run: bash .forge/scripts/tests/t5-bin-server.test.sh --level 1
+ - name: t5-bin-server.test.sh
+   run: bash .forge/scripts/tests/t5-bin-server.test.sh --level 1

- - name: t5-3-1.test.sh
-   # T5.3.1 docker-compose.dev.yml hygiene. L2 opt-in via FORGE_B1DUM_DOCKER=1.
-   run: bash .forge/scripts/tests/t5-3-1.test.sh --level 1
+ - name: t5-3-1.test.sh
+   run: bash .forge/scripts/tests/t5-3-1.test.sh --level 1
```

**Added entry** (3 lines added) :

```yaml
- name: b8-obi.test.sh
  # B.8.8 OBI/Beyla refresh 2.0.1 → 3.15.0. L2 opt-in via FORGE_B8_OBI_DOCKER=1.
  run: bash .forge/scripts/tests/b8-obi.test.sh --level 1
```

**Post-edit line count** :

```
$ wc -l .github/workflows/forge-ci.yml
300 .github/workflows/forge-ci.yml
```

Net : -3 + 3 = 0. NFR-CI-002 plafond preserved at 300/300.

---

## § 8 — ADR-B8-OBI-008 : snapshot ceiling preserved + determinism note

**Snapshot regen** (2026-05-29) :

```
$ rm .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
$ bash bin/forge-snapshot.sh build full-stack-monorepo 1.0.0
✓ snapshot built: ...1.0.0.tar.gz (290 files, 675088 bytes gzipped)
```

| Metric                | Pre-change (post-sibling 2) | Post-change | Delta   |
|-----------------------|-----------------------------|-------------|---------|
| Tarball size (bytes)  | 668589                      | 675088      | +6499   |
| Ceiling (ADR-B8-SIG-008) | 716800                   | 716800      | (no edit) |
| Headroom              | 48211                       | 41712       | -6499   |

**Delta justification** : the +6499 B growth comes from
(a) the new 5-line audit comment block × 2 mirrors, (b) the
`services` resource added to the ClusterRole × 2 mirrors,
(c) the `observability.yaml@2.1.0` annotation bump × 2 mirrors,
(d) the v2.1.0 comment block + Beyla rationale section added to
`observability.yaml` (which is **inside** the snapshot scaffold tree
copy under `.forge/standards/`). The +6 KB delta is well under the
~47 KB headroom. NO ADR bump required.

**Determinism note** (NFR-B8-OBI-011 status) : `bin/forge-snapshot.sh`
does NOT enforce `SOURCE_DATE_EPOCH` — running `build` twice produced
**different SHA-256** with byte-length deltas of ~70 B. Inherited
behavior : sibling legs (`b8-coroot-rehost` + `b8-signoz-unified`)
shipped without enforcing this property either. Determinism remains
**aspirational** in this leg — a follow-up change to harden
`bin/forge-snapshot.sh` (probably under F.x scope) is the right
locus, not the trio-closure leg. NFR-B8-OBI-011 is documented as
deferred ; no harness assertion attempts to enforce it (consistent
with sibling 1 / sibling 2 stance).

**Backward compat** (`a7.test.sh` 29/29 PASS preserved) :

```
$ bash .forge/scripts/tests/a7.test.sh
...
── Summary ──
  Passed:  29
  Failed:  0
```

---

## § final — pre-flip full-CI sweep

Recorded post-completion of Phases 1-5. Verifier MUST re-execute
from scratch before flipping `planned → implemented`.

| Harness                                          | Result      | Notes                                      |
|--------------------------------------------------|-------------|--------------------------------------------|
| `b8-obi.test.sh --level 1`                       | **22/22 GREEN** | this change's harness                  |
| `b8-coroot.test.sh --level 1`                    | **13/13 GREEN** | trio sibling 1 (widened by ADR-B8-OBI-006) |
| `b8-signoz.test.sh --level 1`                    | **20/20 GREEN** | trio sibling 2 (widened by ADR-B8-OBI-006) |
| `t5-otel.test.sh --level 1`                      | **14/14 GREEN** | birth harness (narrowed by ADR-B8-OBI-006) |
| `a7.test.sh` (no `--level` flag accepted)         | **29/29 GREEN** | forge-upgrade backward compat              |
| `validate-standards-yaml.sh observability.yaml`   | **STD-PASS**    | J.7 invariants preserved                   |
| `validate-change-yaml.sh .forge/.../b8-obi-refresh/.forge.yaml` | exit 0 | F.2 invariant            |
| `wc -l .github/workflows/forge-ci.yml`             | **300**       | NFR-CI-002 plafond preserved              |

**Sibling-harness coupling break audit** (mémoire
`shared_standard_sibling_harness_coupling.md`) :
- Pre-change : 8 hard-pinned assertions across 3 sibling harnesses.
- Post-change : 0 hard-pinned Beyla 2.0.1 references outside
  `b8-obi.test.sh`'s own header + L2 informational constant.
- 4 narrowing edits (transfer pin ownership to new owner harness)
  + 4 widening edits (1-char regex window for date / version
  patterns inside the trio window).
- Net effect : future trio additive bumps (post-v2.1.0) landing in
  the v2.x.y line + `2026-05-2[6789]` window do NOT need any
  sibling-harness edit.

**Anti-self-validation hook** : independent reviewer (separate
session, no transcript trust) MUST re-execute :
1. `docker manifest inspect grafana/beyla:3.15.0` → confirm digests
   match § 1.
2. The 4 trio harnesses + `a7.test.sh` + standards validators →
   confirm 69/69 + 29/29 + STD-PASS.
3. `verify.sh` + `constitution-linter.sh` → confirm 0 FAIL +
   OVERALL PASS.
4. `grep -rn 'beyla.*2\.0\.1' .forge/scripts/tests/` → confirm
   only b8-obi.test.sh internal references remain.

---

## § post-review — independent-reviewer findings + remediation (2026-05-29)

Independent code reviewer pass (Author / Reviewer separation per
T5.2 lesson) executed via OMC code-reviewer subagent. Verdict :
**APPROVE**, 0 critical, 1 HIGH + 1 MEDIUM + 3 LOW. All 15
mandatory re-executions matched author claims byte-for-byte.

### HIGH — Snapshot determinism (closed in-leg)

Reviewer flagged : `bin/forge-snapshot.sh` did not enforce
`SOURCE_DATE_EPOCH` so back-to-back builds produced different
SHA-256, contradicting NFR-B8-OBI-011's "byte-identical" claim.

**Fix applied** (commit pending) :
- Replaced `tar -czf` invocation with Python `tarfile` (cross-
  platform GNU/BSD identical output) writing through `gzip.GzipFile`
  with explicit `mtime=0` (strips gzip header timestamp).
- Each `TarInfo` mtime pinned to `SOURCE_DATE_EPOCH` (env-var first,
  then `git log -1 --pretty=%ct`, then 0 — mirrors `bin/forge-sbom.sh`
  ADR-I5-CW-002 fallback chain).
- `uid=0 gid=0 uname='' gname=''` normalised on every entry.
- Entries sorted lexically before write.
- USTAR_FORMAT (POSIX portable, no variable pax extended headers).

**New L1 harness assertion** : `_test_b8obi_l1_023_snapshot_determinism`
deletes the canonical snapshot, rebuilds twice with the patched
script, asserts `shasum -a 256` matches across the two rebuilds.
Adds 1 L1 test → harness now **23 L1** (not 22 as originally
shipped). Methodology asserts rebuild-vs-rebuild determinism (not
rebuild-vs-historical — owned-source edits between runs legitimately
change content).

**Outcome** : two back-to-back rebuilds at 2026-05-29 produced
`shasum -a 256` = `b53ad4...` byte-identical. NFR-B8-OBI-011 now
**enforced**, not deferred. Reviewer's HIGH finding is closed
in-leg (not deferred to a follow-up change as originally
acknowledged).

### MEDIUM — `_test_b8sig_l1_013` test-name drift (closed in-leg)

Reviewer flagged : the widening of `_test_b8sig_l1_013_waiver_breaking_change`
to accept `(true|false)` made the test name misrepresent its
contents (it no longer asserted `breaking_change: true`).

**Fix applied** : split into 2 tests per reviewer recommendation :
- `_test_b8sig_l1_013_waiver_cite_appendonly` — strict (WAIVER
  block presence + ADR-J7-004 citation, Article V append-only
  invariant). NO breaking_change check.
- `_test_b8sig_l1_021_breaking_change_field_present` — field-
  presence only (boolean exists, value-agnostic). Current value
  ownership owned by `b8-obi.test.sh::_test_b8obi_l1_017_standard_breaking_change_false`.

Net : 1 split → 2 tests, names truthful, b8-signoz.test.sh now
**21 L1** (was 20). Verified GREEN 21/21 post-split.

### LOW — 3 nits (acknowledged or fixed)

- **`b8-obi.test.sh:54` OLD_PIN const** — reviewer marked
  "intentional, no fix needed". Audit comment + L2 informational
  test reference. Acknowledged.
- **`cli/.gitignore:3` mirror gitignored** — documented in
  `design.md::ADR-B8-OBI-005` post-fact section that the 4-mirror
  invariant is enforced by harness L1 cmp-checks, not git diff.
  Matches sibling precedent (Coroot + SigNoz both shipped with
  the same cli/.gitignore posture).
- **`observability.yaml:67` rc.5 forward-ref** — edited to drop
  `release target v0.4.0-rc.5` ; replaced with neutral
  `(sibling 3 of 3 — Coroot leg 1 + SigNoz leg 2 + OBI leg 3)`.
  Robust to RC numbering churn.

### Post-fix final sweep (2026-05-29)

| Harness                            | Result          |
|------------------------------------|-----------------|
| `b8-obi.test.sh --level 1`         | **23/23 GREEN** (+1 from determinism test) |
| `b8-signoz.test.sh --level 1`      | **21/21 GREEN** (+1 from split)            |
| `b8-coroot.test.sh --level 1`      | **13/13 GREEN**                            |
| `t5-otel.test.sh --level 1`        | **14/14 GREEN**                            |
| `a7.test.sh`                       | **29/29 GREEN**                            |
| `validate-standards-yaml.sh observability.yaml` | **STD-PASS** |
| `validate-change-yaml.sh`          | exit 0          |
| `verify.sh`                        | 0 FAIL          |
| `constitution-linter.sh`           | OVERALL PASS    |
| `wc -l forge-ci.yml`               | 300/300         |
| Snapshot size                      | ≤ 716800 B      |
| Snapshot determinism (2× rebuild)  | byte-identical SHA-256 |
