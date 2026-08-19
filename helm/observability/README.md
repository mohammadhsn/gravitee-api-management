# Gravitee APIM — observability companion chart

Ports the observability services from `docker/quick-setup/keycloak` to Kubernetes:
**Prometheus + Grafana** (metrics), **Kibana** (queries the Gravitee analytics indices),
**Logstash** (log ingest endpoint, off by default).

Deployed as its **own Helm release** next to `apim`, deliberately not merged into
`helm/`. Reasons: the Gravitee chart is upstream and gets version-bumped, so adding
templates there means merge conflicts on every bump; `helm package helm/` (the air-gap
artifact) stays a clean APIM chart; and these workloads have a different lifecycle from
the API platform. Everything is namespace-local, so nothing else changes.

## Install

Two steps — the APIM release has to expose its metrics first.

```bash
# 1. turn the Gravitee node APIs on (APIM release)
helm upgrade apim ./apim-4.11.0.tgz -n gravitee \
  -f helm/deploy/values-common.yaml \
  -f helm/prod/values-prod.yaml \
  -f helm/prod/values-observability.yaml

# 2. deploy the observability release into the SAME namespace
helm install obs helm/observability/ -n gravitee \
  --set ingress.host=apim.example.com \
  --set ingress.ingressClassName=nginx \
  --set ingress.tls.secretName=apim-tls
```

Reachable on the same host as the Console, alongside `/console` and `/devportal`:

| Path | Service |
|---|---|
| `/prometheus` | Prometheus |
| `/grafana` | Grafana (`admin` / `grafana.adminPassword`) |
| `/kibana` | Kibana |

Grafana arrives with the Prometheus datasource wired and both Gravitee dashboards
provisioned into a **Gravitee** folder — *HTTP Server & Client* and *Node Runtime & JVM*,
carried over verbatim from the compose stack.

## Step 1 is not optional

Prometheus scrapes `/_node/metrics/prometheus` on the Gravitee node API, which needs
**three** things true. Miss any one and the target is simply `DOWN` with no useful error:

1. `services.metrics.enabled: true` — the registry itself
2. `services.core.http.host: 0.0.0.0` — the management API defaults to **`localhost`**, so
   a scrape from another pod connects and gets nothing. The gateway already defaults to
   `0.0.0.0`; only the API needs the override.
3. `services.core.service.enabled: true` — puts the port on the ClusterIP Service.
   `externalPort` is commented out in the chart defaults and must be set explicitly.

`helm/prod/values-observability.yaml` does all three, for both components.

## Verify

```bash
kubectl -n gravitee port-forward svc/obs-observability-prometheus 9090:9090
# then open http://localhost:9090/prometheus/targets — both jobs must be UP:
#   gio-gateway   -> apim-gateway:18082
#   gio-mgmt-api  -> apim-api:18083
```

A target stuck `DOWN` with `connection refused` means item 2 or 3 above is missing.
`401 Unauthorized` means `targets.auth.password` disagrees with the APIM release's
`services.core.http.authentication.password`.

## Security notes before production

- **Node API basic auth** defaults to `admin` / `adminadmin` (the chart default). It is
  written to a Secret and read by Prometheus via `password_file`, so it never lands in a
  ConfigMap — but change it, on both releases, and prefer `targets.auth.existingSecret`.
- **Grafana admin** defaults to `admin`/`admin`. Change it or set `grafana.existingSecret`.
- These three paths sit on the **same host and ingress** as the Console. Anyone who can
  reach the Console can reach Grafana's login page. Put them on an internal-only host, or
  restrict by source IP at the ingress, if that is not acceptable.

## Logstash is off by default, and that is deliberate

Its only input is `beats` on 5044 and the pipeline does **no** parsing — it forwards raw
events to `logs-YYYY.MM.dd`. In compose, Filebeat fed it. There is **no Filebeat here**:
container stdout is already collected by the platform's node-level agent, and a second
DaemonSet mounting the container runtime socket would duplicate logs and need
root-on-node. So Logstash would start and sit idle.

Enable it only when you have a producer, and point that producer at
`obs-observability-logstash:5044`.

Nothing is lost by leaving it off: Gravitee's **analytics** never travelled through
Logstash. The gateway's Elasticsearch reporter writes straight to the `gravitee-*`
indices, which is what the Console dashboards and Kibana both read.

## Air-gapped

Set the registry once; it prefixes all four images while preserving their paths:

```bash
helm install obs helm/observability/ -n gravitee --set global.imageRegistry=registry.internal
```

All four are already in `helm/prod/mirror-images.sh` (Logstash included, so the bundle is
complete if you switch it on later inside the air gap).

## Capacity

Kibana and Logstash both point at the **same Elasticsearch as Gravitee's analytics**,
which the prod overlay sizes as a single node with 30Gi. Kibana only reads, so it is
cheap. Logstash *writes*, and cluster-wide container logs would dwarf the analytics
volume — give ES more disk, or a separate cluster, before pointing real log traffic at it.
