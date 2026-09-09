# Open questions — `t5-qwik-cli-ignore-dep`

## Q-001 — `vite` pin drift between the standard and two templates (OUT OF SCOPE, recorded)

`web-frontend.yaml` pins `vite: "7.3.6"`. Two of the three Qwik surfaces pin
`"=7.3.5"`:

| Surface | template pin | standard |
|---|---|---|
| `full-stack-monorepo/2.0.0/frontend/web-public` | `=7.3.5` | `7.3.6` |
| `ai-native-rag/1.0.0/frontend/web-public` | `=7.3.5` | `7.3.6` |
| `mobile-pwa-first/2.0.0/web-pwa` | `=7.3.6` | `7.3.6` |

**Cause (documented, not speculative).** `web-frontend.yaml` records that B.9.2
re-verified the pins on 2026-07-28 and found `vite` had drifted 7.3.5 → 7.3.6
within Qwik's `>=5 <8` peer range. B.9.2 updated the standard and its own new
template, and did not back-propagate to the two pre-existing surfaces.

**Why not fixed here.** Changing a build-tool pin on the *stable, shipped*
flagship is a behavioural change requiring its own verify-then-pin pass and a
render-and-build check per surface. Folding it into a missing-dependency fix
would mean two unrelated reasons for one diff, and would put an unproven pin
bump into a change whose whole point is restoring a broken build.

**Status.** Not a regression introduced here; both templates build today (the
`ignore` fix is orthogonal to the vite minor). Recorded for a follow-up brick
that re-runs verify-then-pin across all three surfaces at once.

## Q-002 — should `ignore` be a `dependency` rather than a `devDependency`?

Chosen: `devDependency`. The qwik CLI is a build-time tool; nothing at runtime
imports `ignore`. A production install (`npm ci --omit=dev`) will not have it,
and will not need it — `dist/` is already built by then.

Residual risk: a deployment pipeline that runs `npm run build` after an
`--omit=dev` install would break. That shape is already impossible here, since
`vite`, `typescript` and `@builder.io/qwik-city`'s build path are devDependencies
or dev-time too — such a pipeline is broken before `ignore` enters the picture.

## Q-003 — upstream report

Not filed as part of this change. The right artefact is a minimal reproduction
(two dependencies, zero source files, `npx qwik --help`), which
`evidence.md` records. Filing it is a maintainer action, not a repo change; noted
here so the workaround's removal condition has a tracked counterpart.

## Q-004 — `qwik build` breaks under npm ≥ 12 (`--pretty`), independently of this fix

Found while proving the fix (evidence P-7), and deliberately **not** acted on.

The qwik CLI composes `npm run build.types` and appends ` --pretty` before
executing it, so the flag reaches **npm**, not `tsc`. npm 9, 10 and 11 accept
unknown flags; **npm 12 rejects them** (`EUNKNOWNCONFIG`), and the CLI then
reports `Type check failed:` with empty output — a misleading message, since the
type check never ran.

Measured end-to-end on the rendered tree: `npm run build` exits **0** under npm 11
and **1** under npm 12.

**Why nothing was changed.** The archetypes' `.nvmrc` targets Node **24**, which
ships npm ≤ 11. On the declared target the orchestration works. Recomposing
`build` on top of `vite` — which the evidence briefly appeared to force — would
have been an over-correction driven by this machine running Node 26, ahead of the
target, and would have permanently diverged the scaffold from the framework's
documented scripts to route around a bug the target never sees.

**Trigger for revisiting.** Whichever comes first: (a) `.nvmrc` moves to a Node
release shipping npm ≥ 12; (b) upstream stops appending `--pretty`. At that point
the choice is a real one — recompose `build`/`preview`, or drop `build.types`
from `package.json` and run the type check as its own CI step.

Note that the `ignore` pin is required in **both** worlds: without it the CLI
cannot load at all, so `npm run qwik add <integration>` — the documented way to
add adapters — is dead regardless of npm version.
