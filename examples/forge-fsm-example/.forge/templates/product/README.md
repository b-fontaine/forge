# Product Templates

Empty templates for a project's product documentation. The scaffolder
(`forge init`, audit item A3) copies these files to `.forge/product/` in
the target project so the user fills them with **their** product's mission
and roadmap — not Forge's.

Do not edit these files to add Forge-specific content. They must stay
generic. Forge's own filled mission and roadmap live in `.forge/product/`
at the root of this repository (dog-fooding — audit items E1, E2).

## Why this separation

Without it, `forge init` would copy `.forge/product/mission.md` from this
repository (filled with Forge's own mission) into the target project.
Downstream agents (Pythia, Clio, Socrates) would then read the target's
`mission.md` and mistakenly believe they are working on Forge itself.
That is a silent-drift bug the Constitution (Article V) is meant to
prevent but has no automated gate for today.

Audit item **A3.0** tracks this concern; audit item **F4** extends
`constitution-linter.sh` to detect accidental Forge-signature strings
leaking into a scaffolded project's `mission.md`.
