<!-- Audit: B.8.9 (b8-9-qwik-web-public) -->
# Tasks: b8-9-qwik-web-public

TDD-ordered. Ten-file Qwik City skeleton (ADR-B89-002: `2.0.0/frontend/web-public/`
under the schema-aligned `frontend/` layer) + `web-frontend.yaml` v1.0.0 (first
web-frontend pin source) + 2.0.0 buf.gen manifest es out-path re-point (ADR-B89-004)
+ 2.0.0.yaml comment-only delivery annotation (ADR-B89-007). Qwik/Vite/Node pins
are verify-then-pin LIVE at Phase 0 (ADR-B89-001 final-re-verify clause; b8-coroot
lesson). The comment-only 2.0.0.yaml annotation keeps b8-3 17/17 + b8-3b 12/12
green (NFR-B89-003; ADR-B89-007). 1.0.0 frozen surfaces untouched (NFR-B89-002).
Subtree: exactly 10 files (≤ 15 budget; NFR-B89-012). Four `[VERIFY AT IMPLEMENT]`
carry items: Connect-ES v2 TypeScript API shapes, Qwik 1.20.0 component/hook shapes,
vite.config.ts shape, entry.ssr.tsx / root.tsx shapes — all resolved via Context7 /
official docs before any template file is written (Article III.4).

---

## Phase 0 — Verify-then-pin LIVE re-execution (Article III.4 + b8-coroot lesson)

Every task in this phase queries a live external registry or authoritative source.
Each result MUST be appended to `evidence.md` with: URL, HTTP response timestamp,
value recorded, and a one-line summary of what it proves. If any pin differs from
the design ADR values, record the updated pin, update `web-frontend.yaml` versions
accordingly, and continue. If any registry is unreachable or a package has been
removed, emit `[NEEDS CLARIFICATION: <detail>]` and STOP — do NOT proceed to
Phase 1 with unverified pins.

- [x] **T001** Re-query `@builder.io/qwik` dist-tags via npm registry API
  (`https://registry.npmjs.org/@builder.io/qwik`) to confirm the `latest` tag is
  still `1.20.0` (ADR-B89-001 design-phase P-01). Re-query `@builder.io/qwik-city`
  dist-tags to confirm `latest = 1.20.0` (P-02). Record both dist-tag values +
  access timestamp as evidence (P-01/P-02 re-verify). If the latest has advanced
  to a new 1.x patch (e.g., 1.20.1), update the caret pin in `web-frontend.yaml`
  versions and `package.json.tmpl` to `^<new-latest>` and record provenance (P-16+).
  If the latest has jumped to 2.x GA, emit `[NEEDS CLARIFICATION: Qwik 2.x GA
  detected — ADR-B89-001 decision point requires re-evaluation]` and STOP.
  [Story: FR-B89-001, FR-B89-043, NFR-B89-006, ADR-B89-001]

- [x] **T002** Re-query `@qwik.dev/core` and `@qwik.dev/router` dist-tags to
  confirm both are still beta-only (latest = 2.0.0-beta.35 or a newer beta, NOT GA
  — P-03/P-04). Re-confirm that `@qwik.dev/city` does NOT exist on npm (P-05 —
  the v2 router is `@qwik.dev/router`). Record all three outcomes + timestamps as
  evidence (P-03/P-04/P-05 re-verify). If `@qwik.dev/core` has gone GA, emit
  `[NEEDS CLARIFICATION: @qwik.dev/core GA detected — qwik_v2_watch block in
  web-frontend.yaml may need updating; ADR-B89-001 re-evaluation required]` and STOP.
  [Story: FR-B89-043, NFR-B89-006, ADR-B89-001]

- [x] **T003** Re-query `vite` dist-tags (`https://registry.npmjs.org/vite`) to
  confirm vite 8.x is still the live npm `latest` (P-08 design finding: 8.0.16).
  Re-fetch `@builder.io/qwik` 1.20.0 (or the re-verified version from T001)
  `peerDependencies.vite` field to confirm the peer range is still `">=5 <8"`
  (P-06). Compute the maximum stable vite satisfying the constraint: confirm it
  is still in the 7.x line (P-09: 7.3.5). Record the exact vite `latest` +
  peer constraint + max-satisfying value as evidence (P-06/P-08/P-09 re-verify).
  If the peer constraint has been widened to include vite 8.x, update the vite pin
  in `web-frontend.yaml` and `package.json.tmpl` and record provenance (P-16+).
  The Vite-8 trap comment in `web-frontend.yaml` and the README pitfall note MUST
  be updated if the constraint changes.
  [Story: FR-B89-043, ADR-B89-001, NFR-B89-006]

- [x] **T004** Re-verify the Node.js active LTS version from the official release
  schedule (`https://nodejs.org/en/about/previous-releases` or the machine-readable
  `https://nodejs.org/dist/index.json`). Confirm Node v24 is still Active LTS at
  implement time (P-10 design finding: Active LTS since 2025-10-28, maintenance
  2026-10-20, EOL 2028-04-30). Confirm Node v24 still satisfies Qwik 1.20.0
  `engines.node: ">=16.8.0 <18.0.0 || >=18.11"` (24 ≥ 18.11). Record the active
  LTS identity + timestamps (P-10 re-verify). If the active LTS has changed (e.g.,
  Node v26 now active LTS), update `.nvmrc.tmpl` content and the `pin_review_cadence`
  note in `web-frontend.yaml` accordingly and record provenance.
  [Story: FR-B89-050, FR-B89-051, ADR-B89-006, NFR-B89-006]

- [x] **T005** Resolve the **Connect-ES v2 TypeScript API shapes** via Context7
  (`mcp__context7__resolve-library-id` with "connectrpc/connect-es", then
  `mcp__context7__query-docs` with the resolved ID, querying for
  `createClient` / `createConnectTransport`) or the official connect-es docs
  (`https://connectrpc.com/docs/web/`). Capture and record verbatim:
  (a) The exact import path for `createConnectTransport` (is it from
      `@connectrpc/connect-web` or `@connectrpc/connect`?);
  (b) The exact import path for `createClient` (from `@connectrpc/connect`?);
  (c) The exact function signatures and usage pattern for a minimal unary call
      (transport creation → client creation → `client.sayHello({ name: "..." })`
      or equivalent);
  (d) Whether the generated service descriptor import uses `GreeterService` or
      another named export pattern (from `@bufbuild/protobuf` / `@bufbuild/protoc-gen-es`
      generated output with `target=ts`).
  Record as evidence (P-17 — Connect-ES v2 API shapes). If the shapes are unclear
  or conflicting, emit `[NEEDS CLARIFICATION: Connect-ES v2 createClient /
  createConnectTransport API shapes unresolved — see evidence.md P-17]` and STOP.
  These shapes populate `src/lib/connect-client.ts.tmpl` in Phase 4.
  [Story: FR-B89-020, FR-B89-022, FR-B89-023, ADR-B89-003, Article III.4]

- [x] **T006** Resolve the **Qwik 1.20.0 file shapes** for the four template files
  carrying `[VERIFY AT IMPLEMENT]` placeholders (design.md ADR-B89-002 / ADR-B89-003):
  (a) `vite.config.ts`: exact import from `@builder.io/qwik-city/vite` or equivalent;
      plugin function name (`qwikCity()` + `qwikVite()`? — verify via Context7
      `mcp__context7__resolve-library-id` with "qwikdev/qwik" or official
      `https://qwik.dev/docs/` / `https://qwik.dev/docs/guides/static-site-generation/`);
  (b) `src/entry.ssr.tsx`: minimal SSR entry point shape for qwik-city 1.20.0
      (`renderToStream` export pattern);
  (c) `src/root.tsx`: root component shape (QwikCity + RouterHead + RouterOutlet
      pattern; exact import paths);
  (d) `src/routes/index.tsx`: Qwik component shape — exact hook names
      (`component$`, `useSignal`, `useVisibleTask$` or `useTask$` — verify which
      are stable in 1.20.0) for a minimal component that calls the Connect client.
  Capture canonical minimal forms verbatim as evidence (P-18 — Qwik 1.20.0 file
  shapes). If any shape is unclear, emit `[NEEDS CLARIFICATION: Qwik 1.20.0
  <file> shape unresolved — see evidence.md P-18]` and STOP.
  [Story: FR-B89-008, FR-B89-022, FR-B89-023, ADR-B89-002, ADR-B89-003, Article III.4]

- [x] **T007** Re-read `b8-6.test.sh` T-003 coupling assertion to confirm it
  greps plugin NAME sentinels only (`bufbuild/es`, `connectrpc/go:v1.20.0`, etc.)
  and does NOT grep the `out:` path string (design.md CENTRAL FINDING; evidence.md
  P-14). Confirm no other test in `b8-6.test.sh` pins the string
  `../../frontend/lib/generated/connect/ts`. Record the confirmation (P-14 re-verify).
  If any b8-6 assertion is found to grep the out-path value, emit
  `[NEEDS CLARIFICATION: b8-6.test.sh T-003 now greps the out: path — ADR-B89-004
  safe-re-point finding invalidated]` and STOP before Phase 3.
  [Story: FR-B89-033, ADR-B89-004, NFR-B89-003]

---

## Phase 1 — Harness RED

Author `b8-9.test.sh` with ALL ~12 L1 assertions before any template, standard
creation, or schema annotation. Run immediately after authoring to confirm the
expected RED baseline. T-011 coupling guard (b8-3/b8-3b/b8-6) may pass immediately
(sibling harnesses are already green before any edit) — record which tests pass and
which fail.

- [x] **T008** Author `.forge/scripts/tests/b8-9.test.sh` (~12 L1 hermetic tests,
  mirror b8-7.test.sh structure: `--level` flag, `source _helpers.sh`,
  `run_test`, `print_summary`; set -uo pipefail). Include all twelve assertions
  per design.md Testing Strategy table (T-001..T-012):
  - T-001: `2.0.0/frontend/web-public/` directory exists
    (`[ -d "$WEB_PUBLIC_DIR" ]`; FR-B89-001/005)
  - T-002: All 10 required files present in the subtree — loop over:
    `package.json.tmpl`, `.nvmrc.tmpl`, `vite.config.ts.tmpl`,
    `tsconfig.json.tmpl`, `qwik.env.d.ts.tmpl`, `src/entry.ssr.tsx.tmpl`,
    `src/root.tsx.tmpl`, `src/routes/index.tsx.tmpl`,
    `src/lib/connect-client.ts.tmpl`, `README.md.tmpl`
    (FR-B89-002/081; ADR-B89-002)
  - T-003: Template file count ≤ 15 in the subtree
    (`find "$WEB_PUBLIC_DIR" -name "*.tmpl" | wc -l`; NFR-B89-012/082)
  - T-004: `package.json.tmpl` contains `@connectrpc/connect` AND
    `@connectrpc/connect-web` sentinels
    (`grep -qF '@connectrpc/connect'`; FR-B89-021/082)
  - T-005: `protoc-gen-connect-es` does NOT appear as an active (non-comment)
    reference in any template file in the subtree
    (`grep -rn 'protoc-gen-connect-es' "$WEB_PUBLIC_DIR" | grep -v '#'` →
    zero matches; FR-B89-024/083)
  - T-006: `.nvmrc.tmpl` contains `24` (the active LTS value re-verified at T004)
    (`grep -qF '24' "$WEB_PUBLIC_DIR/.nvmrc.tmpl"`; FR-B89-050/051/ADR-B89-006)
  - T-007: `web-frontend.yaml` `version:` field = `"1.0.0"` AND contains
    `versions:` block AND `default:` field present
    (`grep -qE '^version:[[:space:]]*"1\.0\.0"'` +
    `grep -qF 'versions:'` + `grep -qF 'default:'`; FR-B89-040/041/084)
  - T-008: `standards/index.yml` contains `web-frontend.yaml` reference AND
    `standards/REVIEW.md` contains a `| web-frontend.yaml | 1.0.0 |` ledger row
    (FR-B89-045/047/085)
  - T-009: `2.0.0.yaml` contains a B.8.9 delivery annotation comment
    (`grep -qE 'B\.8\.9.*delivered|delivered.*B\.8\.9'`; FR-B89-060/086/ADR-B89-007)
  - T-010: 2.0.0 `buf.gen.yaml.tmpl` contains `web-public/src/lib/generated/connect`
    (out-path re-pointed) AND `B.8.9 delta` bump-note present AND frozen 1.0.0
    manifest does NOT contain a `B.8.9` annotation
    (FR-B89-030/032/086; ADR-B89-004)
  - T-011: Coupling guards — `b8-3.test.sh --level 1` exit 0 +
    `b8-3b.test.sh --level 1` exit 0 + `b8-6.test.sh --level 1` exit 0
    (exit-code only, no output parse; NFR-B89-003/087)
  - T-012: `CHANGELOG.md` contains `b8-9-qwik-web-public` (whole-file grep —
    changelog-test lesson; FR-B89-087/NFR-B89-001)
  L1 budget ≤ 2 s, zero network/Docker/npm.
  [Story: FR-B89-080, FR-B89-081, FR-B89-082, FR-B89-083, FR-B89-084,
   FR-B89-085, FR-B89-086, FR-B89-087, NFR-B89-001]

- [x] **T009** Run `bash .forge/scripts/tests/b8-9.test.sh --level 1` → verify
  RED baseline. Expected fail: T-001..T-010, T-012 (no subtree, no standard, no
  annotation, no manifest edit, no CHANGELOG). Expected pass: T-011 (sibling
  coupling guards b8-3/b8-3b/b8-6 already GREEN before any edit). Record the
  exact pass/fail counts and confirm the RED baseline is as expected.
  [Story: FR-B89-080, Article I RED]

---

## Phase 2 — GREEN: web-frontend.yaml v1.0.0 + index.yml + REVIEW.md

Standard creation FIRST — `web-frontend.yaml` must exist on disk before the
2.0.0.yaml annotation adds a comment referencing it (resolves before b8-3 T-011
re-check). Use Phase 0 verified pins only.

- [x] **T010** Create `.forge/standards/web-frontend.yaml` v1.0.0 (first web-frontend
  pin source; ADR-B89-005). Content per design.md ADR-B89-005 shape:
  (a) J.7-valid frontmatter (gateway.yaml / identity.yaml model):
      `version: "1.0.0"`, `last_reviewed: 2026-06-02`,
      `expires_at: 2027-06-02` (12-month cycle — NOT `never`; web pins drift;
      `exception_constitutional: false` per FR-J7-020 coupling; FR-B89-041),
      `linter_rule: null` (advisory; FR-B89-041),
      `enforcement: { ci_blocking: false, pre_commit_hook: false }` (FR-B89-041);
  (b) `default: qwik-city` (ratifying ADR-005 ARCHITECTURE-TARGET.md:365-374;
      FR-B89-042);
  (c) `alternatives: [sveltekit]` (per ADR-005; FR-B89-042);
  (d) `forbidden: []`;
  (e) `rationale:` citing ADR-005 + AT:365-374 SEO/resumability/LCP/TTI —
      no fabricated benchmark figures, reference-only (FR-B89-042);
  (f) `versions:` map with Phase 0 T001/T003 verified pins (FR-B89-043):
      `qwik: "^<verified-1.x-latest>"` (`@builder.io/qwik` — P-01 re-verify),
      `qwik_city: "^<verified-1.x-latest>"` (`@builder.io/qwik-city` — P-02 re-verify),
      `vite: "<exact-7.x-pin>"` (EXACT pin — vite 8.x EXCLUDED by peer `>=5 <8`
      P-06/P-09 re-verify; include the Vite-8 trap PITFALL comment verbatim per
      design.md ADR-B89-005 shape);
      Cross-reference comments (NOT re-pins): `@connectrpc/connect ^2.0.0` and
      `@connectrpc/connect-web ^2.0.0` noting transport.yaml v1.3.0 owns these;
  (g) `qwik_v2_watch:` block (B.8.O watch-list precedent; ADR-B89-001):
      `{ status: future-option, requires: v2-ga,
         packages: ["@qwik.dev/core", "@qwik.dev/router"],
         observed: "<beta-version> (<date>, P-03/P-04, evidence.md)",
         note: "@qwik.dev/city does not exist (P-05). Router is @qwik.dev/router.
                Re-evaluate when v2 GA ships." }`;
  (h) `pin_review_cadence:` ISO 8601 (gateway.yaml / identity.yaml precedent;
      FR-B89-044): `qwik: "P30D"`, `qwik_city: "P30D"`, `vite: "P30D"`.
  Template variables use `<variable-name>` form only in template files, NOT in
  the standard itself. No secret material (NFR-B89-007).
  [Story: FR-B89-040, FR-B89-041, FR-B89-042, FR-B89-043, FR-B89-044,
   FR-B89-046, ADR-B89-005]

- [x] **T011** Append a `web-frontend.yaml` entry to `.forge/standards/index.yml`
  following the existing entry structure (trigger list + file reference). Include
  triggers at minimum: `qwik`, `web-public`, `connect-es`, `web frontend`,
  `qwik-city`, `sveltekit`, `vite`, `ssr`, `seo`, `web-frontend` (FR-B89-047).
  Mirror the entry format of sibling entries (gateway.yaml, identity.yaml,
  transport.yaml) observed in the file. The entry MUST reference `web-frontend.yaml`
  as the file name.
  [Story: FR-B89-047, ADR-B89-005]

- [x] **T012** Append a B.8.9 `Created` entry to `.forge/standards/REVIEW.md`
  (append-only ledger, Article XII; FR-B89-045). The row MUST contain
  `| web-frontend.yaml | 1.0.0 |` (FR-J7-023 anchor for harness T-008). Mirror
  the B.8.4 `gateway.yaml` and B.8.7 `identity.yaml` REVIEW.md precedents. Include:
  Reviewer @bfontaine, date 2026-06-02, decision Created, next review 2027-06-02,
  notes: "Birth: first web-frontend pin source — Qwik City default (ADR-005 ratification),
  @builder.io/qwik ^1.20.0 + vite =7.3.5 exact (Vite-8 excluded by peer >=5 <8),
  qwik_v2_watch future-option, pin_review_cadence P30D, expires_at 2027-06-02
  (exception_constitutional: false), enforcement off (Iris-Web/K.4 territory)."
  [Story: FR-B89-045, ADR-B89-005, Article XII]

- [x] **T013** Run `bash bin/validate-standards-yaml.sh .forge/standards/` in
  DIRECTORY mode → must exit 0 with `[STD-PASS] …web-frontend.yaml` line (among
  others). Confirms J.7 frontmatter validity (FR-J7-020 dated-expiry coupling +
  FR-J7-023 REVIEW.md row check run in dir context). Re-run
  `b8-9.test.sh --level 1` → T-007 and T-008 must now be GREEN. Record the new
  pass count.
  [Story: FR-B89-046, ADR-B89-005]

---

## Phase 3 — GREEN: 2.0.0.yaml comment-only delivered annotation

- [x] **T014** Edit `.forge/schemas/full-stack-monorepo/2.0.0.yaml`: add comment-only
  delivery annotation at two sites (ADR-B89-007; design.md §2.0.0.yaml Annotation):

  **Site 1** — `layers.frontend.surfaces[web-public]` entry (append the comment
  on the line after `note:`):
  ```yaml
        - id: web-public
          path: web-public/
          stack: qwik
          note: Qwik PWA — public-facing web; new in 2.0.0 (B.8.9)
          # B.8.9 — delivered; standard: web-frontend.yaml v1.0.0
  ```
  **Site 2** — `migration_deltas[no-web-public-layer]` entry (append the comment
  on the line after `strategy: additive-first`):
  ```yaml
    - from: no-web-public-layer
      to: qwik-web-public
      brick: B.8.9
      strategy: additive-first  # new web-public/ surface added alongside web-backoffice/
      # B.8.9 — delivered 2026-06-02
  ```
  YAML comments are transparent to `yaml.safe_load` — the parsed dict is
  byte-identical before and after. T-012 (forbidden keys `{version, pin, image}`)
  and T-015 (`^\d+\.\d+` scalar walk) in b8-3 are UNAFFECTED (ADR-B89-007
  safety proof). No new `standard:` YAML key added to the parsed structure
  (comment-only lean — FR-B89-062).
  [Story: FR-B89-060, FR-B89-061, FR-B89-062, FR-B89-063, ADR-B89-007]

- [x] **T015** Run `bash .forge/scripts/tests/b8-3.test.sh --level 1` → must
  exit 0 (17/17). Run `bash .forge/scripts/tests/b8-3b.test.sh --level 1` →
  must exit 0 (12/12). Any failure is a B.8.9 constitutional violation
  (NFR-B89-003). Re-run `b8-9.test.sh --level 1` → T-009 must now be GREEN.
  Record pass counts.
  [Story: NFR-B89-003, FR-B89-061, FR-B89-063]

---

## Phase 4 — GREEN: 2.0.0 buf.gen manifest es out-path re-point

- [x] **T016** Edit `.forge/templates/archetypes/full-stack-monorepo/2.0.0/shared/
  protos/buf.gen.yaml.tmpl` — the 2.0.0 standalone copy ONLY (1.0.0 manifest
  at `shared/protos/buf.gen.yaml.tmpl` MUST remain byte-unchanged; FR-B89-031):
  (a) Add bump-note comment in the header (FR-B89-032):
      `# B.8.9 delta: es plugin out-path re-pointed to web-public surface (ADR-B89-004).`
  (b) Change the `es` plugin `out:` value from
      `../../frontend/lib/generated/connect/ts`
      to `../../frontend/web-public/src/lib/generated/connect`
      (the new path resolves from `2.0.0/shared/protos/` → `../../` = `2.0.0/`
      → `frontend/web-public/src/lib/generated/connect`; no trailing `/ts`
      subdirectory needed since `target=ts` opt is explicit; ADR-B89-004).
  No other plugin or manifest key is changed.
  [Story: FR-B89-030, FR-B89-031, FR-B89-032, FR-B89-033, ADR-B89-004]

- [x] **T017** Confirm the 1.0.0 buf.gen manifest
  (`shared/protos/buf.gen.yaml.tmpl`) is unchanged: run
  `grep -F 'B.8.9' ".forge/templates/archetypes/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl"`
  → zero matches. Re-run `bash .forge/scripts/tests/b8-6.test.sh --level 1` →
  must exit 0 (coupling proof that the T-003 plugin-sentinel assertions are
  unaffected by the out-path re-point). Re-run `b8-9.test.sh --level 1` →
  T-010 must now be GREEN. Record pass counts.
  [Story: FR-B89-031, FR-B89-033, NFR-B89-002/003]

---

## Phase 5 — GREEN: web-public subtree (10 template files, ADR-B89-002)

Author all ten template files using Phase 0 verified pins and shapes. No 1.0.0
frozen file is touched (NFR-B89-002). All Connect-ES and Qwik API symbols MUST
be from Phase 0 T005/T006 live evidence — NOT from training data (Article III.4).
All files carry top-of-file audit comment + standard reference (FR-B89-003).
All template variables use `<variable-name>` angle-bracket form (FR-B89-004).

### G1 — package.json.tmpl

- [x] **T018** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/package.json.tmpl`. Content:
  (a) Top-of-file comment block (JSON comment via leading `//` or embedded in
      a `_comment` key per JSON5 convention, OR a shebang-style comment if the
      template processor supports it — use the convention observed in sibling
      `2.0.0/` template files):
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml` +
      `// NEVER PUT SECRETS HERE`;
  (b) `"name": "<project-name>-web-public"` (template var; FR-B89-004);
  (c) `"private": true`;
  (d) `"scripts":` matching the official Qwik City starter shape (P-11 re-verify at T006):
      at minimum `{ "start", "dev", "preview", "build", "qwik" }`;
  (e) `"dependencies":` — at minimum:
      `"@builder.io/qwik": "^<P-01-re-verified-version>"` (ADR-B89-001),
      `"@builder.io/qwik-city": "^<P-02-re-verified-version>"` (ADR-B89-001),
      `"@connectrpc/connect": "^2.0.0"` (transport.yaml v1.3.0 pinned fact;
      FR-B89-021; ADR-B89-003),
      `"@connectrpc/connect-web": "^2.0.0"` (transport.yaml v1.3.0 pinned fact;
      FR-B89-021; ADR-B89-003);
  (f) `"devDependencies":` — at minimum:
      `"vite": "=<P-09-re-verified-7.x-exact>"` (EXACT pin — vite 8 excluded;
      ADR-B89-001; Vite-8 pitfall comment inline);
  (g) NO `zod` dependency (ADR-B89-003 deferral; FR-B89-025).
  Harness T-004 asserts `@connectrpc/connect` + `@connectrpc/connect-web`
  sentinels; T-005 asserts `protoc-gen-connect-es` absent.
  [Story: FR-B89-001, FR-B89-002, FR-B89-003, FR-B89-004, FR-B89-021,
   FR-B89-024, FR-B89-025, ADR-B89-001, ADR-B89-003] [P]

### G2 — .nvmrc.tmpl

- [x] **T019** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/.nvmrc.tmpl`. Content:
  (a) Top-of-file audit comment lines (using `#` comment prefix):
      `# Audit: B.8.9 (b8-9-qwik-web-public)` +
      `# Standard: .forge/standards/web-frontend.yaml`;
  (b) Literal value `24` (Phase 0 T004 re-verified active LTS — NOT a template
      variable; the Node version is the decision, not a scaffold parameter;
      ADR-B89-006);
  (c) No other content. This is the minimal Node toolchain pin file consumed by
      `nvm use` / `fnm use` / `actions/setup-node --node-version-file .nvmrc`.
  Harness T-006 asserts `.nvmrc.tmpl` contains `24`.
  [Story: FR-B89-002, FR-B89-003, FR-B89-050, FR-B89-051, ADR-B89-006]

### G3 — vite.config.ts.tmpl

- [x] **T020** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/vite.config.ts.tmpl`. Content:
  (a) Top-of-file audit comments:
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml`;
  (b) Qwik City vite plugin import + `defineConfig` export using the exact
      import paths and function names resolved at Phase 0 T006 (P-18 — Qwik
      1.20.0 vite.config.ts shape; NOT fabricated; Article III.4);
  (c) Minimal configuration: only what the Qwik City 1.20.0 official starter
      requires — no adopter-specific overrides.
  If the exact shape was not fully resolved at T006, emit
  `[NEEDS CLARIFICATION: vite.config.ts shape for qwik-city 1.20.0 unresolved
  — see evidence.md P-18]` and STOP.
  [Story: FR-B89-002, FR-B89-003, FR-B89-008, ADR-B89-002] [P]

### G4 — tsconfig.json.tmpl

- [x] **T021** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/tsconfig.json.tmpl`. Content:
  (a) Top-of-file comment (JSON comment style):
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml`;
  (b) TypeScript config matching the official Qwik City 1.20.0 base starter shape
      (P-11 / P-18 — at minimum: `compilerOptions` with `target`, `module`,
      `moduleResolution`, `strict`, Qwik-specific lib entries);
  (c) Path alias for generated Connect descriptors (resolving
      `src/lib/generated/connect/*` — aligns with the ADR-B89-004 re-pointed
      buf.gen output at `src/lib/generated/connect/`).
  [Story: FR-B89-002, FR-B89-003, ADR-B89-002, ADR-B89-004]

### G5 — qwik.env.d.ts.tmpl

- [x] **T022** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/qwik.env.d.ts.tmpl`. Content:
  (a) Top-of-file audit comments:
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml`;
  (b) Qwik environment type declarations verbatim from the official Qwik City
      1.20.0 starter shape (P-11 — the `/// <reference types="vite/client" />`
      and any Qwik-specific type augmentations; no template variables needed for
      this file — it is a static type declaration file).
  [Story: FR-B89-002, FR-B89-003, ADR-B89-002]

### G6 — src/entry.ssr.tsx.tmpl

- [x] **T023** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/src/entry.ssr.tsx.tmpl`. Content:
  (a) Top-of-file audit comments:
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml`;
  (b) SSR entry point using the exact `renderToStream` export pattern for Qwik
      City 1.20.0 resolved at Phase 0 T006 (P-18 — entry.ssr.tsx shape; NOT
      fabricated; Article III.4). If the shape was not fully resolved at T006,
      emit `[NEEDS CLARIFICATION: entry.ssr.tsx shape unresolved]` and STOP.
  [Story: FR-B89-002, FR-B89-003, FR-B89-008, ADR-B89-002]

### G7 — src/root.tsx.tmpl

- [x] **T024** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/src/root.tsx.tmpl`. Content:
  (a) Top-of-file audit comments:
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml`;
  (b) Root component rendering QwikCity + RouterHead + RouterOutlet using the
      exact import paths and component names for Qwik City 1.20.0 resolved at
      Phase 0 T006 (P-18 — root.tsx shape; NOT fabricated; Article III.4).
  [Story: FR-B89-002, FR-B89-003, FR-B89-008, ADR-B89-002]

### G8 — src/routes/index.tsx.tmpl

- [x] **T025** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/src/routes/index.tsx.tmpl`. Content:
  (a) Top-of-file audit comments:
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml`;
  (b) Minimal Qwik landing-page component demonstrating one unary Connect call:
      imports the Connect client from `../lib/connect-client` (relative path
      from `src/routes/` to `src/lib/`); uses Qwik 1.20.0 stable hook names
      resolved at Phase 0 T006 (P-18 — `component$`, `useSignal`, and
      `useVisibleTask$` or equivalent stable hook; NOT fabricated; Article III.4);
  (c) Template variable `<project-name>` usable in page title or heading (FR-B89-004).
  If any hook name was not resolved at T006, emit
  `[NEEDS CLARIFICATION: Qwik 1.20.0 hook names unresolved for routes/index.tsx]`
  and STOP.
  [Story: FR-B89-002, FR-B89-003, FR-B89-008, FR-B89-022, ADR-B89-002,
   ADR-B89-003] [P]

### G9 — src/lib/connect-client.ts.tmpl

- [x] **T026** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/src/lib/connect-client.ts.tmpl`. Content:
  (a) Top-of-file audit comments:
      `// Audit: B.8.9 (b8-9-qwik-web-public)` +
      `// Standard: .forge/standards/web-frontend.yaml`;
  (b) Connect-ES v2 transport creation using the exact import path resolved at
      Phase 0 T005 (P-17 — `createConnectTransport` from `@connectrpc/connect-web`
      or the correct package per P-17; NOT fabricated; Article III.4);
  (c) Client creation using the exact import path for `createClient` resolved at
      T005 (P-17 — from `@connectrpc/connect`);
  (d) Import of the generated `GreeterService` descriptor from
      `../generated/connect/<GreeterService-file>` (relative from `src/lib/`
      to `src/lib/generated/connect/` — the ADR-B89-004 re-pointed output;
      exact descriptor file name from P-05 T005 live evidence or known buf.gen
      target=ts output conventions; ADR-B89-004);
  (e) One exported function demonstrating a unary `SayHello` call
      (FR-B89-022; ADR-B89-003);
  (f) Template variable `<api-url>` for the backend URL (FR-B89-004; Article XI.6
      — no credentials or hardcoded URLs; NFR-B89-007);
  (g) No `zod` import (ADR-B89-003 deferral; FR-B89-025).
  If any Connect-ES API symbol was not resolved at T005, emit
  `[NEEDS CLARIFICATION: Connect-ES v2 API shape unresolved for connect-client.ts]`
  and STOP.
  [Story: FR-B89-020, FR-B89-021, FR-B89-022, FR-B89-023, FR-B89-024,
   FR-B89-025, ADR-B89-003, ADR-B89-004, Article III.4, NFR-B89-007] [P]

### G10 — README.md.tmpl

- [x] **T027** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  frontend/web-public/README.md.tmpl`. Content sections (FR-B89-009):
  (a) Audit header (top-of-file; FR-B89-003):
      `<!-- Audit: B.8.9 (b8-9-qwik-web-public) -->` +
      `<!-- Standard: .forge/standards/web-frontend.yaml -->`;
  (b) Status block (prominently placed; FR-B89-074):
      `Status: candidate — scaffoldable: false until B.8.14`;
  (c) Delivery model: 2.0.0 candidate subtree introducing the web-public surface;
      `standard: web-frontend.yaml` policy-source reference; B.8.9 change context;
  (d) Janus arbitration section (FR-B89-070): Janus arbitrates `web-public` and
      `web-backoffice` surfaces for cross-layer changes until Iris-Web (K.4, T7 agent)
      ships; cite plan:2321 and ARCHITECTURE-TARGET.md:743 references;
  (e) Envoy Connect/HTTP path section (FR-B89-071):
      "The Qwik client makes Connect-protocol HTTP calls; Envoy Gateway (B.8.4)
      is the ingress (`AT C4: Rel(qwik, envoy)`). See
      `2.0.0/infra/k8s/envoy-gateway/` for the Envoy template.";
  (f) web-backoffice unchanged posture section (FR-B89-007/072):
      "The `web-backoffice` Flutter Web surface is unchanged by this brick.
      The 1.0.0 Flutter app already covers it. Any backoffice migration is
      B.8.10 / B.8.14 territory.";
  (g) Node toolchain setup section (FR-B89-052; ADR-B89-006):
      "This subtree ships `.nvmrc` (value: `24`, active LTS at 2026-06-02,
      re-verified at implement). Use `nvm use` / `fnm use` or
      `actions/setup-node --node-version-file .nvmrc` in CI. Node 24
      satisfies Qwik 1.20.0 `engines.node` (`>=18.11`). Re-verify the
      active LTS at each `pin_review_cadence` boundary (P30D; `web-frontend.yaml`).";
  (h) Vite 8 pitfall note:
      "PITFALL: vite 8.x is the npm `latest` but is EXCLUDED by
      `@builder.io/qwik` peerDependencies `>=5 <8`. Pin to `=<7.x-exact>` exactly
      (see `web-frontend.yaml` versions block for the current pin and ADR-B89-001).";
  (i) Connect-ES usage section: brief guide on the Connect client wiring;
      explicit note that `protoc-gen-connect-es` is retired by Connect v2 (FR-B89-024;
      ADR-B89-003) — correct codegen tool is `buf.build/bufbuild/es:v2.2.0`;
  (j) Zod deferral note (FR-B89-075; ADR-B89-003):
      "Connect-ES client + Zod schemas — deferred per ADR-B89-003 (protobuf-es
      types may suffice for the skeleton; revisit at B.9.2 or the next brick
      requiring client-side validation; AT:612 reference recorded).";
  (k) Scope out (this brick) section (FR-B89-073) listing each of:
      - PWA machinery (Service Worker, Web Push/VAPID, offline shell) → B.9.2
      - OIDC/PKCE Qwik client → B.9.3
      - OTel wiring from Qwik (`Rel(qwik, otel)` OTLP) → B.8.12/B.7
      - Streaming patterns (SSE/WebTransport/cancel-on-unmount) → B.7.10
      - Hosting tier rows (Cloudflare Pages/Vercel/OVH) → B.9.7
      - Iris-Web agent → K.4 (T7)
      - Adopter CI workflow for the web surface (forge-web.yml) → B.8.10 (lean defer);
  (l) Template variable reference: `<project-name>`, `<namespace>`, `<api-url>`
      (angle-bracket form per FR-B89-004);
  (m) `NEVER PUT SECRETS HERE` notice (NFR-B89-007) if any env-file or
      environment variable configuration is mentioned.
  [Story: FR-B89-003, FR-B89-004, FR-B89-007, FR-B89-009, FR-B89-024,
   FR-B89-025, FR-B89-070, FR-B89-071, FR-B89-072, FR-B89-073, FR-B89-074,
   FR-B89-075, ADR-B89-002, ADR-B89-003, ADR-B89-006, NFR-B89-007] [P]

### Subtree validation (implementation-phase, NOT an L1 harness gate)

- [x] **T028** Validate the authored subtree is well-formed:
  (a) Run `find .forge/templates/archetypes/full-stack-monorepo/2.0.0/frontend/web-public
      -name "*.tmpl" | wc -l` → must print exactly `10` (NFR-B89-012 file-count budget);
  (b) If node and npm are available locally: run `node --version` to confirm the
      environment satisfies Node ≥18.11; attempt a parse-only check (e.g.,
      `node -e "require('./package.json')"` after rendering the template with
      placeholder values) as an optional sanity step — skip-pass with a note if
      unavailable; do NOT block on npm install or tsc compilation (full build is
      adopter-side; FR-B89-005);
  (c) Confirm no `protoc-gen-connect-es` active reference across any subtree file
      (`grep -rn 'protoc-gen-connect-es' .../web-public/ | grep -v '#'` → zero
      matches; FR-B89-024/083).
  Record the file count and any sanity result (PASS or skip-with-note).
  [Story: FR-B89-002, FR-B89-024, NFR-B89-012]

---

## Phase 6 — GREEN: CHANGELOG + forge-ci.yml registration

- [x] **T029** Append a `## [Unreleased]` entry to `CHANGELOG.md` summarising
  the B.8.9 deliverables: `2.0.0/frontend/web-public/` Qwik City skeleton
  (10 files: package.json.tmpl + .nvmrc.tmpl + vite.config.ts.tmpl +
  tsconfig.json.tmpl + qwik.env.d.ts.tmpl + src/entry.ssr.tsx.tmpl +
  src/root.tsx.tmpl + src/routes/index.tsx.tmpl + src/lib/connect-client.ts.tmpl +
  README.md.tmpl), `web-frontend.yaml` v1.0.0 (first web-frontend pin source —
  Qwik City default, vite =7.3.5 exact, qwik_v2_watch, P30D cadence),
  2.0.0.yaml web-public surface comment-only delivered annotation,
  2.0.0 buf.gen manifest es out-path re-pointed to web-public surface (ADR-B89-004),
  harness b8-9.test.sh. Entry MUST contain the string `b8-9-qwik-web-public`
  (harness T-012 anchor — changelog-test lesson: grep whole file; NOT bare "B.8.9").
  Mirrors B.8.7 CHANGELOG precedent.
  [Story: FR-B89-087, NFR-B89-001]

- [x] **T030** Append `"b8-9.test.sh --level 1"` as a one-line entry to the
  `harnesses=()` loop in `.github/workflows/forge-ci.yml` after the
  `b8-7.test.sh --level 1` line (the last existing harness entry at line 113;
  FR-B89-080). Verify the CI file stays within the NFR-CI-002 ≤ 300-line budget
  (count lines after the append).
  [Story: FR-B89-080, NFR-CI-002]

---

## Phase 7 — Full harness GREEN

- [x] **T031** Run `bash .forge/scripts/tests/b8-9.test.sh --level 1` → must
  exit 0 with all 12/12 GREEN. Record the full output. Any failure is a
  constitutional violation (Article V). Confirm T-011 coupling guard shows
  b8-3 (17/17) + b8-3b (12/12) + b8-6 (12/12) all exiting 0.
  [Story: FR-B89-080..087, NFR-B89-001, NFR-B89-003]

---

## Phase 8 — Gates and sibling safety (NFR-B89-004 full-suite-before-push lesson)

Run all gates. A partial sweep is insufficient — sibling scans can break silently
(b8-4/b8-5/b8-6 lessons; `full_harness_suite_before_push` project memory;
`shared-standard sibling-harness coupling` memory). Repo-wide scans MUST skip
`2.0.0/` subtrees (N.N.N/ convention). Sibling version-pin scan: grep all
harnesses for any that reference `web-frontend.yaml` or `qwik` or the buf.gen
out-path — those must still pass.

- [x] **T032** Run `bash bin/validate-standards-yaml.sh .forge/standards/` in
  DIRECTORY mode → must exit 0 with `[STD-PASS] …web-frontend.yaml` line (among
  others). Confirm `| web-frontend.yaml | 1.0.0 |` REVIEW.md anchor satisfies
  FR-J7-023 (J.7 drift check runs in dir context).
  [Story: FR-B89-046, NFR-B89-004]

- [x] **T033** Run `bash bin/verify.sh` → must exit 0 (PASS). Record output.
  [Story: Article V]

- [x] **T034** Run `bash bin/constitution-linter.sh` → must exit 0. Record output.
  [Story: Article V]

- [x] **T035** Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-9-qwik-web-public/.forge.yaml` → must exit 0.
  [Story: Article V]

- [x] **T036** 1.0.0 byte-identity check: run
  `bash .forge/scripts/tests/b8-2.test.sh --level 1` → exit 0 (confirms 1.0.0
  templates, schema.yaml, and 1.0.0.tar.gz are byte-unchanged; the frozen
  1.0.0 `shared/protos/buf.gen.yaml.tmpl` is also byte-unchanged; NFR-B89-002).
  [Story: NFR-B89-002, FR-B89-006, FR-B89-031]

- [x] **T037** Run b8-3 and b8-3b one final time post all edits:
  `bash .forge/scripts/tests/b8-3.test.sh --level 1` → 17/17.
  `bash .forge/scripts/tests/b8-3b.test.sh --level 1` → 12/12.
  [Story: NFR-B89-003, FR-B89-061]

- [x] **T038** Sibling version-pin and web-frontend scan: grep all harnesses in
  `.forge/scripts/tests/` for any that reference `web-frontend.yaml`, `qwik`,
  or the buf.gen out-path string. If any harness hard-pins the buf.gen out-path
  (other than b8-6 T-003 which greps plugin NAME sentinels), confirm it stays
  GREEN after the ADR-B89-004 re-point. Run any affected harnesses to confirm
  they exit 0.
  [Story: NFR-B89-004, `shared-standard sibling-harness coupling` lesson]

- [x] **T039** Run the FULL ~48-harness suite (all `*.test.sh` in
  `.forge/scripts/tests/`). Verify each harness exits 0 or is marked as
  expected-fail in forge-ci.yml. Pay special attention to any harness whose
  repo-wide scan might pick up the new `2.0.0/frontend/web-public/` subtree or
  the new `web-frontend.yaml` standard (delivery.test.sh, scaffolder.test.sh,
  b8-3.test.sh, b8-3b.test.sh, b8-4.test.sh, b8-5.test.sh, b8-6.test.sh,
  b8-7.test.sh) — versioned `N.N.N/` subtrees are exempt from repo-wide scans
  per the scaffolding.md convention. Any regression is a blocker.
  [Story: NFR-B89-004]

- [x] **T040** Neutralize any `[NEEDS CLARIFICATION:]` markers remaining in
  `specs.md` that were resolved by the ADRs (design phase) and by Phase 0 live
  evidence. Reword each `[NEEDS CLARIFICATION: ...]` block to a
  `Resolved by ADR-B89-NNN: <summary>; see evidence.md P-XX` statement
  (b8-coroot lesson: no open `[NEEDS CLARIFICATION:]` in finalized specs before
  status flip to `implemented`). Do NOT modify plan files (`.omc/plans/*.md`).
  [Story: Article III.4, NFR-B89-010]

---

## Phase 9 — Wrap-up (b8-coroot lesson + T5.2 lesson)

- [x] **T041** Flip `.forge/changes/b8-9-qwik-web-public/.forge.yaml` status
  `planned → implemented` AND add `timeline.implemented: <YYYY-MM-DD>`.
  **Re-run Phase 8 gates POST status flip** (b8-coroot lesson: gates must be
  re-run AFTER the flip, not trusted from pre-flip run). Specifically re-run:
  `b8-9.test.sh --level 1`, `b8-3.test.sh --level 1`, `b8-3b.test.sh --level 1`,
  `b8-6.test.sh --level 1`, `validate-standards-yaml.sh` dir-mode,
  `validate-change-yaml.sh`.
  [Story: Article V, NFR-B89-011, b8-coroot lesson]

- [x] **T042** Independent review pass (separate lane — author MUST NOT
  self-approve; NFR-B89-010; T5.2 self-validation lesson). The independent
  reviewer MUST re-execute (not trust the transcript):
  `b8-9.test.sh --level 1` (12/12), `b8-3.test.sh --level 1` (17/17),
  `b8-3b.test.sh --level 1` (12/12), `b8-6.test.sh --level 1` (12/12),
  `validate-standards-yaml.sh` dir-mode, `b8-2.test.sh --level 1` (frozen sha256
  guard), and the `[NEEDS CLARIFICATION:]` neutralization check on `specs.md`.
  Record the reviewer's name and run timestamp in the change record.
  [Story: NFR-B89-010, Article V.2, T5.2 lesson]

- [x] **T043** Archive prep: verify all tasks marked complete, run
  `/forge:archive b8-9-qwik-web-public` to flip status `implemented → archived`
  after the independent review PASS. Confirm the B.9.2 / B.9.3 / B.8.12 / B.7.10
  next-brick dependency chain is noted (ADR-B89-003 Zod deferred to B.9.2;
  ADR-B89-003 OTel wiring to B.8.12/B.7; ADR-B89-003 OIDC PKCE to B.9.3;
  Iris-Web/K.4 standard governance handoff pending).
  [Story: Article V, ADR-B89-003, ADR-B89-006]

---

## FR-B89-* / NFR-B89-* Coverage Table

All 49 FRs + 12 NFRs covered.

| FR / NFR | Task(s) |
|----------|---------|
| FR-B89-001 | T008 (T-001), T018, T031 |
| FR-B89-002 | T008 (T-002/T-003), T018..T027, T028, T031 |
| FR-B89-003 | T018..T027 (audit comments on all files) |
| FR-B89-004 | T018..T027 (angle-bracket vars), T025, T026, T027 |
| FR-B89-005 | T015 (b8-3b coupling guard: scaffoldable:false) |
| FR-B89-006 | T036 (b8-2 frozen sha256 guard) |
| FR-B89-007 | T027 (README web-backoffice posture section) |
| FR-B89-008 | T005, T006, T020, T023, T024, T025, T026 (Article III.4 anti-hallucination) |
| FR-B89-009 | T027, T031 |
| FR-B89-010 | T015 (b8-3 coupling guard: FR-GL-001 triple preserved) |
| FR-B89-020 | T008 (T-002), T026, T031 |
| FR-B89-021 | T008 (T-004), T018, T026, T031 |
| FR-B89-022 | T005, T026, T031 |
| FR-B89-023 | T005, T006, T026 (Article III.4 anti-hallucination) |
| FR-B89-024 | T008 (T-005), T018, T027, T028 |
| FR-B89-025 | T018, T026, T027 (Zod deferral + README note) |
| FR-B89-030 | T008 (T-010), T016, T031 |
| FR-B89-031 | T017, T036 (frozen 1.0.0 guard) |
| FR-B89-032 | T016, T031 |
| FR-B89-033 | T008 (T-011), T017, T031 |
| FR-B89-040 | T010, T031 |
| FR-B89-041 | T010, T013, T032 |
| FR-B89-042 | T010, T031 |
| FR-B89-043 | T001, T002, T003, T010 (Phase 0 re-verify → T010 pins) |
| FR-B89-044 | T010 |
| FR-B89-045 | T012, T031 |
| FR-B89-046 | T013, T032 |
| FR-B89-047 | T011, T031 |
| FR-B89-050 | T008 (T-002/T-006), T019, T031 |
| FR-B89-051 | T004, T019 (Node 24 re-verified) |
| FR-B89-052 | T027 (README Node toolchain setup section) |
| FR-B89-060 | T008 (T-009), T014, T031 |
| FR-B89-061 | T015, T037 |
| FR-B89-062 | T014 (comment-only — no standard: YAML key added) |
| FR-B89-063 | T015, T037 (Python yaml.safe_load coupling) |
| FR-B89-070 | T027 (README Janus arbitration section) |
| FR-B89-071 | T027 (README Envoy Connect/HTTP path section) |
| FR-B89-072 | T027 (README web-backoffice unchanged posture) |
| FR-B89-073 | T027 (README scope-out section) |
| FR-B89-074 | T027 (README Status block) |
| FR-B89-075 | T027 (README Zod deferral note) |
| FR-B89-080 | T008, T009, T030 |
| FR-B89-081 | T008 (T-002), T031 |
| FR-B89-082 | T008 (T-004), T031 |
| FR-B89-083 | T008 (T-005), T028 |
| FR-B89-084 | T008 (T-007), T010, T031 |
| FR-B89-085 | T008 (T-008), T011, T012, T031 |
| FR-B89-086 | T008 (T-009/T-010), T014, T016, T031 |
| FR-B89-087 | T008 (T-011/T-012), T015, T029, T031 |
| NFR-B89-001 | T008, T009, T031 (≤ 2 s L1) |
| NFR-B89-002 | T017, T036 (frozen 1.0.0 + buf.gen 1.0.0 byte-identity) |
| NFR-B89-003 | T015, T031, T037 (b8-3 17/17 + b8-3b 12/12 + b8-6 12/12) |
| NFR-B89-004 | T038, T039 (full ~48-harness suite before push) |
| NFR-B89-005 | T008 (bash + grep + python3 only; no new external binary) |
| NFR-B89-006 | T001..T007 (Phase 0 LIVE re-verify; ADR-B89-001 clause) |
| NFR-B89-007 | T018..T027 (no secret material in any template file) |
| NFR-B89-008 | T018..T027 (Flutter files not touched; additive brick) |
| NFR-B89-009 | T014 (Kong/Article VIII.1 untouched; scaffoldable:false) |
| NFR-B89-010 | T042 (independent review — separate lane; T5.2 lesson) |
| NFR-B89-011 | T041 (POST-flip gates re-run; b8-coroot lesson) |
| NFR-B89-012 | T008 (T-003), T028 (file count ≤ 15) |
