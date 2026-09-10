# Migration Paths

This document is the **index of every migration Forge supports**, and the
walkthrough for the ones that change archetype.

Two documents divide the territory, and this is the boundary
(`b9-10-migration-paths` ADR-B910-002) :

- **Same archetype, version to version** — the runbook lives in
  [`MIGRATIONS.md`](MIGRATIONS.md). Phases, canary cutover, rollback, latency
  methodology.
- **Different archetype** — the walkthrough lives here. The question is not
  "which version" but "what does the target archetype have that the source does
  not".

Either way the migration gets **one row in the index below**, so a reader who
starts here always reaches the right document in one hop.

> Created 2026-05-05 by `t5-connect-codegen` to back the
> `transport-codegen-coverage` linter rule (FR-T5-CC-040). Future
> migrations append a new section per archetype × version pair.
>
> Index table, boundary statement and the B.9 section added 2026-09-10 by
> `b9-10-migration-paths`. The first sentence used to claim an index this file
> did not have: the flagship migration had shipped a driver, a runbook and a
> rollback procedure without ever appearing here. `b9-2.test.sh::T-029` now
> asserts that every `bin/forge-migrate-*.sh` has a row.

## Index

| from | to | kind | driver | walkthrough |
|---|---|---|---|---|
| `full-stack-monorepo / 1.0.0` | `full-stack-monorepo / 2.0.0` | same-archetype, major | `bin/forge-migrate-flagship.sh` | [`MIGRATIONS.md`](MIGRATIONS.md) |
| `full-stack-monorepo / 1.0.0` on v0.3.x | the same, on v0.4.0-rc.x | same-archetype, in place | `forge upgrade` (3-way merge) | § T.5 below |
| `mobile-only / 1.0.0` | `mobile-pwa-first / 2.0.0` | **cross-archetype** | `bin/forge-migrate-mobile-pwa.sh` | § B.9 below |

The T.5 row is same-archetype and, by the boundary above, would belong in
`MIGRATIONS.md`. It stays here : it is a shipped artefact and
`constitution-linter.sh:1196` points a live `transport-codegen-coverage` WARN at
this file. Recording the anomaly in the table costs a column ; moving the section
would break a pointer adopters already follow.

---

## B.9 — mobile-only 1.0.0 → mobile-pwa-first 2.0.0 (cross-archetype)

Adds the Qwik PWA surface to an existing Flutter `mobile-only` install. The native
tree is not touched — not merged, not rewritten, not reformatted.

**Status** : the driver ships and works ; the target schema does not yet.
`mobile-pwa-first / 2.0.0` is `stage: candidate` / `scaffoldable: false`, so
`forge init --archetype mobile-pwa-first` refuses at exit 3 while
`bin/forge-migrate-mobile-pwa.sh` succeeds. That asymmetry is deliberate and
temporary — **B.9.11** is the promotion gate that flips it. Until B.9.11 lands,
treat this as a preview : a migrated project is correct, but it targets a schema
the framework has not committed to.

### Why `forge upgrade` cannot do this

`forge upgrade` resolves a *version* within an archetype. This jump changes the
archetype, so there is no version for it to resolve : the source project's
`.forge/` carries `mobile-only`, and nothing in the upgrade path maps that onto
`mobile-pwa-first`. The `dispatch-table.yml` entry records the relationship
(`status: legacy_alias`, `target: mobile-pwa-first`) and names this script as the
way across.

### Invocation

Inspect the plan first — `--dry-run` prints every file it would write and mutates
nothing :

```bash
bash bin/forge-migrate-mobile-pwa.sh --target . --dry-run
bash bin/forge-migrate-mobile-pwa.sh --target .
```

If the target already holds one of the files below, the migration refuses rather
than overwriting. `--force` overrides that, and overwrites :

```bash
bash bin/forge-migrate-mobile-pwa.sh --target . --force
```

### What it adds

**26 files added, 0 modified** — measured by rendering both archetypes from
identical inputs and diffing, then again by hashing a real target's tree before
and after :

| what | count |
|---|---|
| `web-pwa/` — the Qwik City surface, service worker, Web Push client, OIDC browser client | 23 |
| `oidc-provider.json` — the issuer declaration, shared by both surfaces | 1 |
| `.github/workflows/web-pwa-ci.yml` — a second CI workflow, filtered on `web-pwa/**` | 1 |
| `.forge/scaffold-manifest.yaml` — which a `mobile-only` install never had | 1 |

Everything arrives **rendered**, through the same `overlay.sh` a fresh
`forge init` uses. No `.tmpl` file and no unsubstituted `<project-name>` reaches
your project.

### What stays untouched

Every file that existed before the migration is byte-identical after it. Not "the
migration tries not to modify them" — the harness hashes the tree before and
after and compares (`b9-2.test.sh::T-026`).

Stronger still : a migrated tree is byte-identical to a native
`forge init --archetype mobile-pwa-first` render of the same project, with exactly
one exception — `.forge/scaffold-manifest.yaml`, which differs in three fields
(`scaffold_date`, `scaffold_plan_sha`, `template_set_sha`) because the migration
rendered a 25-entry filtered plan rather than the archetype's full 73-entry one.
`archetype`, `archetype_version`, `project_name`, `reverse_domain` and
`root_module` all match.

That is not luck. `mobile-only`'s single `app` layer maps 1:1 onto
`mobile-pwa-first`'s, same id and same path (`ADR-B9-1-004`), so the migration
*cannot* need to rewrite native files. The prediction came first ; the numbers
above are the measurement that was taken before the design relied on it.

### Where the substitution values come from

A `mobile-only` install has no `.forge/scaffold-manifest.yaml`, so there is
nothing to read them out of. Both are derived from the project itself :

| value | read from |
|---|---|
| `project_name` | `pubspec.yaml`'s `name:` |
| `reverse_domain` | `android/app/build.gradle.kts`'s `namespace = "..."` |

Deriving is also more correct than a stored value would be : if you changed your
`applicationId` after scaffolding, the Gradle file is what your build actually
uses. If either cannot be read — a `namespace` set from a variable rather than a
literal, say — the migration stops at exit 7 naming the file. It never substitutes
an empty string.

### Exit codes

| code | condition |
|---|---|
| exit 0 | migration applied, or `--dry-run` completed |
| exit 2 | usage error — no `--target`, or an unknown flag |
| exit 5 | a required tool is missing (`python3`) |
| exit 7 | precondition not met — target is not a directory, has no `pubspec.yaml`, has no `android/app/build.gradle.kts`, or **already has `web-pwa/`** |
| exit 8 | **collision** — a file the migration would write already exists, and `--force` was not given |

The last two are the deliberate refusals. Running the migration twice hits exit 7
on the second run : an additive migration has nothing to converge to, so stopping
is the honest behaviour rather than re-rendering over your work.

### After the migration

Three things the framework cannot do for you :

1. `cd web-pwa && npm install && npm run build` — the surface ships with pinned
   dependencies but no lockfile resolution.
2. Review `oidc-provider.json`. It declares the issuer for **both** surfaces ; the
   Flutter client and the browser client must agree on it.
3. `.github/workflows/web-pwa-ci.yml` is a **second required check**. Branch
   protection does not pick it up on its own — add it, or a pull request that
   rewrites the whole PWA surface merges with nothing having run. (That is the
   exact gap B.9.7 was opened to close on the archetype side.)

### What `forge upgrade` will not do afterwards

`.forge/framework-owned-paths.yml` names nothing under `web-pwa/`. So framework-side
improvements to the Qwik surface will **not** 3-way-merge into your project on a
later `forge upgrade` — you own that subtree outright, and you keep every change you
make to it.

This is inherited, not introduced : `mobile-pwa-first / 2.0.0` ships the same
`framework-owned-paths.yml` as `mobile-only` (byte-identical, `sha256
a9a7921e…`), so a project created by a fresh `forge init` is in exactly the same
position. Recorded as an open question on `b9-10-migration-paths` rather than
silently patched — widening framework ownership changes what every future upgrade
writes into adopter projects, and that needs its own change.

### Rollback

The script has no rollback flag — deliberately. `forge-migrate-flagship.sh` needs
one because it rewrites existing files and restores from a frozen snapshot ; this
migration only adds, so undoing it is deleting what it added :

```bash
rm -rf web-pwa oidc-provider.json .github/workflows/web-pwa-ci.yml
rm -f .forge/scaffold-manifest.yaml
```

Remove the manifest only if you are going back to `mobile-only` for good : a
`mobile-only` install has none, so leaving it behind would describe a surface that
is no longer there. Nothing else needs undoing, because nothing else was changed.

---

## T.5 — Connect codegen additive (v0.3.x → v0.4.0-rc.x)

**Status** : in flight on branch `t5-connect-codegen` (planned status,
21/25 tests GREEN at the time of writing).

**Scope** : the `full-stack-monorepo / 1.0.0` archetype is extended
**additively** with Connect-RPC codegen alongside the existing tonic
gRPC + Kong-bridge REST path. **No path is retired** in T.5 — the
breaking codec swap (and Kong → Envoy, Temporal → DBOS, etc.) ships
in B.8 (T6).

### What `forge upgrade` adds

After this change archives, an adopter running `forge upgrade` against
a project scaffolded from `full-stack-monorepo / 1.0.0` (v0.3.x) gets :

- **`shared/protos/buf.gen.yaml`** receives 3 new entries via 3-way
  merge :
  - `buf.build/connectrpc/go:v1.19.2` — Go forward-compat for B.6/B.7.
  - `buf.build/bufbuild/es:v2.2.0` — Connect v2 / Protobuf-ES v2 (TS).
  - `buf.build/connectrpc/dart:v1.0.0` — official ConnectRPC Dart
    plugin (replaces the abandoned `skadero/connect-dart-community`).
- **`.gitignore`** receives `backend/crates/grpc-api/src/generated/connect/`
  + `frontend/lib/generated/connect/` (the generated stubs are NOT
  committed — `task proto` regenerates them).
- **`.forge/standards/transport.yaml`** is bumped 1.0.0 → 1.1.0 with
  a new `codegen.versions:` map pinning the 11 toolchain components
  (buf, protoc-gen-connect-go, protoc-gen-es, connectrpc-dart,
  connectrpc/buffa/buffa-types/connectrpc-build pinned `=0.3.3` —
  `WAIVER` documented inline).

### What stays untouched

- **The Kong-bridge REST path is preserved**. Existing REST routes
  served via Kong remain bound to their tonic gRPC backends ; the
  Connect adapter is mounted in **parallel** under `/connect`.
- **The tonic gRPC server bind is unchanged** (ADR-004 KEEP). Adopters
  who only consume gRPC continue to work.
- **The application + domain layers are untouched**. The Connect
  adapter is a transport-only concern under
  `backend/crates/grpc-api/src/transport_connect.rs`.
- **`framework-owned-paths.yml` is NOT extended** with the Rust crate
  paths. Adopter-owned files (`backend/crates/grpc-api/Cargo.toml`,
  `build.rs`, `src/transport_connect.rs`, `bin-server/src/main.rs`)
  are NOT propagated by future `forge upgrade` runs (per
  ADR-T5-006). Adopters who modify these files keep their changes.
  A future T.5+ amendment of these `.tmpl` will not flow downstream
  via 3-way merge — adopters must re-scaffold or patch manually.

### Linter rule `transport-codegen-coverage` (WARN-only)

A new section in `.forge/scripts/constitution-linter.sh` walks the
project for any `proto/` or `protos/` directory and emits a single
WARN line if no sibling `gen/connect/` tree exists, pointing here.

The rule is **WARN-only — never blocking**. Opt out via
`FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1` if you have a reason to keep
proto contracts without Connect codegen during the v0.3.x → v0.4.0-rc.x
window (e.g. mid-migration projects, single-language consumers).

### Codec coverage on day 1

The `connectrpc` crate (Anthropic OSS, `=0.3.3`) multiplexes :

- `application/connect+json` (HTTP/1.1 + HTTP/2)
- `application/connect+proto` (HTTP/1.1 + HTTP/2)
- `application/grpc` (HTTP/2)
- `application/grpc-web` (HTTP/1.1 + HTTP/2)

…all on the **same handler**. The `application/connect+json` HTTP/1.1
codec — originally deferred to B.8 — ships immediately with this
change.

### Pre-1.0 risk for `connectrpc=0.3.3`

The crate is < 30 days old at the time of pinning (waiver justified
by 6 558 conformance tests + Anthropic OSS pedigree + exact pin —
see `transport.yaml` inline `WAIVER` block). If a 0.4.x lands before
B.8 (T6), evaluate bump vs stay via a new `transport.yaml` review
entry.
