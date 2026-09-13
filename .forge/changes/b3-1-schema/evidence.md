# Evidence — `b3-1-schema`

2026-09-13.

---

## P-1 — the plan defers to a list that is not here

`docs/new-archetypes-plan.md` §3.3, in full:

> B.3 `rust-cli-tui` — `KEEP`. Inchangé du plan d'origine (B.3.1 → B.3.14).
> Effort : `XL`. Reste à livrer.

`grep -rn "B\.3\.[0-9]" docs/ .forge/` returns that line and nothing else. The only
statement of B.3's content in the repository is `roadmap.md:202`.

By contrast the plan spells out B.6.1–B.6.14 (§6.1) and B.7.1–B.7.14. B.3's breakdown
was never transcribed.

## P-2 — the precedent the inference rests on

```
2901:- **B.6.1.** Schema `.forge/schemas/event-driven-eu/1.0.0.yaml` étend `tdd-rust`
2945:- **B.7.1.** Schema `.forge/schemas/ai-native-rag/1.0.0.yaml` étend `ai-first`
```

plus B.9.1 (`mobile-pwa-first/2.0.0`). Three archetypes, three schema-first bricks.

## P-3 — the shape is ratified, not invented

`archetype.schema.json:13` carries `rust-cli-tui` in its enum, pinned by
`t4.test.sh:253-265`, and `:21` describes it: *"Devtools archetype — clap + ratatui +
cargo-dist signed releases ; multi-channel distribution."* The two layers come from that
sentence; their agents from the Rust sub-team `CLAUDE.md` fixes.

No taxonomy edit was needed — the same position `b9-1` was in.

## P-4 — RED before GREEN

18 cells against no schema: **16 RED**. The two that passed are `T-017` (no dispatch key
yet) and `T-018` (shipped archetypes untouched) — correct, and worth noticing: a
negative that passes before the work exists is only meaningful if it still passes after.

After the schema: **18/18**, including `T-016`, which runs `validate-foundations.sh`
itself rather than re-implementing its rules.

## P-5 — mutation probes, and the one that failed

| probe | first pass |
|---|---|
| stage flipped to `stable` | RED |
| `scaffoldable` flipped to true | RED |
| `layer_profile` set to `multi-layer` | RED |
| a layer loses `primary_agent` | RED |
| an `extends:` key appears | RED |
| a review gate dropped | RED |
| a resolved pin creeps in | RED |
| a `delivered_by` points at B.9.4 | RED |
| **the inference note deleted** | **STILL GREEN** |

`T-015`'s needle was the bare word `inferred`. The header uses it twice — once in the
sentence the needle protects, once two paragraphs later in *"whose number is inferred
the same way"*. Deleting the load-bearing sentence left the other.

`grep -c` confirms it: `inferred` → 2, `is therefore **inferred**` → 1. Narrowed to the
latter, re-probed: **RED. 9/9.**

Seventh instance in this repository of a needle satisfied by something other than what it
names. The harness header now prescribes the check — `grep -c` inside the region, before
trusting the needle.

## P-6 — a second defect in my own harness

`T-009`'s failure message printed *"the schema declares  — nothing resolves it"*. The
message contained `` `extends:` `` inside a double-quoted bash string, so the backticks
command-substituted an empty result. A test that fires correctly can still report
uselessly; the message was rewritten to `'extends:'`.

## P-7 — registration and regression

`forge-ci.yml` 420 → **421**, cap 440 — the first line of the headroom
`t7-ci-line-budget-440` opened, exactly as that brick said B.3.1 would spend it.

Full CI matrix **82/82** · `verify.sh` + `constitution-linter.sh` after the status flip ·
shellcheck clean.

## P-8 — negative scope, asserted rather than inspected

`T-017`: no `rust-cli-tui` key in `dispatch-table.yml`. `T-018`: the three stable
schemas are still stable and the taxonomy enum still carries the archetype. Both pass
after the change as they did before.
