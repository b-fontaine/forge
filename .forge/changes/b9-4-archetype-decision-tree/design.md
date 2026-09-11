# Design — `b9-4-archetype-decision-tree`

## Where the section goes, and why not in the table

`docs/ARCHETYPES.md` is 165 lines: intro, invocation reference, the 7-row matrix, the
flagship 2.0.0 "what you get and what you don't" section, `How forge init chooses`,
the J.8 forbidden combinations, the `--eu-tier` table.

The channel decision is **not** an archetype choice — it is a choice *inside*
`mobile-pwa-first`, between its two client layers. It therefore gets its own section
rather than a matrix row, placed immediately before `How forge init chooses`: after
the reader knows which archetypes exist and what the flagship actually ships, and
before the mechanics of invoking the CLI.

That placement also mirrors the flagship section's job — *"a version number normally
implies a content, and here it does not yet"* — which is exactly the shape of the
`candidate` caveat this section has to carry.

## Section outline

1. **The rule**, as an ASCII tree. Three leaves, because the interesting branch is the
   one the plan's one-liner omits: iOS *without* critical push still takes the PWA.
2. **Normative source** — `pwa.yaml::channel_fallback`, and the `channel-decision`
   schema phase that records the per-change choice.
3. **What the rule does not say** — the disclaimer. Load-bearing (see below).
4. **What you actually get today** — a three-row table: `exit 3`, the reachable path
   via the migration, and `layer_profile: client-only` with the §6.3 discrepancy.

## The disclaimer is the design decision

The plan's line is *« si plateforme iOS ET push critique → fallback Flutter natif »*.
Written as prose, that invites the reader to infer *"because iOS can't do Web Push"* —
a claim the repository never makes and that has been false since Safari 16.4.

The repo's own most careful sentence is `pwa.yaml:77`: iOS installed-PWA push is *"not
assumed"*. That is epistemic, not technical, and the section inherits it verbatim plus
an explicit *"makes no claim about iOS capability"*.

Consequence for the guard: `FR-B94-002` is a prohibition, and a prohibition cannot be
guarded negatively here — "the section must not say iOS cannot do push" would fire on
the sentence explaining that it does not. So it is enforced **positively**: the
disclaimer must be present, and the disclaimer is precisely what a flattened rewrite
would delete.

## Guards, and which harness owns which

| guard | host | asserts |
|---|---|---|
| `test_archetypes_decision_matrix_present` (rewritten) | `b5.test.sh` | every registry archetype that is available has a **row in the matrix table** |
| `T-031` | `b9-2.test.sh` | the decision-tree section's content battery |

Split per `ADR-B94-003`: `FR-IW-009` owns the matrix and lives in `b5`; a second
harness asserting the same table from another file is how two sources of truth start.
`b9-2` hosts only what is B.9-specific. Neither is a new harness — `forge-ci.yml` is at
419/420 and the last line is B.9.11's.

### The derivation, and the exclusion that does the work

```
expected = { k for k, v in dispatch_table["archetypes"].items()
             if v.get("status") not in {"candidate", "removed_from_roadmap"}
             and v.get("scaffolder") != "<removed>" }
```

Excluding `candidate` is not a convenience. It encodes the precedent — no archetype has
ever held a matrix row while candidate — and it turns the guard into B.9.11's
checklist: the promotion flip makes `expected` gain `mobile-pwa-first`, the row is
absent, `b5` goes red. Proven by simulation, not asserted (`evidence.md` P-3).

`FR-IW-009`'s five mandated names are asserted separately, because two of them
(`flutter-firebase`, `rust-cli-tui`) are deliberately *not* in the derived set and a
cleanup would otherwise be free to delete them.

## Traps this file has already paid for

**Scope every match to its region.** Both guards read a delimited slice — the
`## Available archetypes` rows, the `## Choosing the mobile channel` section — never
the whole file. The old `b5` guard did not, and 4 of 7 rows were deletable.

**A needle must name the claim, not a word.** `client-only` occurs twice in the new
section; the bare-word needle passed a probe that deleted the load-bearing row.
Narrowed to `layer_profile: client-only`.

**Run each harness the way CI runs it.** `b5.test.sh` takes no `--level`; passing one
makes it exit 2 before any test runs, which the first probe read as "caught".

## Verification strategy

Content batteries prove the document *says* things. What makes them true is that each
figure is transcribed from a probe in `evidence.md`, and that every guard is
mutation-proven: seven row deletions against the matrix guard, five fact deletions
against `T-031`, plus the simulated B.9.11 flip.
