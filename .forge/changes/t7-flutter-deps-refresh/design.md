# Design — `t7-flutter-deps-refresh`

## Why the two open questions were one

`b9-5` Q-001 (a stale pin) and `b9-10` Q-001 (an unowned surface) read as unrelated
until `_a7_resolve_owned_paths` is opened:

```python
for pattern in owned:            # ONLY these are merged
    for m in glob.glob(...):
        if not is_excluded(rel): found.add(rel)
```

`excluded:` filters that set; it is not an independent list. An unlisted path is never
touched. `pubspec.yaml` was unlisted — so fixing the pins alone would have shipped
current versions to new projects and nothing to existing ones.

## Order, and the guard collision

```
1. flutter pub outdated on a real render        → the resolvable set (not a pub.dev scrape)
2. bump + analyze on a throwaway                → 3 errors, 2 files
3. flutter test                                 → fails; ALSO fails pristine ⇒ pre-existing
4. apply to both archetypes                     → T-004 and T-007 both go red, as predicted
5. re-scope T-004, exclude the owned file from T-007, add T-034
6. full sweep                                   → t5-otel-dartastic + b9-3 T-022 surface
```

Step 3 is the one worth naming. A failing test after a nine-package bump looks like the
bump's fault. Running it against a pristine render first is what separated "I broke it"
from "it was already broken" — and the answer changed what the brick did.

## The three re-scoped guards share one flaw

`b9-2` T-004, `b9-3` T-022 and, indirectly, `b9-2` T-007 all encoded **"this brick must
not touch X"** as **"X is byte-clean vs HEAD"**. That is correct for the brick that
writes it and wrong forever after: it freezes the artefact against all future
maintenance, including security updates.

`b9-3` T-022 made the confusion explicit — its failure message said the surface was
"byte-frozen by b9-2 T-007", while its mechanism was `_git_clean_vs_head`. T-007
freezes the two archetypes *relative to each other*; it says nothing about history.

Each was replaced by the standing property it was really protecting:

| | was | now |
|---|---|---|
| `b9-2` T-004 | mobile-only git-clean | alias metadata survives; the frozen snapshot still matches its `.sha256` |
| `b9-3` T-022 | Flutter surface git-clean | no `oauth4webapi` / browser-OIDC concern reaches the Flutter surface |
| `b9-2` T-007 | compares every file | compares every file except `framework-owned-paths.yml`, whose divergence `T-034` bounds exactly |

## T-034, and why it compares parsed sets

Excluding a whole file from T-007 weakens the gate, so `T-034` replaces the lost
coverage: the two `owned:`/`excluded:` sets must be identical once `web-pwa` entries are
removed. `mobile-only` has no such surface, and listing a path that can never exist
would make its manifest describe an archetype it is not.

Its first version diffed the files line by line and failed on a prose comment that
happened not to contain the filtered token — asserting that the *comments* matched.
Rewritten to compare parsed YAML, because what matters is what the file means to
`_a7_resolve_owned_paths`.

## T-036 guards a floor, not a string

A caret pin moving forward is normal; sliding back beneath a major whose API the call
sites were adapted to is a silent break. So the guard compares **majors** against the
verified set, and says why in its failure message.

## The one change that alters app behaviour

Everything else here is versions, ownership and tests. `app.dart` is not: moving
`BiometricLockWidget` inside `MaterialApp`'s `builder:` changes the widget tree of every
scaffolded project. It is the correct tree — the overlay needs `Directionality`,
`Theme` and `Material`, all introduced by `MaterialApp` — and the old one threw on
first build. Called out because a dependency brick quietly changing production
composition is exactly the kind of thing a reviewer should be told, not left to find.
