# Proposal — `b8-10b-migrate-render`

**`forge-migrate-flagship.sh` copies raw template files into an adopter's project.**
It never renders them: the `.tmpl` extension survives, and the placeholders inside
survive with it.

## Reproduced, not inferred

Rendered a real `full-stack-monorepo / 1.0.0` project, `git init`-ed it, and ran the
migration as an adopter would:

```
$ bash bin/forge-migrate-flagship.sh --target <adopter> --force
migrate exit=0
```

Result in the adopter's tree:

| | |
|---|---|
| raw `.tmpl` files deposited | **36** |
| of those, still carrying `<project-name>` / `<reverse-domain>` / `<root-module>` | **24** |
| sitting **beside** an already-rendered file of the same name | **9** |

`README.md.tmpl` line 3 is literally `# <project-name>`. `CLAUDE.md` and
`CLAUDE.md.tmpl` now sit side by side, as do `docker-compose.dev.yml`,
`Taskfile.yml` and `README.md` with their `.tmpl` twins.

And the migration reports success: `.forge/scaffold-manifest.yaml` records
`upgraded: 36` and flips `archetype_version` to `2.0.0`. An adopter is told the
migration worked.

## Root cause

Three lines, all in `bin/forge-migrate-flagship.sh`:

- `:48` — `TPL_20=…/archetypes/full-stack-monorepo/2.0.0` — the merge RIGHT is the
  **raw framework template tree**, not a rendered surface.
- `:227-230` — `_b810_map_relpath` strips the `2.0.0/` prefix and nothing else. The
  `.tmpl` suffix is carried through verbatim.
- `:263`, `:290` — the file operations are a plain `cp`.

`grep -c 'tmpl\|substitut\|placeholder'` over the whole script returns **0**.

## This is an omission, not a deferral

Worth separating, because B.8.14 made exactly the opposite call *explicitly* for
fresh-init and wrote it into `scaffold-plan-2.0.0.yaml`'s header. Here there is no
such record:

- `ADR-B810-001` resolves the RIGHT-selection problem in detail — it has a
  dedicated "Path-mapping note" explaining the `2.0.0/` prefix strip and the schema
  layer paths — and never mentions the extension or the placeholders.
- `b8-10-migrate-flagship/evidence.md:62-69` **lists the source files with their
  `.tmpl` extensions**, so they were in front of the author.
- `docs/MIGRATIONS.md:95` promises the adopter `no-web → Qwik web-public →
  frontend/web-public/`. It does not say "as unrendered templates you must process
  yourself".

## Why it survived five weeks of green CI

`b8-10.test.sh` is 12 L1 + 1 L2. The L1 tests assert the script exists, `--help`
exits 0, no new dependency, the exit envelope, the no-DBOS and additive-only static
guards, the rollback path, the docs. The single "live" test,
`_test_b810_l2_001_live_dry_run`, is a **`--dry-run`** — which by construction
produces no files.

**Nothing has ever inspected the migration's output.** Same shape as the
`ai-native-rag` fixture that had never run anywhere: a suite that is green about
everything except the thing that matters.

## The fix is tractable

The values needed for substitution are already in the adopter's tree.
`.forge/scaffold-manifest.yaml` carries them:

```yaml
project_name: adopter
reverse_domain: com.probe.ad
root_module: adopter
```

So no new CLI flag is required — which matters, because the script's ABI is
`--target` only and widening it would break every caller.

## Scope

**In:** rendering the migrated files (extension + placeholders); a test that
inspects real migration **output**; the stale banner at `:175`
(`"2.0.0 (scaffoldable: false until B.8.14)"` — B.8.14 shipped and the schema says
`scaffoldable: true`); `docs/MIGRATIONS.md` if the delivered behaviour changes what
it should promise.

**Out:** the fresh-init gap — 23 of the 36 files in the `2.0.0/` tree are referenced
by no scaffold plan, deliberately per B.8.14. Closing that is a separate decision
(`open-questions.md` Q-002).

## Negative scope

MUST NOT change the migrate script's `--target`-only ABI, the frozen `1.0.0`
snapshot, `overlay.sh`, or the `_a7_*` merge library it sources.
