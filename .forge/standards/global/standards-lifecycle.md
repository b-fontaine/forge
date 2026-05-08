# Standards lifecycle

> **Audit**: T.4 (t4-adr-ratification, 2026-05-04). Ratifies the 12-month
> review window introduced by `docs/ARCHITECTURE-TARGET.md` §12.6 and
> `docs/new-archetypes-plan.md` §2.3 (P-3).

This standard governs the lifecycle of every `.forge/standards/*.yaml` file :
how it is born, when it must be reviewed, when it expires, and how it is
amended when its `exception_constitutional` flag forbids automatic expiry.

## Purpose

Forge consacre certaines décisions techniques (le choix d'un transport, d'un
state management, d'un IdP, d'une orchestration, d'une persistance, d'une
stack d'observabilité) sous forme de standards versionnés. Pour éviter le
double écueil — soit la fossilisation (un standard qui survit à sa pertinence
technique), soit l'instabilité (un standard amendé sans contrainte) — Forge
applique un cycle de révision uniforme avec **exception structurelle**
explicite pour les choix qui définissent l'identité de Forge.

## Frontmatter

Tout fichier `.forge/standards/*.yaml` MUST porter le frontmatter uniforme
défini dans la spec t4-adr-ratification (FR-T4-STD-001..006) :

```yaml
version: <semver>                   # version propre du standard, indép. de la Constitution
last_reviewed: <ISO-8601>           # date de la revue la plus récente
expires_at: <ISO-8601 | "never">    # prochaine revue due ; "never" ssi exception_constitutional: true
exception_constitutional: <bool>    # si true, structurel — seul amendement Constitution
linter_rule: <string | null>        # règle déterministe enforçant ce standard
enforcement:
  ci_blocking: <bool>               # FAIL le gate CI ou non
  pre_commit_hook: <bool>           # bloque le commit local
forbidden: [<string>...]            # libs / providers / patterns disallowed
rationale: <multiline string>       # le « pourquoi » — court paragraphe < 10 lignes
```

Tout standard incomplet sur ces clés est un FAIL de
`t4.test.sh::_check_frontmatter_keys`.

## 12-month review window

Par défaut, `expires_at = last_reviewed + 365 jours`. À expiration :

1. `t4.test.sh::_test_t4_l2_expired_warns` détecte la condition et émet un
   WARN dans `verify.sh`.
2. L'agent **Themis** (compliance officer, K.5 — *deferred to T7*) ouvre une
   issue de revue mensuelle via le hook `forge review-standards`.
3. Le mainteneur revoit le standard, met à jour `last_reviewed` et
   `expires_at`, et ajoute une entrée dans `.forge/standards/REVIEW.md`.
4. Si la revue conclut REPLACE / DEPRECATE, un nouveau Forge change est
   ouvert (proposal → specs → design → tasks → implement) qui amende le
   standard ; l'ancien fichier reste en place jusqu'à archive du change.

WARN n'est jamais bloquant : une expiration n'arrête pas la production.
Le but est de signaler une dette de revue, pas de geler le pipeline.

## Structural exception

Certaines décisions sont **structurelles** : elles définissent l'identité
de Forge plutôt qu'un choix technique amendable. Pour celles-ci,
`exception_constitutional: true` ET `expires_at: never`. Elles sont
**explicitement listées ici** pour audit :

| Standard fichier        | Raison                                                                                                  | ADR de référence  |
|-------------------------|---------------------------------------------------------------------------------------------------------|-------------------|
| `transport.yaml`        | proto + Connect = source unique des contrats Spec→Code, structural au pipeline SDD de Forge             | ADR-003 + ADR-009 |
| `state-management.yaml` | flutter_bloc consacré comme cadre unique pour cohérence cross-project + alignement event-driven SDD     | ADR-006           |

Toute modification d'un standard structural exige une **procédure
d'amendement de Constitution** (Article XII) :

1. Discussion publique ≥ 7 jours via GitHub Discussions.
2. Proposal Forge change avec rationale + analyse d'impact sur les
   archétypes existants.
3. Vote BDFL (phase actuelle) ou comité (phase mature, futur amendement).
4. Bump Constitution version (mineure si extension, majeure si breaking).
5. Mise à jour synchronisée du standard structural.

`t4.test.sh::_test_t4_025` vérifie que ce document liste explicitement
`transport.yaml` et `state-management.yaml` dans la table ci-dessus.

## Themis hook (deferred — T7)

L'automation mensuelle de la revue (génération d'issues Forge changes pour
chaque standard expirant dans les 30 jours) est la responsabilité de
l'agent **Themis** (compliance officer, module K.5 du plan
`docs/new-archetypes-plan.md`). Themis n'est PAS livré dans ce change
(t4) ; sa livraison est planifiée en T7 lors des modules B.6/B.7.

Jusqu'à T7, la revue est manuelle : le mainteneur scanne `verify.sh`
pour les WARN d'expiration et ouvre les changes correspondants à la main.

## Linter integration

`constitution-linter.sh` (extension F.4) gagne une fonction
`lint_standards_expiry()` qui :

1. Walk `.forge/standards/*.yaml`.
2. Parse `expires_at` et `exception_constitutional`.
3. Si `expires_at < today` ET `exception_constitutional ≠ true` → WARN.
4. Le WARN incrémente le compteur global `verify.sh::WARN`, mais le
   gate global reste PASS (consistent avec F.4 Article XI.3 qui n'est
   également que WARN).

Opt-out via `FORGE_LINTER_SKIP_STANDARDS_EXPIRY=1` env var.

## Automated enforcement (J.7 — `validate-standards-yaml.sh`)

Depuis `j7-validate-standards-yaml` (2026-05-08), le contrat
frontmatter et les invariants lifecycle sont vérifiés automatiquement
par `bin/validate-standards-yaml.sh` (validator dédié, distinct de
`constitution-linter.sh`). Le validator est invoqué par `verify.sh`
section "Standards YAML Schema" pour chaque `.forge/standards/*.yaml`
top-level et par la harness `j7.test.sh` (CI matrix).

### Invariants bloquants (`[STD-FAIL]`)

- **FR-J7-001..010** : 8 champs obligatoires + types + patterns
  (SemVer pour `version`, ISO-8601 pour `last_reviewed`, kebab-case
  pour `linter_rule` non-null).
- **FR-J7-020** : couplage Article XII bidirectionnel —
  `expires_at: never` ⇔ `exception_constitutional: true`.
- **FR-J7-021** : `expires_at` strictement supérieur à
  `last_reviewed` quand les deux sont datés.
- **FR-J7-023** : la `version` déclarée DOIT apparaître dans le
  ledger `REVIEW.md` (full ledger scan, multi-entrée par
  `(file, version)` toléré).
- **FR-J7-030** : `linter_rule` non-null DOIT être référencé comme
  ancre de section (`echo "..."` ou `# ...`) dans
  `constitution-linter.sh`.
- **FR-J7-040..041** : entrées `forbidden:` sont des strings non-vides
  uniques.
- **FR-J7-050** : les `path:` de `index.yml` pointent vers des
  fichiers existants.

### Indicateurs informatifs (`[STD-INFO]`, non bloquants)

- **FR-J7-022** : la fenêtre `expires_at - last_reviewed` excède
  ~12 mois (lâche).
- **FR-J7-051** : un standard sur disque non référencé par aucune
  entrée de `index.yml` (orphelin légitime ou index incomplet).

### Validateur autonome

`bin/validate-standards-yaml.sh` est appelable seul :

```bash
bash bin/validate-standards-yaml.sh                # défaut .forge/standards/
bash bin/validate-standards-yaml.sh <dir>          # validate every *.yaml
bash bin/validate-standards-yaml.sh <file.yaml>    # single file
```

Sortie : `[STD-PASS]` (stdout) / `[STD-FAIL: ...]` (stderr) /
`[STD-INFO: ...]` (stdout). Exit codes 0 (PASS) / 1 (FAIL) /
2 (usage). Voir `docs/SCHEMA.md` § "Standard YAML schema" pour la
documentation utilisateur complète.
