# Tasks — `t8-codegen-render-builds`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — measure the failure before fixing it

- [x] **T1.1** `buf generate` on a rendered copy of each proto tree: all three fail on
      `go_package`. [Story: FR-T8CRB-001]
- [x] **T1.2** With the managed override added, the tonic plugin fails separately;
      prost alone rc=0, tonic alone rc=1. Two defects, not one.
      [Story: FR-T8CRB-002, FR-T8CRB-003]
- [x] **T1.3** Context7 `/bufbuild/buf` for the managed-override shape and
      `/bufbuild/protobuf-es` for the output layout — not from memory.
      [Story: FR-T8CRB-002, FR-T8CRB-004, NFR-T8CRB-002]

## T2 — RED (guards first, so the fix has something to satisfy)

- [x] **T2.1** Rewrite `b7-6::T-B05` to DERIVE the expected specifier from the es `out:`
      and the proto path. It must go RED on the current templates.
      [Story: FR-T8CRB-006]
- [x] **T2.2** Narrow `T-C02`'s offline escape so a plugin error fails. Against the
      current templates it must go RED with the real buf error, not SKIP.
      [Story: FR-T8CRB-007]
- [x] **T2.3** Give `T-C04` a body (install + `tsc --noEmit` on the rendered surface),
      skipping only when node/npm are absent. RED on the current template.
      [Story: FR-T8CRB-008]

## T3 — GREEN

- [x] **T3.1** The three live `buf.gen.yaml.tmpl`: managed override with the placeholder
      value, and tonic `no_include=true` with its reason.
      [Story: FR-T8CRB-002, FR-T8CRB-003]
- [x] **T3.2** `ai-native-rag` client import; flagship client realigned to
      `ExampleService`/`Ping` plus its `index.tsx.tmpl` consumer.
      [Story: FR-T8CRB-004]
- [x] **T3.3** The `forge-rag-example` and `forge-eda-example` copies, substituted from
      the templates. `forge-fsm-example` untouched.
      [Story: FR-T8CRB-005]

## T4 — prove it on real renders

- [x] **T4.1** Render each archetype with its real wrapper: `buf generate` rc=0.
      [Story: FR-T8CRB-001]
- [x] **T4.2** On the rendered `ai-native-rag` and flagship web surfaces: `npm install`,
      `tsc --noEmit`, `vite build` — all rc=0, **no shim**.
      [Story: FR-T8CRB-004]
- [x] **T4.3** Mutation-probe every new assertion, each naming its file; files restored
      byte-identical.
      [Story: NFR-T8CRB-003]

## T5 — records

- [x] **T5.1** CHANGELOG (Known-issues bullet narrowed), roadmap B.7 row and gap
      paragraph, plan §0.N; `t7-qwik-deps-refresh` Q-005/Q-006 answered with the five
      mandated fields.
      [Story: FR-T8CRB-009]

## T6 — regression

- [x] **T6.1** Full `forge-ci` replay on the committed tree, `verify.sh`,
      `constitution-linter.sh`, shellcheck, `forge-ci.yml` still 421 lines.
      [Story: NFR-T8CRB-001, NFR-T8CRB-003]

## Review round 1 (2026-09-22) — independent guard lane: CHANGES REQUIRED, 4 findings

- [x] **T8.1** Verify the reviewer's blocking claim at the source: `scaffold-plan-2.0.0.yaml`
      inherits the 1.0.0 manifest (64 sources, most without the `2.0.0/` prefix), and
      `forge-upgrade.sh:277-286` takes BASE from the snapshot tarball, not the template tree.
      [Story: FR-T8CRB-001, ADR-T8CRB-002]
- [x] **T8.2** Reverse ADR-T8CRB-002: fix the 1.0.0 manifest, re-render
      `examples/forge-fsm-example`'s copy; `b8-9::T-010` still 14/14.
      [Story: FR-T8CRB-001, FR-T8CRB-005]
- [x] **T8.3** Guard fixes: anchor T-C04's npm escape to npm's error-code line; add buf's
      measured remote-unavailable shapes to the transport classifier; generate only the es
      plugin in T-C04. Re-tested on 11 captured logs, no network.
      [Story: FR-T8CRB-007, FR-T8CRB-008, NFR-T8CRB-003]
- [x] **T8.4** Correct every record that repeated the false freeze rationale: the ADR, the
      proposal, FR-T8CRB-005, the CHANGELOG, plan §0.18, and Q-001.
      [Story: FR-T8CRB-009]

## Negative scope guard

- [x] **T7.1** Frozen `full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl` and
      `examples/forge-fsm-example` untouched; no plugin version moved; no guard satisfied
      by pinning the literal it should derive.
      [Story: NFR-T8CRB-002, ADR-T8CRB-002]
