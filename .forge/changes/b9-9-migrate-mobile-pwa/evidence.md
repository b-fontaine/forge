# Evidence — `b9-9-migrate-mobile-pwa`

All probes 2026-09-10.

---

## P-1 — the contract, measured

Rendered `mobile-only` and `mobile-pwa-first` from identical inputs, diffed:

```
Only in <ported>/.forge:            scaffold-manifest.yaml
Only in <ported>/.github/workflows: web-pwa-ci.yml
Only in <ported>:                   oidc-provider.json
Only in <ported>:                   web-pwa            (23 files)
Files differing: 0
```

**26 additions, 0 modifications.** `ADR-B9-1-004` predicted this; the diff establishes
it. The design rests on the measurement, not on the prediction.

## P-2 — a locale trap that would have inverted the answer

The first diff reported **nothing**. `diff` on this machine answers in French —
`Seulement dans …`, not `Only in …` — so `grep "^Only in"` matched zero lines and the
conclusion would have been "the two renders are identical", i.e. nothing to migrate.

Caught because 48 vs 74 files made "identical" impossible. Re-run under `LC_ALL=C`.
Checked afterwards: `b9-2.test.sh::T-007` is not exposed — it tests `[ -n "$out" ]`
on the whole diff rather than grepping for an English phrase.

## P-3 — a mobile-only install has no manifest

```
$ ls <mobile-only render>/.forge/
framework-owned-paths.yml
```

No `scaffold-manifest.yaml`. So `b8-10b`'s "read the substitution values from the
manifest" is unavailable, and they are derived instead: `pubspec.yaml`'s `name:`
(`mig`) and `android/app/build.gradle.kts`'s `namespace` (`com.m.g`), the latter also
appearing in `applicationId`, `Info.plist` and the intent-filter scheme.

## P-4 — RED before GREEN

Four guards written first: **RED**, naming the absent script. After the script:
`b9-2.test.sh` **27/27 GREEN**.

T-025 passed from the start — it is a drift guard on the plan filter, not a
red-before-green test, and the plan already held the 25 entries.

## P-5 — the proof

Migrated a real `mobile-only` render, compared against a native
`forge init --archetype mobile-pwa-first` render:

```
[Phase 2] added 26 file(s); 0 modified

Files ported/.forge/scaffold-manifest.yaml and mig-src/.forge/scaffold-manifest.yaml differ
--- differences: 1
```

**Byte-identical except the manifest.** And the manifest differs in exactly three
fields:

```
< scaffold_date: '1970-01-01T00:00:00+00:00'      (the reference render pinned SOURCE_DATE_EPOCH)
< scaffold_plan_sha: 739bbe63…
< template_set_sha: 87de7776…
```

`archetype`, `archetype_version`, `project_name`, `reverse_domain` and `root_module`
all match. The two hashes differ because the migration rendered from the filtered
25-entry plan — which is what actually happened, so recording it is correct (Q-002).

## P-6 — the guards do what they say

| test | check |
|---|---|
| T-024 | `--help` exits 0 and documents `--target`; missing `--target` exits 2 |
| T-025 | the plan filter still yields 25 entries, 23 under `web-pwa/` |
| T-026 | hashes every pre-existing file before and after — **0 changed** |
| T-027 | a re-run exits 7 or 8 |

T-026 is the load-bearing one. `b8-10b` shipped 36 raw templates into adopters'
projects because no test had ever inspected migration output; this one hashes the
tree.

## P-7 — behaviour at the edges

```
  dry-run exit=0   files before=48  after=48   → wrote nothing
  re-run on an already-migrated tree: exit=7
```

## P-8 — regression

`b9-2`, `b9-1`, `b9-3`, `b4` (mobile-only), `b8-2` (frozen flagship snapshot): GREEN.
`shellcheck --severity=warning` over `.forge/scripts` and `bin`: clean.
`verify.sh`, `constitution-linter.sh` and the 80-entry sweep: `tasks.md` T6.

Negative scope: no edit to `overlay.sh`, the archetype scaffold-plan, the frozen
`mobile-only/1.0.0` snapshot, or any template.
