# Kubernetes Standard

## Resource Organization

```
k8s/
├── namespaces/
│   ├── staging.yaml
│   └── production.yaml
├── base/                      # Kustomize base resources
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── servicemonitor.yaml
│   └── network-policy.yaml
└── overlays/
    ├── staging/
    │   ├── kustomization.yaml
    │   └── patch-replicas.yaml
    └── production/
        ├── kustomization.yaml
        ├── patch-replicas.yaml
        └── patch-resources.yaml
```

Or use Helm charts for parameterized deployments:

```
charts/
└── my-service/
    ├── Chart.yaml
    ├── values.yaml
    ├── values-staging.yaml
    ├── values-production.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        ├── configmap.yaml
        ├── hpa.yaml
        ├── pdb.yaml
        ├── ingress.yaml
        └── network-policy.yaml
```

---

## Namespace Per Environment

```yaml
# k8s/namespaces/production.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    managed-by: terraform
```

---

## Deployment

```yaml
# charts/my-service/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-service.fullname" . }}
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "my-service.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  revisionHistoryLimit: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0          # zero-downtime rolling update
  selector:
    matchLabels:
      {{- include "my-service.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-service.selectorLabels" . | nindent 8 }}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "{{ .Values.metrics.port }}"
    spec:
      serviceAccountName: {{ include "my-service.serviceAccountName" . }}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      terminationGracePeriodSeconds: 60

      initContainers:
        - name: db-migrate
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: ["/server", "migrate"]
          envFrom:
            - secretRef:
                name: {{ include "my-service.fullname" . }}-secrets

      containers:
        - name: server
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: IfNotPresent
          ports:
            - name: grpc
              containerPort: 50051
            - name: metrics
              containerPort: {{ .Values.metrics.port }}

          envFrom:
            - configMapRef:
                name: {{ include "my-service.fullname" . }}-config
            - secretRef:
                name: {{ include "my-service.fullname" . }}-secrets

          resources:
            requests:
              cpu: {{ .Values.resources.requests.cpu }}
              memory: {{ .Values.resources.requests.memory }}
            limits:
              cpu: {{ .Values.resources.limits.cpu }}
              memory: {{ .Values.resources.limits.memory }}

          livenessProbe:
            grpc:
              port: 50051
              service: ""            # empty = overall health
            initialDelaySeconds: 10
            periodSeconds: 30
            failureThreshold: 3

          readinessProbe:
            grpc:
              port: 50051
              service: ""
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 3

          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]

          volumeMounts:
            - name: tmp
              mountPath: /tmp

      volumes:
        - name: tmp
          emptyDir: {}
```

---

## Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-service.fullname" . }}
  namespace: {{ .Values.namespace }}
spec:
  selector:
    {{- include "my-service.selectorLabels" . | nindent 4 }}
  ports:
    - name: grpc
      port: 50051
      targetPort: grpc
      protocol: TCP
    - name: metrics
      port: 9090
      targetPort: metrics
      protocol: TCP
```

---

## ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-service.fullname" . }}-config
data:
  RUST_LOG: "info"
  OTLP_ENDPOINT: "http://otel-collector.observability.svc.cluster.local:4317"
  SERVICE_NAME: {{ .Chart.Name | quote }}
  SERVICE_VERSION: {{ .Chart.AppVersion | quote }}
  DEPLOYMENT_ENVIRONMENT: {{ .Values.environment | quote }}
```

Secrets are **never** in ConfigMaps. Use External Secrets Operator:

```yaml
# External secret — fetches from AWS Secrets Manager / Vault
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "my-service.fullname" . }}-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: {{ include "my-service.fullname" . }}-secrets
  data:
    - secretKey: DATABASE_URL
      remoteRef:
        key: /production/my-service/database-url
    - secretKey: JWT_SECRET
      remoteRef:
        key: /production/my-service/jwt-secret
```

---

## Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "my-service.fullname" . }}-pdb
spec:
  minAvailable: 1          # always keep at least 1 pod running during disruptions
  selector:
    matchLabels:
      {{- include "my-service.selectorLabels" . | nindent 6 }}
```

---

## Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "my-service.fullname" . }}-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "my-service.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

## Networking: Ingress via Kong

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "my-service.fullname" . }}-ingress
  annotations:
    konghq.com/plugins: "rate-limiting,jwt-auth,request-size-limiting"
    konghq.com/strip-path: "false"
spec:
  ingressClassName: kong
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /v1/
            pathType: Prefix
            backend:
              service:
                name: {{ include "my-service.fullname" . }}
                port:
                  name: grpc
```

---

## NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "my-service.fullname" . }}-network-policy
spec:
  podSelector:
    matchLabels:
      {{- include "my-service.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Allow from Kong ingress controller
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kong
      ports:
        - port: 50051
    # Allow Prometheus scraping
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
      ports:
        - port: 9090
  egress:
    # Allow DNS
    - ports:
        - port: 53
          protocol: UDP
    # Allow database
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: database
      ports:
        - port: 5432
    # Allow OTel collector
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: observability
      ports:
        - port: 4317
```

---

## values.yaml Reference

```yaml
namespace: production
environment: production
replicaCount: 3

image:
  repository: registry.example.com/my-service
  tag: "1.2.3"

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

autoscaling:
  minReplicas: 2
  maxReplicas: 10

metrics:
  port: 9090
```

---

## Rules

- **Infrastructure as Code only**: no `kubectl apply` of hand-crafted YAML in production; use Helm or Kustomize via CI
- **External secrets only**: never store secrets in ConfigMaps, manifests, or git; use External Secrets Operator
- **Rolling updates with `maxUnavailable: 0`**: zero-downtime deployments for all stateless services
- **Resource requests and limits are mandatory**: every container specifies CPU and memory bounds
- **Liveness and readiness probes are mandatory**: use gRPC health check for gRPC services
- **PDB ensures minimum availability**: set `minAvailable: 1` for services with >= 2 replicas
- **HPA scales on CPU 70% and memory 80%**: adjust thresholds per service profile
- **NetworkPolicy is deny-by-default**: whitelist only required ingress/egress
- **`runAsNonRoot: true` and `allowPrivilegeEscalation: false`** on all containers
- **Init containers run migrations**: database migrations run as init containers, not in application startup code
