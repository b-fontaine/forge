# Evidence — b9-2-web-pwa

<!-- Audit: B.9.2 (b9-2-web-pwa) — verify-then-pin record (FR-B9-2-014, ADR-B9-2-003) -->

## P-1 — T3.1 verify-then-pin LIVE, npm registry, 2026-07-28

Resolved with `npm view <pkg> version` / `npm view <pkg> peerDependencies` against the
public registry. **No pin in this change was taken from `web-frontend.yaml` on trust** —
its `P30D` cadence had lapsed by 25 days (`last_reviewed: 2026-06-03`).

| Package | `web-frontend.yaml` (2026-06-03) | Live 2026-07-28 | Verdict |
|---------|----------------------------------|-----------------|---------|
| `@builder.io/qwik` | `^1.20.0` | latest **1.20.0** | **HOLDS** — no drift |
| `@builder.io/qwik-city` | `^1.20.0` | latest **1.20.0** | **HOLDS** — no drift |
| `vite` | `"7.3.5"` exact, "max stable 7.x" | max in `<8` is now **7.3.6**; npm `latest` is **8.1.5** | **DRIFTED** — the recorded max-in-range moved 7.3.5 → 7.3.6 |

### P-1.a — the Vite-8 trap still holds (the specific question ADR-B9-2-003 flagged)

```
$ npm view @builder.io/qwik@1.20.0 peerDependencies
{ vite: '>=5 <8' }
```

The exact `vite` pin is justified **solely** by this exclusion, so it was the one thing
that had to be re-checked rather than assumed. The range is **unchanged**: Vite 8 is
still excluded, and npm `latest` (8.1.5) would still produce an incompatible peer. The
pin's *rationale* survives; only its *value* is stale.

**Consequence for ADR-B9-2-003**: this is the **drift branch**. `web-frontend.yaml`
gets a `versions:` update (`vite: 7.3.5` → `7.3.6`), a SemVer `version:` bump, a
refreshed `last_reviewed`, and a `REVIEW.md` entry recording that qwik/qwik_city held
while vite's max-in-range moved.

`@builder.io/qwik-city@1.20.0` declares **no** `peerDependencies` (empty output) — the
vite constraint comes from the core package alone.

## P-2 — devDependencies for the new `web-pwa` template

These are **not** governed by `web-frontend.yaml`; B.8.9 chose them for
`frontend/web-public/`. Live latest at 2026-07-28:

| Package | B.8.9 template | Live latest | Decision for `web-pwa/` |
|---------|----------------|-------------|-------------------------|
| `typescript` | `^5.4.0` | **7.0.2** | **Keep the `^5.x` line.** |
| `@types/node` | `^22.0.0` | **26.1.2** | **Keep `^22`.** |
| `vite-tsconfig-paths` | `^4.2.1` | **6.1.1** | **Keep `^4`.** |

**Rationale for not taking latest.** TypeScript **7** is a major jump whose
compatibility with Qwik 1.x is **unverified**. Note precisely what upstream does and
does not say: `@builder.io/qwik@1.20.0` declares **no** TypeScript constraint at all —
its `peerDependencies` is `{vite: '>=5 <8'}` and its `engines` covers node only — so
there is no upstream signal in either direction. An earlier draft of this paragraph
asserted that Qwik "is built and tested against the TS 5 line"; that was an inference
stated as a fact and has been removed (review N5). Separately, `@types/node` 26 implies
a Node major this template does not target.

Taking a latest-major on a transitive toolchain purely because it is `latest` is the
exact failure shape of T5.3.2 (`t5-otel-stack-image-refresh`), where a "pin refresh"
turned out to be an unannounced architectural migration. Adopting these majors is a
deliberate upgrade with its own verification, not a side effect of scaffolding a new
archetype.

**Recorded, not hidden**: three devDependency lines in this template are behind live
latest by design. If a later brick wants them current, it must verify Qwik-1.x
compatibility first and say so.

## P-3 — Node runtime

`.nvmrc` and the `engines.node` floor are inherited from the B.8.9 spine unchanged;
`web-frontend.yaml` declares `node: "P12M"` cadence, which has **not** lapsed
(`last_reviewed: 2026-06-03`, ~2 months). No live re-check was required and none is
claimed.
