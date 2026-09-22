# Design — `t8-codegen-render-builds`

## Why the guards come first

Three assertions were supposed to cover this and could not fail:

- `T-B05` greps for the literal `from "./generated/connect/rag_pb"` — it asserts the very
  string that is wrong, so it has passed since the template was written.
- `T-C02` treats any buf failure matching `network|connect|resolve|timeout|BSR|buf\.build|
  offline|dial tcp` as offline and returns 0. The go_package error names
  `buf.build/connectrpc/go`: it matches on `buf.build` **and** on `connect`.
- `T-C04` returns 0 on every path after four `command -v` checks.

So the fix is written second, deliberately: each guard is rewritten to fail on the current
templates first. A guard that goes green the moment it is written has proved nothing —
this repository has paid for that lesson repeatedly.

## The two buf changes

```yaml
managed:
  enabled: true
  override:
    - file_option: go_package_prefix
      value: <reverse-domain>/<project-name>/gen/go
plugins:
  - remote: buf.build/community/neoeinstein-tonic:v0.4.0
    opt:
      - no_include=true          # buf isolates plugin outputs; the include would
                                 # reference the prost file tonic cannot see
```

The value uses the placeholders `overlay.sh` already substitutes, so each project gets a
path of its own. It is not a resolvable module path — no scaffold default is — but it is
well-formed, unique per project, and honest about ownership. A shared literal would put
every adopter's generated Go under the same import path.

## `T-C02`, failing closed without becoming flaky

The offline escape exists for a real reason: the BSR is remote and rate-limits. Two
failures must stay distinguishable:

- **transport** — `dial tcp`, `timeout`, `resolve`, `connection refused`, and BSR
  `resource_exhausted: too many requests` — SKIP, as today.
- **plugin** — buf's own `plugin <name>: …` prefix — FAIL.

The discriminator is therefore the *shape* of buf's message, not a keyword list that
`buf.build` and `connect` happen to match. Tested against both: the go_package error and
the tonic error must FAIL; a simulated rate-limit message must still SKIP.

## `T-C04`, given a body

After `T-C02`'s render and generate, install the rendered web surface and run
`tsc --noEmit` on it. `harness-rust` already provides node and buf, so this costs no
`forge-ci.yml` line. It genuinely SKIPs only when node or npm is absent — the dev-host
case — and that SKIP says which command was missing rather than claiming the work happens
elsewhere.

## Example trees

`forge-rag-example` and `forge-eda-example` receive the substituted template output, per
ADR-T8ETP-001. `forge-fsm-example` is a render of the frozen 1.0.0 tree and does not move
(ADR-T8CRB-002); `b8-9::T-010`'s frozen guard and the `forge upgrade` BASE contract both
depend on that.

## Verification

1. Guards RED on the current templates, each naming the real cause.
2. Templates and examples fixed; guards GREEN.
3. Real renders through each wrapper: `buf generate` rc=0; on the two web surfaces
   `npm install`, `tsc --noEmit`, `vite build` rc=0 with no shim.
4. Mutation probes on every new assertion.
5. Full `forge-ci` replay on the committed tree.
