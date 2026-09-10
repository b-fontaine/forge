# Evidence — `b9-10-migration-paths`

All probes 2026-09-10.

---

## P-1 — the index claimed more than it held

```
$ grep -c '^## ' docs/MIGRATION-PATHS.md          1
$ grep -n 'forge-migrate-flagship' docs/MIGRATION-PATHS.md   (no output)
```

One section, and no mention of the flagship migration — whose driver, runbook and
rollback procedure all shipped with B.8.10. The document's first sentence said
*"indexes every supported migration in Forge."*

`T-029` reproduces the finding mechanically before any text was written:

```
FAIL T-029: forge-migrate-flagship.sh is a migration driver with no row in ...
FAIL T-029: forge-migrate-mobile-pwa.sh is a migration driver with no row in ...
```

## P-2 — the additive contract, re-measured rather than transcribed

`b9-9` recorded 26/0. Re-run here from scratch on a real `mobile-only` render:

```
before files: 48   after files: 74
--- added:    26     (23 under web-pwa/, + oidc-provider.json,
                      .github/workflows/web-pwa-ci.yml, .forge/scaffold-manifest.yaml)
--- removed:  0
--- modified (pre-existing files whose hash changed): 0
```

Against a native render under the harness gate override:

```
$ LC_ALL=C diff -rq <migrated> <native>
Files <migrated>/.forge/scaffold-manifest.yaml and <native>/.forge/scaffold-manifest.yaml differ
```

**One file, of 74.** And that file differs in exactly three lines:

```
6,8c6,8
< scaffold_date: '2026-09-10T19:33:55.269741+00:00'
< scaffold_plan_sha: 60cac6b0…
< template_set_sha:  dc27c736…
---
> scaffold_date: '1970-01-01T00:00:00+00:00'     (the native render pinned SOURCE_DATE_EPOCH)
> scaffold_plan_sha: 739bbe63…
> template_set_sha:  87de7776…
```

`LC_ALL=C` is not decorative: `diff` answers in French on this machine, and `b9-9`
recorded a first run where `grep "^Only in"` matched nothing and would have concluded
the two renders were identical.

## P-3 — every exit code the document tabulates was provoked

| invocation | exit |
|---|---|
| `--target <dir>` on a clean mobile-only render | 0 |
| `--dry-run` (files 48 → 48, nothing written) | 0 |
| no `--target` | 2 |
| `--nope` | 2 |
| `PATH` without `python3` | 5 |
| `--target` a missing directory | 7 |
| `--target` a directory with no `pubspec.yaml` | 7 |
| re-run, `web-pwa/` present | 7 |
| `oidc-provider.json` already present | 8 |
| the same, `--force` | 0 |

The exit-5 probe was wrong on the first attempt. `env -i PATH=/nonexistent bash …`
returned **127**: `env` resolves `bash` itself through the new `PATH` and never found
it, so the script never ran. Re-run with an absolute interpreter, it exits 5 as
specified. A probe that never reaches the code under test reports the tool's failure
as the subject's behaviour.

## P-4 — RED before GREEN

Three guards written first, run against the untouched document:

```
FAIL T-028: no '## B.9 ' section in MIGRATION-PATHS.md
FAIL T-029: forge-migrate-flagship.sh … no row      (× 2 drivers)
FAIL T-030: no B.9 section (see T-028)
```

After the document: **b9-2.test.sh 30/30 GREEN.**

## P-5 — `T-030` refused a claim the document was entitled to make

First GREEN run:

```
FAIL T-030: the section documents exit 3, which is unreachable in bin/forge-migrate-mobile-pwa.sh
```

Correct on its own terms and wrong as a rule. The sentence is *"`forge init
--archetype mobile-pwa-first` refuses at exit 3"* — a **different binary's** envelope,
and one already asserted by `b9-2.test.sh::T-L2-001`.

The wrong fix is to reword the prose until the regex stops matching; that trades a
true statement for a quiet guard. The fix taken: read exit codes from the
`### Exit codes` table only — the place where the section actually claims *this*
script's envelope — mirroring the rule already used for flags, which are read from the
fenced code blocks so the prose can say there is no rollback flag.

## P-6 — the mutation probes, and the guard that failed one

Each probe mutates the real document, runs the harness, restores, and verifies the
restore by sha256.

| probe | result |
|---|---|
| drop `26 files added, 0 modified` | RED |
| **delete the flagship's index row** | **STILL GREEN — the guard did not guard** |
| invent `--rollback` in the invocation example | RED |
| invent `exit 9` in the envelope table | RED |

`T-029` grepped the **whole document** for each driver name, and the rollback prose
mentions `forge-migrate-flagship.sh` while explaining why this migration needs no
rollback flag. "The name appears somewhere" is not "the driver is indexed" — the
document could lose its entire index table and the guard would still pass.

Rescoped to the rows of the `## Index` table, with an anti-vacuity floor on both the
driver count and the row count. Re-run: **4/4 RED.** Restore verified byte-identical
each time.

This is the third session in a row in which a probe that does not mutate — or a guard
that matches something other than what it names — looked exactly like a passing test.

## P-7 — negative scope holds

```
$ git status --short
 M .forge/scripts/tests/b9-2.test.sh
 M docs/MIGRATION-PATHS.md
 M docs/MIGRATIONS.md
?? .forge/changes/b9-10-migration-paths/
```

Nothing under `bin/`, `.forge/templates/`, `.forge/schemas/` or `.forge/scaffolding/`
(NFR-B910-003). The T.5 section is byte-stable across the rewrite:
`sha256 d1716a91ee310bf863bd808417d2f85b42567b783829632f1ee41981bf46fc5b`, before and
after (NFR-B910-004).

## P-8 — the `framework-owned-paths.yml` claim, checked rather than read

```
a9a7921e…  .forge/templates/archetypes/mobile-only/.forge/framework-owned-paths.yml.tmpl
a9a7921e…  .forge/templates/archetypes/mobile-pwa-first/2.0.0/.forge/framework-owned-paths.yml.tmpl
$ grep -c web-pwa <mobile-pwa-first copy>   0
```

Identical hashes, zero mentions of the surface the archetype is named for. Recorded as
Q-001.

## P-9 — regression

- `b8-10` 14/0, `b8-12` 23/0, `b8-13` 18/0 — the three harnesses asserting
  `docs/MIGRATIONS.md` content, run after the cross-reference line was added.
- `b9-2` **30/30**.
- Full 80-entry CI matrix sweep, `shellcheck --severity=warning`, `verify.sh` and
  `constitution-linter.sh` after the status flip: `tasks.md` T6.
