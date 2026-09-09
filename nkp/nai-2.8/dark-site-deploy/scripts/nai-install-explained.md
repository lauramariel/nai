# NAI 2.8 Dark-Site Install — Process & Architecture

Reference companion to `README.md`. Explains what the three install scripts in
`dark-site-deploy/scripts/` do, how the Helm charts in `../../charts/` fit
together, and how request routing works once NAI is up.

> Scope: the **install** workflow (`01`/`02`/`03`). The registry-seeding
> scripts (`00-push-charts.sh`, `00-push-images.sh`) are out of scope here — they
> only mirror charts and images into the private registry beforehand.

---

## 1. Big picture

Airgapped install of **Nutanix Enterprise AI (NAI) 2.8** onto an existing
**NKP** (Nutanix Kubernetes Platform) cluster, driven from a workstation with
`kubectl` / `helm` access to the target cluster.

| Script | Layer it installs | Namespaces touched |
|---|---|---|
| `01-install-dependencies.sh` | Platform layer — Envoy Gateway, KServe, OpenTelemetry operator, LeaderWorkerSet | `envoy-gateway-system`, `kserve`, `opentelemetry`, `lws-system`, `nai-system` |
| `02-install-nai.sh` | NAI product — `nai-operators` then `nai-core` | `nai-system` (+ `nai-admin`, `nai-admin-extensions` created by the chart) |
| `03-post-install.sh` | Swap in the real TLS certificate on the ingress Gateway | `nai-system` |

Assumed already present on the cluster:

- **CloudNativePG (CNPG)** — the install in `01` is commented out; expected to
  come from the NKP application catalog.
- **cert-manager** — charts reference cert-manager `Issuer`s / webhooks (e.g. the
  AI Gateway controller's mutating webhook cert).

### Layering

```
NKP cluster  (+ CloudNativePG, cert-manager assumed present)
  └─ 01: Envoy Gateway (AI Gateway mode) · KServe (RawDeployment) · OTel Operator · LeaderWorkerSet
       └─ 02a: nai-operators  — CRDs, clickhouse/valkey/db operators, AI Gateway controller
            └─ 02b: nai-core  — API, UI, IAM, RAG, model-serving control plane, Gateway + routes
                 └─ 03: real TLS cert patched onto nai-ingress-gateway
```

---

## 2. Configuration (`~/.env`)

Every script begins with `source ~/.env`. Seed it from `sample.env`:

| Variable | Example | Used for |
|---|---|---|
| `IMAGE_REGISTRY_URL` | `registry.example.com/bootcamps` | Private registry **including** project path. Charts are pulled as OCI artifacts from here; NAI images live at `$IMAGE_REGISTRY_URL/$PROJECT/nai-*`. |
| `PROJECT` | `nutanix` | Image sub-path segment. |
| `NAI_DEFAULT_RWO_STORAGECLASS` | `nutanix-volume` | RWO storage: nai-db, clickhouse, valkey, labs. |
| `NAI_API_RWX_STORAGECLASS` | `nutanix-files` | RWX storage: nai-api model store, OTel collector PVCs. |
| `NKP_WORKSPACE_NAMESPACE` | `kommander` | Added to monitoring `ServiceMonitor` namespace selectors. |
| `REGISTRY_USERNAME` / `REGISTRY_PASSWORD` / `REGISTRY_EMAIL` | | Credentials baked into the per-namespace image pull secret. |
| `IMAGE_PULL_SECRET` | `registry-image-pull-secret` | Name of the docker-registry secret created in each namespace. |

`../../charts/` holds the same 10 chart tarballs locally (identical to what `01`
pulls from the registry):

```
gateway-crds-helm-v1.8.1.tgz          opentelemetry-operator-0.114.1.tgz
gateway-helm-v1.8.1.tgz               lws-v0.8.0.tgz
kserve-crd-v0.19.0.tgz                nai-operators-2.8.0.tgz
kserve-llmisvc-crd-v0.19.0.tgz        nai-core-2.8.0.tgz
kserve-llmisvc-resources-v0.19.0.tgz
kserve-resources-v0.19.0.tgz
```

---

## 3. `01-install-dependencies.sh` — platform layer

### 3.1 Namespaces + image pull secrets

Creates `envoy-gateway-system`, `kserve`, `opentelemetry`, `lws-system`,
`nai-system`, and a `docker-registry` secret named `registry-image-pull-secret`
in each. Idempotent (`kubectl ... --dry-run=client -o yaml | kubectl apply -f -`).

### 3.2 Pull charts

`helm pull oci://$IMAGE_REGISTRY_URL/<chart> --version <v>` for all 10 charts into
the working directory as `.tgz`.

### 3.3 Render the Envoy Gateway config

`envsubst < templates/eg-config-for-gateway-mode.yaml.template > eg-config-for-gateway-mode.yaml`
(the only substitution is `REGISTRY`). This file puts Envoy Gateway into **AI
Gateway mode**:

- **Extension manager** → gRPC to `ai-gateway-controller.nai-system.svc.cluster.local:1063`
  with `hooks.xdsTranslator` (`listener` / `route` / `cluster` / `secret`
  `includeAll`, post-hooks on `Translation` / `Cluster` / `Route`),
  `maxMessageSize: 11Mi`.
- **Backend resource** `InferencePool` (`inference.networking.k8s.io`) registered,
  `extensionApis.enableBackend: true`, `enableEnvoyPatchPolicy: true`.
- **Rate limiting** backed by Redis-protocol **Valkey sentinel**:
  `url: "mymaster,nai-valkey-sentinel.nai-system.svc.cluster.local:26379"`,
  and the EG `rateLimitDeployment` is patched with
  `REDIS_TYPE=sentinel`, `REDIS_PIPELINE_WINDOW=150us`.

> Forward reference: `eg-config` points at a Service (`ai-gateway-controller`)
> that does not exist until `02` runs. Envoy Gateway tolerates this and
> reconciles once the controller comes up.

### 3.4 Installs (in order)

| # | Release | Chart | Namespace | Key `--set` overrides |
|---|---|---|---|---|
| 1 | `eg` (CRDs) | `gateway-crds-helm-v1.8.1.tgz` | cluster-scoped | `helm template ... \| kubectl apply --server-side --force-conflicts`; `crds.gatewayAPI.enabled=true`, `crds.envoyGateway.enabled=true` |
| 2 | `eg` | `gateway-helm-v1.8.1.tgz` | `envoy-gateway-system` | `global.images.envoyGateway.image=…/nai-gateway:v1.8.1`, `global.images.ratelimit.image=…/nai-ratelimit:1e50889b`, `global.imagePullSecrets[0].name`, `-f eg-config-for-gateway-mode.yaml` |
| 3 | `kserve-crd` | `kserve-crd-v0.19.0.tgz` | `kserve` | — |
| 4 | `kserve` | `kserve-resources-v0.19.0.tgz` | `kserve` | `deploymentMode=RawDeployment`, `gateway.disableIngressCreation=true`, controller + `nai-kube-rbac-proxy` images overridden |
| 5 | `kserve-llmisvc-crd` | `kserve-llmisvc-crd-v0.19.0.tgz` | `kserve` | — |
| 6 | `kserve-llmisvc-resources` | `kserve-llmisvc-resources-v0.19.0.tgz` | `kserve` | `createSharedResources=false`, `llmisvc.createGIECRDs=false` (nai-operators owns the Gateway-Inference-Extension CRDs), llmisvc controller image overridden |
| 7 | `opentelemetry-operator` | `opentelemetry-operator-0.114.1.tgz` | `opentelemetry` | `manager.image.repository`, `manager.collectorImage.repository` overridden |
| 8 | `lws` | `lws-v0.8.0.tgz` | `lws-system` | `image.manager.repository=…/nai-lws` — enables multi-node / pipeline-parallel model serving |

`helm list -A | grep -E "…"` is printed before and after.

### 3.5 Notes

- **KServe RawDeployment + `disableIngressCreation=true`**: KServe creates no
  ingress of its own. Model pods are reached via the NAI gateway or in-cluster by
  `nai-api`.
- **CloudNativePG** install is commented out (NKP catalog).

---

## 4. `02-install-nai.sh` — NAI product

1. **Wait** for the KServe controller: `kubectl wait --for condition=ready pods -l app.kubernetes.io/name=kserve-controller-manager -n kserve` (retried).
2. **Render override files** with `envsubst`:
   - `templates/darksite-nai-operators.yaml.template` → `darksite-nai-operators.yaml`
   - `templates/darksite-nai-core.yaml.template` → `darksite-nai-core.yaml`

   These are pure **image / registry / storage overlays** — every NAI image
   pointed at `$IMAGE_REGISTRY_URL/$PROJECT/nai-*`, plus
   `global.imagePullSecrets`, storage classes, and the monitoring namespace
   selectors.
3. **`nai-operators`** → `nai-system` (`--wait --timeout 15m -f darksite-nai-operators.yaml`).
4. **Wait loops** (`until kubectl wait ...`) for:
   - `app.kubernetes.io/name=nai-operators` (nai-system)
   - `app.kubernetes.io/name=nai-clickhouse-operator` (nai-system)
   - `app.kubernetes.io/name=postgresql` (nai-system) — the `nai-db-iep-1` pod
   - `serving.kserve.io/gateway=nai-ingress-gateway` (envoy-gateway-system) — the Envoy data-plane pod
5. **`nai-core`** → `nai-system` (`--wait --timeout 15m --set naiLabs.enabled=true -f darksite-nai-core.yaml`).
6. Trailing comment lists optional `--set` tunables: `gateway.replicaCount`,
   `naiApi.replicaCount`, `naiDatabase.postgresConfig.maxConnections` (default 1000).

### 4.1 What `nai-operators` contains

Chart `dependencies` (all vendored as `charts/` subcharts):

| Subchart | Version | Role |
|---|---|---|
| `nai-clickhouse-crd` | 1.1.0 | ClickHouse `Installation` CRD |
| `nai-clickhouse-operator` | 1.2.0 | Altinity ClickHouse operator + metrics exporter |
| `ai-gateway-crds-helm` | v1.0.0 | Envoy AI Gateway CRDs (see §6) |
| `ai-gateway-helm` | v1.0.0 | Envoy AI Gateway **controller** + webhook (see §6) |

Plus `templates/`: `nai-iep-operator/`, `nai-database/` (CNPG `Cluster`
resources), `nai-valkey/` (sentinel-fronted cache — default XS profile: 1 data
pod + 1 Sentinel), `gie/crds.yaml` (Gateway API Inference Extension —
`InferencePool`).

### 4.2 What `nai-core` contains

Chart `dependencies`: `oauth2-proxy` (7.12.17), `nai-clickhouse-keeper` (2.0.0),
`nai-clickhouse-server` (2.0.0), `nai-clickhouse-schemas` (2.1.4).

`templates/nai-components/` deploys the product: `nai-api`, IEP operator +
processors (model / datasource / batch-inference / finetuning), inference UI,
`nai-jobs`, `nai-agent`, `nai-labs` (RAG app, enabled by `naiLabs.enabled=true`),
the full IAM stack (`iam-proxy`, `iam-proxy-control-plane`, `themis`,
`user-authn`, `iam-ui`, `bootstrap`), `oauth2-proxy`, ClickHouse
keeper/server/schemas, monitoring (OTel collector, target allocator), and all the
Gateway-API objects — the `Gateway`, `GatewayClass`, `EnvoyProxy`,
`ClientTrafficPolicy`, `GatewayConfig`, `SecurityPolicy` (ext-authz),
`Backend`, `AIServiceBackend`, `ReferenceGrant`s, and `HTTPRoute`s (see §7).

### 4.3 Helm hooks (upgrade path)

`nai-core` ships `pre-upgrade` / `post-upgrade` jobs (`./nai-iep helm-hooks …`)
that run schema / config migrations, plus a `pre-delete` job that cleans up the
ClickHouse `Installation`.

---

## 5. `03-post-install.sh` — TLS certificate

1. Wait for all `nai-system` pods `Ready`.
2. Create a `nai-cert` TLS secret in `nai-system` from local PEM files
   (`CERT_PATH` / `KEY_PATH` are hard-coded to `$HOME/certs/tmelab/…` — **edit
   these**).
3. `kubectl patch gateway nai-ingress-gateway -n nai-system` — replace the HTTPS
   listener's `certificateRefs[0].name` (`spec/listeners/1/tls/...`) with
   `nai-cert`, replacing the placeholder secret the chart shipped.

---

## 6. Deep dive: the AI Gateway (`ai-gateway-crds-helm`, `ai-gateway-helm`, ExtProc)

All three are the upstream **Envoy AI Gateway** project
(`aigateway.envoyproxy.io`, `github.com/envoyproxy/ai-gateway`), vendored into
`nai-operators` at `v1.0.0`. The dark-site override only repoints images:

```yaml
# darksite-nai-operators.yaml.template
ai-gateway-helm:
  extProc:
    image:
      repository: ${IMAGE_REGISTRY_URL}/${PROJECT}/nai-ai-gateway-extproc
  controller:
    image:
      repository: ${IMAGE_REGISTRY_URL}/${PROJECT}/nai-ai-gateway-controller
```

### 6.1 `ai-gateway-crds-helm` — CRDs only

| CRD (`aigateway.envoyproxy.io`) | Purpose |
|---|---|
| `aigatewayroutes` | AI-aware route: match on model name / API schema, choose a backend |
| `aiservicebackends` | A model-serving backend + its API schema (OpenAI / Cohere / Anthropic) |
| `backendsecuritypolicies` | Upstream credential injection (API keys, AWS/GCP/Azure auth) toward providers |
| `quotapolicies` | Token-based quota enforcement |
| `mcproutes` | MCP (Model Context Protocol) proxy routing |
| `gatewayconfigs` | Per-Gateway knobs for the injected ExtProc (e.g. resources) |

(`nai-operators/templates/gie/crds.yaml` additionally installs the Gateway API
Inference Extension CRDs — `InferencePool` — hence `01` sets
`kserve.llmisvc.createGIECRDs=false` and `eg-config` registers `InferencePool` as
a backend resource.)

### 6.2 `ai-gateway-helm` — the controller

One `Deployment`, `ai-gateway-controller`, in `nai-system` (`replicaCount: 1`,
leader election on). Its `Service` exposes:

| Port | Name | Consumer |
|---|---|---|
| `1063` | `grpc` | Envoy Gateway's **extension manager** (`eg-config` FQDN target) |
| `9443` | `mutating-webhook` | Kubernetes API server admission |
| `8080` | `http-metrics` | Prometheus / OTel |
| `18002` | `ratelimit-xds` | pushes rate-limit config to the EG ratelimit deployment |

Three jobs:

1. **Kubernetes controller** — watches the six AI-gateway CRDs, reconciles them
   into Envoy Gateway primitives (`HTTPRoute`, `Backend`, `EnvoyExtensionPolicy`,
   `EnvoyPatchPolicy`, xDS).
2. **Envoy Gateway extension server** — on every reconcile of
   `nai-ingress-gateway`, EG gRPC-calls this controller, which mutates the
   generated Envoy config to insert the `ext_proc` filter, its cluster,
   `InferencePool` routing, and secrets.
3. **ExtProc injector** — runs with `--extProcImage=<nai-ai-gateway-extproc>`
   (+ pull policy / secrets / log level) and injects the ExtProc **container into
   the Envoy data-plane pod**, connected over a Unix domain socket named
   `ai-gateway-extproc-uds`.

Controller args as configured in this install:

| Arg | Value | Source / meaning |
|---|---|---|
| `--rootPrefix` | `/enterpriseai/gateway` | `endpointConfig.rootPrefix` in `nai-operators` values |
| `--endpointPrefixes` | `openai:,cohere:,anthropic:` (all empty) | per-provider path segment under the root prefix. `nai-operators/values.yaml` overrides the subchart defaults (`/cohere`, `/anthropic`) to `""`, so **no** extra provider segment is added — every schema sits directly under `/enterpriseai/gateway`. |
| `--maxRecvMsgSize` | `11534336` (~11 MiB) | matches `extensionManager.maxMessageSize: 11Mi`; sized for ~1100 unified endpoints |
| `--quotaRateLimitServiceAddr` | `envoy-ai-gateway-ratelimit.envoy-gateway-system` | `QuotaPolicy` enforcement → EG ratelimit → Valkey |
| `--metricsRequestHeaderAttributes` | `x-nutanix-api-key-id:apiKeyId,…,x-nutanix-mcp-key-id:…` | maps Nutanix API-key / MCP headers into OTel metric labels (per-key usage accounting) |
| `--mcpSessionEncryptionSeed` / `Iterations` | (chart default seed) | MCP proxy session encryption — **change the seed for production** |

**Mutating webhook**: `ai-gateway-helm.controller.mutatingWebhook.certManager.enable: true`
in the dark-site override → cert-manager issues + rotates the webhook TLS cert.
The webhook targets pods labelled `app.kubernetes.io/managed-by: envoy-gateway`
(the Envoy data plane).

### 6.3 The ExtProc

An Envoy **external processing** (`ext_proc`) gRPC server. **Not a standalone
Deployment** — the controller injects it as a **sidecar into the
`nai-ingress-gateway` Envoy pods**. Image `nai-ai-gateway-extproc`.

Per AI API call it:

- Parses the request body in its declared schema (OpenAI / Cohere / Anthropic),
  routes by model name to the right `AIServiceBackend`, rewrites path / host /
  schema for cross-API translation.
- Extracts token usage from responses (including streamed SSE) → emits usage
  metrics and feeds rate-limit descriptors.
- Applies `BackendSecurityPolicy` (upstream credentials) and `QuotaPolicy`
  (token quotas via the ratelimit service).

Because it buffers bodies, `nai-core` compensates:

| Object | Adjustment | Why |
|---|---|---|
| `ClientTrafficPolicy` `client-buffer-limit` | `connection.bufferLimit` raised to `naiAIGateway.naiExtAuthSecurityPolicy.bodySizeLimit`; HTTP/2 tuned (`maxConcurrentStreams: 2000`, window sizes) | Envoy's 32 KiB default buffer is too small for AI payloads |
| `EnvoyProxy` `nai-envoyproxy-config` bootstrap | circuit breakers on cluster `ai-gateway-extproc-uds` raised 1024 → 50000; `http2.max_outbound_frames` 10k → 100k; `reset_with_error: false` | defaults cause `rq_pending_overflow` 5xx and spurious HTTP/2 resets under load |
| `GatewayConfig` `nai-ai-gateway-config` | `spec.extProc.kubernetes.resources` = `gateway.extProcResources` (2 CPU / 8 Gi) | ExtProc sidecar resources have no native `EnvoyProxy` field; bound to the Gateway via annotation `aigateway.envoyproxy.io/gateway-config: nai-ai-gateway-config` |

### 6.4 End-to-end wiring order

1. `01` installs Envoy Gateway; `eg-config` already points the extension manager
   at `ai-gateway-controller.nai-system:1063` (forward reference) and switches the
   ratelimit backend to Valkey sentinel.
2. `02a` (`nai-operators`) installs the AI-gateway CRDs + GIE CRDs + the
   `ai-gateway-controller` Deployment + cert-manager-backed mutating webhook.
3. `02b` (`nai-core`) creates `nai-ingress-gateway` (annotated with
   `aigateway.envoyproxy.io/gateway-config`), the `GatewayConfig`,
   `ClientTrafficPolicy`, the `AIServiceBackend`s (`nai-backend-openai`,
   `nai-backend-cohere`), the `Backend` `nai-backend` → `nai-api:7000`, and
   `ReferenceGrant`s allowing `AIGatewayRoute`s in `nai-admin` to reference the
   `AIServiceBackend`s. The IEP operator / `nai-api` then create `AIGatewayRoute`
   resources per model endpoint at runtime.
4. On reconcile, Envoy Gateway calls the controller → the ExtProc sidecar is
   injected and AI routing is programmed into Envoy.

---

## 7. The single front door: `nai-ingress-gateway`

There is **one** data plane and **one** entry point for NAI application traffic:

- One `Gateway` `nai-ingress-gateway` (HTTP `:80`, HTTPS `:443`), one
  `GatewayClass` `nai-gatewayclass`
  (`controllerName: gateway.envoyproxy.io/gatewayclass-controller`), one Envoy
  fleet managed by Envoy Gateway, one LoadBalancer Service.
- **Every** `HTTPRoute` in `nai-core` has `parentRefs: [{ name: nai-ingress-gateway }]`.
- `03-post-install.sh` patches the TLS cert on this one Gateway.

The **"AI Gateway" is a mode of this same gateway, not a second proxy.** The
ExtProc sidecar lives inside the `nai-ingress-gateway` Envoy pods and only
engages on routes the AI Gateway controller programs (`AIGatewayRoute`s).
Everything else rides the same Envoy as plain Gateway-API routing.

### 7.1 Route table (`nai-core`, all attach to `nai-ingress-gateway`)

| Route | Path match | Backend | Auth / notes |
|---|---|---|---|
| `nai-ui-httproute` | `/` → 301 `/nai`; `/nai` prefix | `nai-oauth2-proxy:80` | browser SSO via oauth2-proxy; adds HSTS/CSP/X-Frame headers |
| `nai-iam-protected-routes` | `/api/iam/` with `Authorization: Basic/Bearer` | `iam-proxy:443` | |
| `nai-iam-protected-routes` (rule 2) | `/api/iam` prefix | `nai-oauth2-proxy:80` | |
| `nai-iam-unprotected-routes` | OIDC well-known / login / token / `/ui/iam` | `iam-proxy:443` | no auth (login endpoints) |
| `oauth2-proxy-routes` | `/oauth2` prefix | `nai-oauth2-proxy:80` | |
| `nai-v1-mgmt-httproute` | `/api/enterpriseai/v1/` prefix | `nai-api:7000`; or `nai-oauth2-proxy:80` when header `X-Nutanix-Client-Type: ui` | management API (CLI vs UI) |
| `nai-v4-httproute` | `/api/enterpriseai/v4.0.a1/` prefix | `nai-api:7000` | labelled `nai.nutanix.com/extauth: enabled` |
| `nai-dataplane-httproute` | `/enterpriseai/v1/{chat/completions,completions,embeddings,rerank,models,images/generations,audio/transcriptions,audio/translations}`, `/enterpriseai/v2/rerank`, **`/enterpriseai/gateway/v1/models`** | `nai-api:7000` (300s timeout) | labelled `nai.nutanix.com/extauth: enabled` |
| `nai-ui-dataplane-httproute` | same dataplane paths **with** header `X-Nutanix-Client-Type: ui` | `nai-oauth2-proxy:80` | UI Playground traffic |
| `nai-agent-httproute` | `/nai/agent` prefix | `nai-oauth2-proxy:80` | only if `naiAgent.enabled` |
| `nai-labs-httproute` | `/nai/apps/rag` prefix | `nai-oauth2-proxy:80` | only if `naiLabs.enabled` |
| *(dynamic)* `AIGatewayRoute` in `nai-admin` | `/enterpriseai/gateway/...` (see §8) | `AIServiceBackend` → `nai-backend` → `nai-api:7000`, or external provider | created at runtime by IEP operator / nai-api |

### 7.2 ext-authz

`SecurityPolicy` `nai-extauth` exists in `nai-system`, `nai-admin`, and
`nai-admin-extensions`. It targets routes by name (`nai-dataplane-httproute`,
`nai-v4-httproute`) or by label (`nai.nutanix.com/extauth: enabled`) and makes an
external-authorization callout to `nai-api:7001`, which validates the API key and
injects identity / endpoint headers before the request reaches the backend:

```
X-Nutanix-Api-Key-Id / -Name / -Key      X-Nutanix-User-Id / -Name / -Group-Uuids
X-Nutanix-Endpoint-Engine / -Serving-Backend / -Id / -Type
X-Nutanix-NIM-API-Spec / -Served-Model-Name
```

`nai-admin-extensions` variant forwards MCP headers
(`X-Nutanix-Mcp-Key-Id / -Name / -Connector-Name`).

### 7.3 What does *not* go through `nai-ingress-gateway`

The Kubernetes API itself (kubectl / admin), Prometheus scraping component
metrics, pure in-cluster service-to-service calls, and NKP / Kommander's own
ingress. KServe creates no ingress (`disableIngressCreation=true`), so model pods
are never directly exposed — `nai-api` fronts them.

---

## 8. `/enterpriseai/v1` vs `/enterpriseai/gateway/v1`

Both prefixes can serve `/chat/completions` against the same in-cluster models.
The difference is the request pipeline: `/enterpriseai/v1/...` is NAI's native
dataplane (Envoy → ext-authz → `nai-api`), while `/enterpriseai/gateway/v1/...`
runs the AI Gateway pipeline (ExtProc: schema translation, token metering,
quota), which additionally can proxy to external providers.

| | `/enterpriseai/v1/chat/completions` | `/enterpriseai/gateway/v1/chat/completions` |
|---|---|---|
| **Matched by** | static `nai-dataplane-httproute` (plain `HTTPRoute`) | dynamic `AIGatewayRoute` in `nai-admin` (created by IEP operator / nai-api) |
| **Path origin** | NAI's native dataplane prefix | AI Gateway controller `--rootPrefix=/enterpriseai/gateway`; all provider prefixes empty, so the OpenAI schema lands at `<root>/v1/...` |
| **On-path processing** | Envoy → ext-authz `SecurityPolicy` (`nai-api:7001`) → `nai-api:7000` | Envoy → **ExtProc** (schema parse, model-name routing, token metering, `QuotaPolicy`, `BackendSecurityPolicy`) → `AIServiceBackend` |
| **ExtProc active?** | No — route is not an `AIGatewayRoute` (sidecar present on listener but not engaged) | Yes |
| **Ultimate backend** | `nai-api:7000` (then dispatches to the KServe model) | `nai-backend-openai` (`schema: OpenAI, prefix: /enterpriseai/v1`) → `nai-backend` → `nai-api:7000`; or an external provider |
| **Multi-provider / unified API** | No | Yes — the same root prefix also serves the Cohere schema (`nai-backend-cohere`, `version: /enterpriseai/v2` → `/enterpriseai/gateway/v2/rerank`) and the Anthropic schema (`/enterpriseai/gateway/v1/messages`). With the provider prefixes set to `""`, all three schemas share `/enterpriseai/gateway` and are told apart by sub-path. |

Overlap: `nai-dataplane-httproute` explicitly carves out
**`/enterpriseai/gateway/v1/models`** (only `/models`) → `nai-api:7000`, so model
discovery under the gateway prefix is answered directly by nai-api via static
route, while `/enterpriseai/gateway/v1/chat/completions` falls to the dynamic
`AIGatewayRoute`.

> The `AIGatewayRoute` specifics are inferred from the controller flags, the
> `AIServiceBackend` schema prefixes, and the one static `/models` carve-out —
> those routes are generated at runtime and are not in the chart.

---

## 9. Request-path summary

```
                          ┌───────────────────────────────────────────────┐
   client ── :443 ───────▶│  nai-ingress-gateway  (Envoy, 1+ replicas)     │
   (TLS: nai-cert)        │                                               │
                          │  ┌─────────────┐   ext_proc (UDS)             │
                          │  │  ExtProc    │◀──── only for AIGatewayRoutes │
                          │  │  sidecar    │      (/enterpriseai/gateway/…) │
                          │  └─────────────┘                              │
                          └───────┬───────────────────┬───────────────────┘
                                  │                   │
             plain HTTPRoute      │                   │  ext-authz SecurityPolicy
             (UI / IAM / mgmt)    │                   │  → nai-api:7001 (key check,
                                  ▼                   ▼     header injection)
                       nai-oauth2-proxy        nai-api:7000 ──▶ KServe LLMInferenceService
                       iam-proxy:443                            (multi-node via LWS)
                                                                       │
   QuotaPolicy / global rate limit ───▶ EG ratelimit ──▶ Valkey sentinel (nai-system:26379)
```

---

## 10. Quick reference — namespaces & releases

| Namespace | Releases / key workloads |
|---|---|
| `envoy-gateway-system` | `eg` (Envoy Gateway controller), `envoy-ai-gateway-ratelimit`, the `nai-ingress-gateway` Envoy data-plane pods |
| `kserve` | `kserve-crd`, `kserve`, `kserve-llmisvc-crd`, `kserve-llmisvc-resources` |
| `opentelemetry` | `opentelemetry-operator` |
| `lws-system` | `lws` |
| `nai-system` | `nai-operators`, `nai-core` — nai-api, IEP operator + processors, UI, IAM stack, oauth2-proxy, nai-jobs, nai-agent, nai-labs, ClickHouse (keeper/server), Valkey, CNPG `Cluster` (`nai-db-iep-1`), `ai-gateway-controller`, OTel collector |
| `nai-admin` | namespace + service accounts, `SecurityPolicy`, network policies, EPP config, dynamic `AIGatewayRoute`s |
| `nai-admin-extensions` | namespace + service accounts, MCP `SecurityPolicy`, network policies |
