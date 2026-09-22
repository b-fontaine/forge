# Evidence — `t8-codegen-render-builds`

2026-09-22. buf 1.72.0 (CI uses 1.70.0), node v26.8.1 / npm 12.0.2. Every render, install
and generate ran in a scratch directory outside the repository.

---

## P-1 — `buf generate` fails on every archetype that ships protos

Proto trees copied out with the scaffold placeholders substituted, then `buf generate`:

| archetype | rc | error |
|---|---|---|
| `ai-native-rag/1.0.0` | 1 | `Please specify either: a "go_package" option … or an "M" argument` |
| `event-driven-eu/1.0.0` | 1 | identical |
| `full-stack-monorepo` 1.0.0 base + 2.0.0 overlay | 1 | identical |

Q-005 recorded this as an `ai-native-rag` defect. It is a configuration-wide one: no proto
in the repository declares `option go_package`, and
`grep -rn 'go_package\|go_package_prefix' .forge/templates examples` returns nothing, while
all four `buf.gen.yaml` variants run `buf.build/connectrpc/go` under `managed: enabled`.

## P-2 — the first fix uncovers a second, independent failure

With the documented managed override added (Context7 `/bufbuild/buf`, the shape its README
shows), the go_package error disappears on all three — and a different one appears:

```
Failure: plugin buf.build/community/neoeinstein-tonic:v0.4.0: read rag.v1.rs: file does not exist
```

Isolated:

```
prost alone  -> rc=0, writes rag.v1.rs
tonic alone  -> rc=1, same "read … file does not exist"
```

buf gives each plugin its own output; the tonic plugin's generated include references the
prost file, which it cannot see — sharing an `out:` does not help, and the shipped config
already shares one.

`opt: no_include=true` → **rc=0**, writes `rag.v1.tonic.rs` (15.1 KB of service code).
Measured alternatives: bare `no_include` also rc=0; `compile_well_known_types=false` rc=1.

## P-3 — both fixes together, on all three

```
ai-native-rag   full_chain_rc=0
event-driven-eu full_chain_rc=0
full-stack-monorepo (base+2.0.0) full_chain_rc=0
```

Produced: `<pkg>.rs` (prost) + `<pkg>.tonic.rs` (tonic) + Go Connect stubs
(`ragv1connect`, `examplev1connect`) + Dart (flagship) + the TS descriptors.

With the placeholder-derived value `io.forge.example/forge-rag-example/gen/go` — the
`<reverse-domain>/<project-name>/gen/go` form rendered with the rag example's real
manifest values — buf accepts it and the Go stubs carry `package ragv1connect`.

## P-4 — the TS import, and why only one option survives

`protoc-gen-es` documents no flattening: `foo/bar.proto` → `foo/bar_pb.ts`, options limited
to `target`, `import_extension`, `keep_empty_files`, `ts_nocheck`, `bootstrap_wkt`
(Context7 `/bufbuild/protobuf-es`). With `out:` at
`frontend/web-public/src/lib/generated/connect` and the proto at `v1/rag/rag.proto`, buf
can only write `generated/connect/v1/rag/rag_pb.ts`; the template imports
`./generated/connect/rag_pb`.

The flagship is wrong on both axes: it imports `GreeterService` from
`./generated/connect/greeter_pb`, while its only proto declares
`package example.v1; service ExampleService { rpc Ping(PingRequest) returns (PingResponse) }`
with fields `payload` / `reply`. A path-only edit would still not compile.

(Filled further at T4.)

## P-5 — the guards RED on the shipped templates, before any fix

Rewritten first, deliberately. `b7-6 --level 1,2` against the unmodified templates:

```
FAIL T-B05: connect-client.ts does not import "./generated/connect/v1/rag/rag_pb" …
FAIL T-C02: buf generate failed on rendered proto — a PLUGIN failed, which is a defect
            in the shipped codegen config, not an outage
FAIL T-C04: buf generate failed — a plugin failed, so the descriptor the client imports
            was never written
Passed: 32 · Failed: 3
```

Each had previously been incapable of failing: `T-B05` grepped for the literal it was
supposed to validate, `T-C02` read the plugin failure as an outage, `T-C04` returned 0
down every path.

## P-6 — the discriminator, unit-tested on five logs

`_b76_buf_failure_is_transport` decides SKIP vs FAIL. Fed real and simulated logs:

| log | verdict |
|---|---|
| `plugin "buf.build/connectrpc/go:v1.20.0" exited with non-zero status 1` (the real go_package failure) | FAIL |
| `plugin buf.build/community/neoeinstein-tonic:v0.4.0: read rag.v1.rs: file does not exist` (the real tonic failure) | FAIL |
| `resource_exhausted: too many requests` (BSR rate limit) | SKIP |
| `failed to resolve …: dial tcp …: i/o timeout` | SKIP |
| an unrecognised message | FAIL |

Order matters: a plugin that ran and failed is decided before any keyword sweep, because
plugin names contain both `buf.build` and `connect` — the two words the old pattern used
to call an outage.

## P-7 — GREEN, on real renders of all three archetypes

| archetype | evidence |
|---|---|
| `ai-native-rag` | `b7-6 --level 1,2` **35/35, zero SKIP lines in the whole run** — so `T-C02` and `T-C04` genuinely rendered, generated, `npm install`ed and typechecked |
| `event-driven-eu` | `b6-7 --level 1,2` **36/36** |
| `full-stack-monorepo` 2.0.0 | rendered base + 2.0.0 overlay by hand: `buf generate` rc=0, writing exactly `generated/connect/v1/example/example_pb.ts`; `npm install` rc=0; `tsc --noEmit` rc=0; `vite build` rc=0 (`✓ built in 2.50s`) |

No shim, no hand-edit: the two web surfaces typecheck as scaffolded, which neither did.

## P-8 — mutation probes

| probe | result |
|---|---|
| the rag import reverted to the old literal | RED |
| the proto moved `v1/rag` → `v2/rag` | RED, **and the expectation followed it** (`…/v2/rag/rag_pb`) — the guard derives, it does not pin |
| `managed.override` `go_package_prefix` deleted | RED via `T-C02`, and **not** a SKIP |
| tonic `no_include=true` dropped | **INCONCLUSIVE** — see below |

The fourth probe returned SKIP rather than FAIL. Checked rather than assumed: a bare
`buf generate` at that moment returned `Failure: resource_exhausted: too many requests`
— the BSR was rate-limiting after the many generates these measurements required. So
`T-C02` classified a genuine transport failure as transport, which is the designed
behaviour; the probe simply could not reach the tonic failure. The FAIL path for that
exact message is covered by P-6's second row. Re-run it when the limit clears rather than
treating this row as proven.

Every file restored byte-identical (sha256), baseline `b7-6 --level 1` back to 0 failures.

## P-9 — review round 1 (2026-09-22): two blocking findings, one of them against this brick's own ADR

An independent guard lane returned **CHANGES REQUIRED**. Four findings, all reproduced by
the reviewer before I touched anything.

### (a) BLOCKING — a fresh `forge init` of the stable flagship never saw the fix

`scaffold-plan-2.0.0.yaml:174` reads `source: shared/protos/buf.gen.yaml.tmpl` — no
`2.0.0/` prefix, unlike its neighbours. The 2.0.0 plan **inherits** the 1.0.0 manifest, so
`forge init --archetype full-stack-monorepo`, the stable default path, renders the file
this brick had excluded as "frozen". The reviewer rendered the real plan through
`overlay.sh` and measured the result: `grep -c go_package_prefix` = 0, `grep -c no_include`
= 0, and the Go plugin still pinned at v1.19.2. FR-T8CRB-001 was unmet on the archetype's
own default path while the CHANGELOG, roadmap and plan all said the flagship was fixed.

My own P-7 said the flagship row was produced "rendered base + 2.0.0 overlay by hand" — by
its own words, not through the path an adopter uses.

### (b) BLOCKING — the ADR's rationale for the freeze was false

ADR-T8CRB-002 justified leaving the 1.0.0 manifest alone because "that tree is the BASE
`forge upgrade` three-way-merges against". Checked at the source:
`bin/forge-upgrade.sh:277-286` recovers BASE from
`.forge/scaffold-snapshots/<archetype>/<from>.tar.gz`, the committed snapshot tarball —
never from the live template tree. Editing the template changes RIGHT, which is the side a
fix belongs on. Plausible, unverified, and wrong.

**Both fixed by reversing the decision**: the 1.0.0 manifest now carries the override and
`no_include=true`, and `examples/forge-fsm-example`'s render was regenerated from it.
`b8-9::T-010`'s frozen guard checks only for a `B.8.9` annotation and stays green (14/14).

### (c) MAJOR — the transport classifier called a real outage a defect

buf's actual offline message is `Failure: the server hosted at that remote is
unavailable.`, which matched none of my keywords, so the function fell through to FAIL —
turning every PR red during an outage with a message that misdirects the triage. The
reviewer produced it deterministically and without spending BSR quota, by pointing buf at
a dead `HTTPS_PROXY`. P-6's five-log table had never fed it buf's real offline shape: its
two SKIP rows were a rate limit and a hand-written `dial tcp` string.

### (d) BLOCKING in kind — T-C04 re-created the exact bug this brick removed

Its npm escape matched `registry` case-insensitively. Every npm **E404** body contains
`registry.npmjs.org`, so a renamed or unpublished dependency — a defect — would have been
waved through as an outage. Structurally identical to T-C02's old `buf.build` match. The
reviewer measured it, and measured two controls that correctly FAIL (ETARGET, ERESOLVE),
which is why only the 404 shape leaked.

Now anchored to npm's own error-code line. Re-tested on captured logs, no network needed:

| log | verdict |
|---|---|
| `npm error code E404` + `registry.npmjs.org/... Not found` | FAIL |
| `npm error code ETARGET` | FAIL |
| `npm error code ERESOLVE` | FAIL |
| `npm error code ETIMEDOUT` | SKIP |

And the buf classifier, re-tested on seven shapes including the reviewer's measured ones:
`the server hosted at that remote is unavailable`, its DNS variant, `unavailable: 503`,
`connection reset by peer` and `resource_exhausted` → SKIP; the real go_package and tonic
failures → FAIL.

### (e) MAJOR — T-C04 spent a second full four-plugin generate

It now generates the **es plugin alone**, reading its config from the rendered manifest:
it only needs the descriptor `tsc` resolves, and T-C02 already exercises the full chain.
That halves the remote calls, which matters because a BSR rate limit turns the leg into a
SKIP. That both live legs can skip together during a rate limit is inherent to
skip-on-transport and is recorded as Q-004.

## P-10 — the coupling the ADR reversal pulled in

Re-rendering `examples/forge-fsm-example/shared/protos/buf.gen.yaml` made four further
harnesses red on the uncommitted tree: `b8-12`, `b8-13`, `b8-14`, `b8-15`. The chain is
the one project memory records — the leaf is `b8-12::_test_b812_008_c1_gitclean_after`
and the other three are collateral through their coupling guards, so only the leaf was
worth reading:

```
git -C "$FORGE_ROOT_REAL" diff --quiet -- examples/forge-fsm-example/
```

It asserts the committed fsm example is not dirty — a side-effect guard on
`forge-migrate-flagship`, which must not touch that tree while it runs. A deliberate,
committed parity re-render satisfies it again once staged, exactly like `b7-7` and
`b6-8`'s "no uncommitted archetype edit" guards. Verified by the committed-tree replay in
P-11 rather than assumed.

## P-11 — regression on the committed tree (T6.1)

On commit `09e7bc8` (clean tree): `npm run bundle`, then all **82** harness entries parsed
from `forge-ci.yml` — **82/82 PASS**. Every one of the six reds seen on the uncommitted
tree (`b7-7`, `b6-8`, `b8-12`, `b8-13`, `b8-14`, `b8-15`) was an uncommitted-edit or
dirty-tree guard and is green once staged, which is what P-10 predicted and is now
measured rather than assumed. `verify.sh` RESULT: PASS. `constitution-linter.sh`
105 PASS / 0 FAIL. `forge-ci.yml` 421 lines, unchanged (NFR-T8CRB-001).
