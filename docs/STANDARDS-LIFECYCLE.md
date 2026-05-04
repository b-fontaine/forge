# Forge standards — lifecycle policy

> **For adopters**. This document explains how Forge standards age, when
> they are reviewed, and how the framework guards against fossilisation.
> The internal canonical version lives at
> `.forge/standards/global/standards-lifecycle.md` ; this is the public
> summary.

## Why a lifecycle ?

Forge consacre certains choix techniques (state management, transport,
persistence, identity, observability, orchestration) sous forme de
**standards versionnés** dans `.forge/standards/*.yaml`. Le risque sans
gouvernance : un standard qui survit à sa pertinence technique et fossilise
le framework, ou un standard amendé sans contrainte qui érode la cohérence.

Le compromis Forge :

- **Cycle de revue par défaut : 12 mois.** Tout standard porte un
  `expires_at` ISO-8601 ; à expiration, un WARN apparaît dans `verify.sh`.
- **Exception structurelle.** Deux standards sont consacrés comme
  **structurels** par décision constitutionnelle (Article XII) et
  échappent au cycle 12 mois : `transport.yaml` (proto + Connect) et
  `state-management.yaml` (flutter_bloc). Les amender exige une procédure
  d'amendement de Constitution.

## Comment lire un standard

Tout `.forge/standards/*.yaml` ouvre par un frontmatter uniforme :

```yaml
version: "1.0.0"                  # version propre du standard
last_reviewed: 2026-05-04          # date de revue la plus récente
expires_at: 2027-05-04             # ou "never" si exception_constitutional
exception_constitutional: false    # true => structural (Article XII only)
linter_rule: <id-or-null>          # rule that enforces this standard
enforcement:
  ci_blocking: false               # FAIL CI ou non
  pre_commit_hook: false           # block local commit
forbidden: [...]                   # libs / providers / patterns disallowed
rationale: |
  Why this standard exists.
```

## Les 6 standards consacrés (2026-05-04)

| Standard               | Version | Expires_at         | Exception structurelle | Source                                                |
|------------------------|---------|--------------------|------------------------|-------------------------------------------------------|
| `transport.yaml`        | 1.0.0   | never              | YES (ADR-003 + ADR-009)| `docs/ARCHITECTURE-TARGET.md` §4.2 / §4.7             |
| `state-management.yaml` | 1.0.0   | never              | YES (ADR-006)          | `docs/ARCHITECTURE-TARGET.md` §4.1 ADR-006            |
| `observability.yaml`    | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.8 ADR-008            |
| `orchestration.yaml`    | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.6 ADR-002            |
| `identity.yaml`         | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.9 ADR-007            |
| `persistence.yaml`      | 1.0.0   | 2027-05-04         | no                     | `docs/ARCHITECTURE-TARGET.md` §4.5 ADR-010            |

## Cycle de revue

1. À expiration (`expires_at < today`), `verify.sh` émet un WARN. Le WARN
   n'est PAS bloquant ; il signale une dette de revue.
2. Le mainteneur revoit le standard, met à jour `last_reviewed` /
   `expires_at`, et ajoute une entrée dans `.forge/standards/REVIEW.md`.
3. Si la revue conclut REPLACE / DEPRECATE, un nouveau Forge change est
   ouvert (proposal → specs → design → tasks → implement) qui amende le
   standard.
4. À partir de T7, l'agent **Themis** (compliance officer) automatise
   ce cycle via le hook `forge review-standards`.

## Exception structurelle : pourquoi ?

`transport.yaml` et `state-management.yaml` définissent **l'identité de
Forge**, pas un choix technique amendable :

- **transport.yaml** — proto + Connect = source unique des contrats
  Spec→Code. Changer ce standard reviendrait à redéfinir le pipeline SDD
  de Forge.
- **state-management.yaml** — flutter_bloc consacré comme cadre unique
  pour cohérence cross-project + alignement event-driven SDD. Changer
  ce standard casserait l'identité « un seul cadre canonique » assumée
  par Forge.

Pour les amender :

1. Discussion publique ≥ 7 jours via GitHub Discussions.
2. Forge change avec rationale + analyse d'impact sur les archétypes.
3. Vote BDFL (phase actuelle) ou comité (phase mature).
4. Bump Constitution version (mineure si extension, majeure si breaking).
5. Mise à jour synchronisée du standard.

## Document de référence

- `docs/ARCHITECTURE-TARGET.md` — audit architectural cible Forge 2026
  (10 ADRs ratifiés par `t4-adr-ratification`, sha256 pinné, drift gate
  actif via `t4.test.sh`).
- `docs/new-archetypes-plan.md` — plan post-v0.3.0 (taxonomie 5
  archétypes, modules B.6/B.7/B.8/B.9, compliance T1/T2/T3).
- `.forge/standards/REVIEW.md` — ledger append-only des événements de
  revue.
- `.forge/standards/global/standards-lifecycle.md` — version canonique
  interne, source de vérité.
