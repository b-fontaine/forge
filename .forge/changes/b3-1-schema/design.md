# Design — `b3-1-schema`

## Start where nothing depends on you

B.3's artefacts form a chain: templates need the schema, the dispatch key needs
templates (registering it without a tree turns `forge init` from a clean exit 2 into an
exit 3 that promises a scaffold nobody can produce), the CLI trust fixture needs the
dispatch key, and the promotion needs a harness over all of them.

The schema is the only link with no upstream. That is why B.6.1, B.7.1 and B.9.1 are
each their archetype's schema, and it is the argument for inferring the same here rather
than a coincidence of numbering.

## What the schema commits to, and what it deliberately does not

| committed | deferred, with a pointer |
|---|---|
| identity, stage, `layer_profile` | the template tree (`B.3.2`) |
| the two layers and their agents | the release pipeline (`B.3.4`) |
| the tdd-rust phase chain, inline | signing (`B.3.5`) |
| the component surface | SBOM (`B.3.6`), the five channels (`B.3.7`) |

Every deferral is a `delivered_by` naming a brick. `b9-1` shipped four such pointers and
`b9-2` discharged them; `T-014` asserts none of them points outside B.3, because a
pointer at a module that will never run is a promise nobody owns.

## The one design decision that is not inherited

`layer_profile` accepts two values and a devtool is neither, in plain English. The
discriminator's *function* is binary — does the `{backend, frontend, infra}` triple
apply? — and for a CLI it does not, so `client-only` is behaviourally right and
lexically wrong.

The alternatives are worse. A third value with identical behaviour is taxonomy
inflation: two names, one meaning, and a reader who must learn which. A rename touches
`mobile-pwa-first`'s shipped schema, `validate-foundations.sh` and three harnesses to
change a word. So the schema uses `client-only` and spends six lines explaining why, in
the place a confused reader will actually be standing.

## Guards

18 L1 cells. The load-bearing ones are the negatives and the live validator:

- `T-012` reads a **comment-stripped** stream. The header discusses versions in prose,
  and an unstripped grep would report that discussion as a pin — the trap this
  repository has now paid for seven times.
- `T-016` runs `validate-foundations.sh` rather than re-implementing its rules, so the
  schema is checked against the thing that will actually reject it in CI.
- `T-017` and `T-018` assert what this brick must **not** have done: no dispatch key, no
  shipped archetype touched.

`T-015`'s first needle was the bare word `inferred`, and it survived the mutation that
deleted the sentence it protects, because the word recurs two paragraphs later. Narrowed
to `is therefore **inferred**` — verified unique by `grep -c` before trusting it. Eighth
line of the harness header now says to do that check first.

## Registration

`b3-1.test.sh` takes `forge-ci.yml` from 420 to 421, the first line of the headroom
`t7-ci-line-budget-440` opened. Cap 440.
