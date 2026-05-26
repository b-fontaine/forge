# Exploration — `b8-observability-rearch`

> **Type** : research note (output `/forge:explore`, 2026-05-24)
> **Statut** : ratifiée — 4 décisions arbitrées par le mainteneur en fin de session
> **Servira d'input à** : 3 sous-changes (Coroot → SigNoz → OBI)
> **Source contexte** : known issue `v0.4.0-rc.2` (SigNoz pins rotted), §0.5
> `docs/new-archetypes-plan.md` (T5.3.2 ABANDONED 2026-05-20), B.8.8 du plan
>
> **CORRECTION NOTICE (2026-05-25)** : la table § 2 et le scope § 5.1
> ci-dessous affirment que GHCR force le v-prefix sur Coroot
> (`v1.20.2` obligatoire). C'était une **mis-lecture verify-then-pin**
> dans cette session d'exploration (background-task outputs
> mis-labelled). La convention réelle est **no v-prefix** —
> `ghcr.io/coroot/coroot:1.20.2` fonctionne, `:v1.20.2` retourne
> `manifest unknown`. Inversion attrapée au `/forge:implement` Phase 6
> par le L2 manifest-pull fixture. Voir
> `.forge/changes/b8-coroot-rehost/{design.md::ADR-B8-COR-001,
> open-questions.md::Q-001, evidence.md § 1}` pour les transcripts
> corrigés. La note d'exploration reste préservée per Article V
> (l'erreur fait partie de l'historique du raisonnement).

---

## 1. État actuel cartographié

`docker-compose.dev.yml` flagship `full-stack-monorepo / 1.0.0` ship 4 services
observability + manifests K8s base/overlays minimaux :

| Service compose | Image | Pin | Rôle | Verdict |
|---|---|---|---|---|
| `fsm-otel-collector` | `otel/opentelemetry-collector-contrib` | `0.96.0` | Ingestion OTLP gRPC :4317 / HTTP :4318 | ⚠️ remplacé par `signoz/signoz-otel-collector` dans nouvelle archi |
| `fsm-signoz-clickhouse` | `clickhouse/clickhouse-server` | `24.1.2-alpine` | Storage | ⚠️ bump 24.1.2 → 25.5.6 dans nouvelle archi |
| `fsm-signoz-query` | `signoz/query-service` | `0.55.1` | Query API | ❌ **rotted** (archi 3-services morte upstream) |
| `fsm-signoz-frontend` | `signoz/frontend` | `0.55.1` | UI (port 3301) | ❌ **rotted** |

`infra/k8s/base/` :
- OBI eBPF DaemonSet `grafana/beyla:2.0.1` (T.5 ratification `t5-otel-stack`)
- Coroot Deployment `coroot/coroot:1.4.4`

Aucun manifest K8s SigNoz/query/frontend aujourd'hui (split dev↔prod).

`processors.probabilistic_sampler` (ADR-OTEL-001) en place via
`otel-collector-config.yaml` (proportional / traceID / hash_seed=22 / ratios
100/100/10 dev/staging/prod).

`observability.yaml v1.1.0` (T.4 ratification) cite `backend: signoz` + bloc
`versions: {beyla: "2.0.1", coroot: "1.4.4"}`.

## 2. Verify-then-pin sur les 4 composants (lesson T5.3.2 institutionnalisée)

Évidence collectée via `docker manifest inspect` + Docker Hub tags API +
GitHub releases API + compose officiel upstream.

| Composant | Pin actuel | État upstream | Action requise |
|---|---|---|---|
| `signoz/query-service:0.55.1` + `signoz/frontend:0.55.1` | rotted (archi 3-services morte) | Remplacée par `signoz/signoz:v0.125.1` unifié + `signoz/signoz-otel-collector:v0.144.4` | **Rearch complète** |
| `otel/opentelemetry-collector-contrib:0.96.0` | OK | Remplacé par fork SigNoz dans nouvelle archi | Substitution composant |
| `grafana/beyla:2.0.1` | OK (encore tirable) | v3.15.0 dispo (2026-05-12) — **major bump 2→3** | Refresh (Beyla CHANGELOG à parcourir) |
| `coroot/coroot:1.4.4` | 🔴 **`docker.io denied: unauthorized`** | Migré vers **`ghcr.io/coroot/coroot:1.20.2`** (tag v-prefixé) | **Host migration + major bump 1.4→1.20** |

**Coroot écosystème étendu** (compose officiel) :
- `ghcr.io/coroot/coroot` (CE, libre, OSS)
- `ghcr.io/coroot/coroot-ee` (EE, paid via `${LICENSE_KEY:+-ee}`)
- `ghcr.io/coroot/coroot-node-agent` (agent per-node, non shippé par forge)
- `ghcr.io/coroot/coroot-cluster-agent` (agent cluster, non shippé par forge)

## 3. SigNoz nouvelle archi — décodage compose upstream

Source : `https://raw.githubusercontent.com/SigNoz/signoz/main/deploy/docker/docker-compose.yaml`

Topologie réelle : **5 services** (pas "1 unifié" comme suggéré §0.5) :

1. `zookeeper-1` (`signoz/zookeeper:3.7.1`) — coordination ClickHouse
2. `init-clickhouse` (`clickhouse/clickhouse-server:25.5.6`) — one-shot fetch
   binary `histogram-quantile` depuis GitHub releases SigNoz
3. `clickhouse` (`clickhouse/clickhouse-server:25.5.6`) — storage, mount
   `common/clickhouse/{config.xml,users.xml,custom-function.xml,cluster.xml}`
4. `signoz` (`signoz/signoz:v0.125.1`) — UI + query unifié, port **8080**
   (était 3301). Env-vars : `SIGNOZ_ALERTMANAGER_PROVIDER`,
   `SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_DSN`, `SIGNOZ_SQLSTORE_SQLITE_PATH`,
   `SIGNOZ_TOKENIZER_JWT_SECRET`. Volume `sqlite:/var/lib/signoz/`.
5. `otel-collector` (`signoz/signoz-otel-collector:v0.144.4`) — fork OTel
   contrib + bootstrap `migrate sync check` + OPAMP via
   `--manager-config=/etc/manager-config.yaml` (nouveau fichier
   `otel-collector-opamp-config.yaml`).

Conséquences :
- Adieu `signoz-config.yaml` (schéma `query-service` mort).
- Nouveau fichier `otel-collector-opamp-config.yaml` requis.
- Nouveau répertoire `clickhouse/{config.xml, users.xml, custom-function.xml, cluster.xml}` requis (à dériver du compose officiel SigNoz).
- Drop volume `signoz-clickhouse-data` existant (ClickHouse 24→25 + schema diff).
- Port UI 3301 → 8080 (vérifier collision avec autres services `fsm-` qui pourraient déjà utiliser 8080).
- `probabilistic_sampler` ADR-OTEL-001 SURVIT (collector reste OTel-flavored).
  Mais endpoint exporter `otlp/signoz` change : `signoz-otel-collector:4317`
  (pas `signoz-query:4317` qui n'existe plus).

## 4. Décisions arbitrées par le mainteneur (2026-05-24)

| # | Décision | Choix | Implication |
|---|---|---|---|
| 1 | Découpe | **Trio séparé** | 3 changes indépendants livrés successivement, revertabilité maintenue. Lesson T5.3.2 : monobloc rend rollback impossible. |
| 2 | Pin strategy | **Cadence différenciée** | SigNoz → `tagged_immutable + 30d REVIEW.md`. OBI/Coroot → 12 mois loose. Amendement minimal `observability.yaml` : nouveau champ optional `pin_review_cadence: 30d \| 12mo`. Article XII via standards-lifecycle amendment. |
| 3 | Bump standard | **v2.0.0 breaking** | Adopters perdent `signoz-config.yaml`, héritent de 2 nouveaux fichiers + 5 services au lieu de 4 + port UI 3301→8080 + hosting Coroot migré GHCR. |
| 4 | Ordre du trio | **Coroot d'abord** | Pilote bas-risque (effort `S`, juste host + tag change). Sert de répétition pour la cadence rearch. SigNoz ensuite (M-L, débloque rc), OBI dernier (le moins urgent). |

## 5. Trio de sous-changes proposé

### 5.1 `b8-coroot-rehost` — Premier (effort `S`)

Scope :
- Bump `coroot/coroot:1.4.4` → `ghcr.io/coroot/coroot:1.20.2` (host change +
  major bump, tag v-prefixé obligatoire côté GHCR).
- Update `infra/k8s/base/coroot-deployment.yaml.tmpl` (image registry change).
- Update `observability.yaml::versions.coroot` (recommandation : bump à
  v1.20.2 ; investiguer CHANGELOG pour breaking API ConfigMap si applicable).
- Decision documentée : `coroot-ee` paid out-of-scope ; `coroot-node-agent` +
  `coroot-cluster-agent` deferred (à revisiter post-rearch si Coroot doit
  faire de la vraie discovery).
- Janus/Demeter check : hosting US (Coroot Inc, US-incorporated) — vérifier
  K3-RULE-001 (jurisdiction T3 forbidden ?) ; sinon documenter T1/T2 OK + T3
  candidate à substitution.

### 5.2 `b8-signoz-unified` — Deuxième (effort `M`-`L`)

Scope :
- Compose-dev : 4 services → 5 services (zookeeper + init-clickhouse +
  clickhouse@25.5.6 + signoz + signoz-otel-collector).
- Suppression `signoz-config.yaml.tmpl` ; création
  `otel-collector-opamp-config.yaml.tmpl` + 4 fichiers `clickhouse/*.xml.tmpl`.
- `otel-collector-config.yaml.tmpl` : conserver `probabilistic_sampler`
  ADR-OTEL-001 (proportional / traceID / hash_seed=22 / ratios), changer
  exporter endpoint `signoz-otel-collector:4317`, ajouter OPAMP manager
  config wiring.
- Update `infra/CLAUDE.md.tmpl` § "Privileged DaemonSet" + § "Sampler
  overlay" pour refléter nouveau bootstrap.
- Standards : `observability.yaml v1.1.0 → v2.0.0` breaking, ajouter bloc
  `versions.signoz` + `versions.signoz_collector` + `pin_review_cadence: 30d`
  pour SigNoz uniquement.
- K8s parity : décision deferred à `b8-signoz-unified` design phase (sous-Q
  Q-B8.8-006 du rapport explore).

### 5.3 `b8-obi-refresh` — Troisième (effort `S`)

Scope :
- Bump `grafana/beyla:2.0.1` → `grafana/beyla:3.15.0` (major bump).
- Parcourir Beyla 2→3 CHANGELOG via Context7 (capabilities Linux changes ?
  RBAC ? ConfigMap schema ?).
- Update OBI DaemonSet annotations / capabilities si Beyla 3.x change.
- Update `observability.yaml::versions.beyla` à `3.15.0` (compatible avec
  major bump déjà breaking v2.0.0).
- Régression à valider : Aegis review verbatim (capabilities set, kernel
  min 5.8 inchangé, RBAC).

## 6. Risques transverses + dépendances

- **Coroot major bump 1.4 → 1.20** : 16 minor bumps écartés, breaking API
  probable côté ConfigMap (à vérifier).
- **SigNoz cadence 2 semaines** : v0.125.1 risque d'être obsolète avant que
  `b8-signoz-unified` soit livré. → `pin_review_cadence: 30d` ledger
  obligatoire dès archive.
- **Beyla 2 → 3 major** : Grafana donation à OTel a peut-être renommé
  l'image (`otel/opentelemetry-ebpf-instrumentation` candidate ?). À
  vérifier avant pin Beyla 3.x.
- **Hosting Coroot company (US)** : si T3 EU-strict, Coroot CE peut tomber
  sous K3-RULE-001. À documenter par Demeter dans `b8-coroot-rehost`.
- **OPAMP nouveauté** : `signoz-otel-collector --manager-config` shim,
  potentiel d'incompatibilité avec sampler proportional si OPAMP override
  côté serveur. À tester en L2 fixture.
- **Aucun adopter actuel** sur `full-stack-monorepo/1.0.0` n'utilise la
  stack obs en prod (T5.3.2 ABANDONED implique que `task validate` n'a
  jamais passé end-to-end depuis 2026-05-10). Donc l'impact "breaking" est
  théorique pour les adopters early-bird, réel pour les nouveaux scaffolds.

## 7. Sources

- `docs/new-archetypes-plan.md` §0.5 (T5.3.2 ABANDONED — investigation
  2026-05-20)
- `docs/new-archetypes-plan.md` §4.2 B.8.8
- `.forge/standards/observability.yaml` v1.1.0 (T.4 ratification 2026-05-04
  + T.5 bump 2026-05-09)
- `https://hub.docker.com/v2/repositories/signoz/signoz/tags`
- `https://hub.docker.com/v2/repositories/signoz/signoz-otel-collector/tags`
- `https://hub.docker.com/v2/repositories/grafana/beyla/tags`
- `https://api.github.com/repos/coroot/coroot/releases`
- `https://raw.githubusercontent.com/SigNoz/signoz/main/deploy/docker/docker-compose.yaml`
- `https://raw.githubusercontent.com/coroot/coroot/main/deploy/docker-compose.yaml`
- `docker manifest inspect` : `signoz/signoz:latest` ✅,
  `signoz/signoz-otel-collector:latest` ✅, `grafana/beyla:2.0.1` ✅,
  `coroot/coroot:1.4.4` ❌ `denied: unauthorized`,
  `ghcr.io/coroot/coroot:1.20.2` ✅.
