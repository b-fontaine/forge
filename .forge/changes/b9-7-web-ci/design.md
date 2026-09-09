# Design — `b9-7-web-ci`

## Shape

```
web-pwa-ci.yml
├── filter   dorny/paths-filter@v3 on web-pwa/**  → outputs.web
├── build    if: needs.filter.outputs.web == 'true'
│            setup-node@v4 (node-version-file: web-pwa/.nvmrc, cache: npm)
│            npm install
│            npm run build.types      ← static analysis
│            npm run build            ← build
│            upload-artifact@v4 web-pwa/dist
│            verify.sh                ← Forge gates, last
│            constitution-linter.sh
└── summary  needs: [filter, build] · required check · skipped == success
```

Two jobs plus the filter, mirroring `forge-frontend.yml.tmpl`'s
`filter` → `build` split, which is the shape `ci-workflows.md` documents.

## The one decision with teeth: which Node

`node-version-file: web-pwa/.nvmrc` rather than `node-version: 24`.

This is not style. `t5-qwik-cli-ignore-dep` measured that `qwik build` appends
` --pretty` to `npm run build.types`, so the flag reaches **npm**:

| npm | result |
|---|---|
| 9, 10, 11 | accepted → `npm run build` exits 0 |
| 12 | `EUNKNOWNCONFIG` → exits 1, reporting `Type check failed:` with empty output |

`.nvmrc` says `24`, which ships npm ≤ 11. Reading the version from that file
means CI and the declared target cannot drift apart, and the day `.nvmrc` moves
to a Node shipping npm 12 the workflow goes red **in the same commit that caused
it**, next to the `.nvmrc` change — instead of weeks later on an unrelated pull
request. A hardcoded `node-version: 24` would silently keep working after
`.nvmrc` moved, which is worse.

## Verification

Two layers, as with the qwik fix, because they prove different things:

| Layer | Asserts | Blind to |
|---|---|---|
| `b9-7.test.sh` L1 | the template's *shape* — filter, ordering, pins, no deploy, no `continue-on-error`, plan entry | whether GitHub would accept it |
| `python3 -c yaml.safe_load` inside the harness | the file is valid YAML after comment stripping | semantics |

Neither runs the workflow — there is no runner here. That limit is stated in the
harness header rather than left for a reader to infer from what the tests happen
to check.

### Two traps this harness has to dodge

**Substring assertions that cannot fail.** `b9-3` lost three tests to needles
satisfied by unrelated text. Every content assertion here is anchored on a key
in *this* file and probed by mutation before the change is called done.

**Ordering asserted by position, not presence.** Checking that four step
keywords all appear proves nothing about order. The harness records each
needle's byte offset and asserts the offsets are sorted — the same mechanism
`delivery.test.sh` uses, which is why it is borrowed rather than reinvented.

## The byte-equivalence exclusion

`b9-2.test.sh::T-007` diffs a legacy `mobile-only` render against the ported one.
`web-pwa-ci.yml` is a new root-level file with no legacy counterpart, so it fails
that diff exactly as `oidc-provider.json` did for B.9.3.

Adding `--exclude=web-pwa-ci.yml` follows that precedent, and the comment repeats
B.9.3's warning verbatim in substance: `--exclude` matches a **basename at any
depth**, so any file with that name anywhere under either tree is skipped. The
name is distinctive enough that this costs nothing real, but the next person to
add an exclusion should see the mechanism spelled out rather than infer it.

What the gate still guarantees, stated precisely: every file under `lib/`,
`ios/`, `android/`, `test/`, and `mobile-ci.yml` itself, is still compared
byte-for-byte. This change adds no file under any of them.

## Ordering (TDD)

1. Write `b9-7.test.sh`. Run it. **Confirm RED** — and confirm it reds for the
   right reason (template absent), not a harness bug.
2. Write `web-pwa-ci.yml.tmpl`.
3. Add the `scaffold-plan.yaml` entry.
4. Run. Confirm GREEN.
5. Mutation-probe every assertion.
6. Render, and confirm the file lands at `.github/workflows/web-pwa-ci.yml`.
7. `b9-2.test.sh` T-007 exclusion; confirm b9-2 GREEN again.
8. Register in `forge-ci.yml` (418 → 419 ≤ 420).
9. Regression: full local CI sweep + both Forge gates, **after** the status flip.
