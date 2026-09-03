# Documentation index

Every document this fork maintains, plus the upstream ones worth knowing about.

This repository is a fork of [gravitee-io/gravitee-api-management](https://github.com/gravitee-io/gravitee-api-management),
so its docs come from two places. The distinction matters when something looks
wrong: **ours** describes *this* deployment and is ours to fix; **upstream**
describes the product in general and is better fixed by a PR to upstream than by
a local edit that the next merge will conflict with.

Documents ending `.fa.md` / `-fa-` are Persian translations of their English
counterpart. They are maintained as pairs — **update both, or neither**, since a
stale translation is worse than an obvious gap.

---

## Using Gravitee (API producers and platform users)

| Document | What it covers |
| --- | --- |
| [en-gravitee-howto-guide.md](en-gravitee-howto-guide.md) | **Start here.** Task-oriented guide to Gravitee 4.x + Keycloak: core concepts, creating and publishing your first API, use-case tutorials, the transparent service-to-service token flow, audit logging and analytics, and documenting APIs in the portal. |
| [fa-gravitee-howto-guide.md](fa-gravitee-howto-guide.md) | Persian translation of the above. |

## Understanding the platform (engineers)

| Document | What it covers |
| --- | --- |
| [GRAVITEE_APIM_TECHNICAL_GUIDE_EN.md](GRAVITEE_APIM_TECHNICAL_GUIDE_EN.md) | Backend architecture, database structure, debugging from source, and the core API endpoints. Scoped to self-managed / Community Edition — enterprise-only features are deliberately excluded. |
| [GRAVITEE_APIM_TECHNICAL_GUIDE_FA.md](GRAVITEE_APIM_TECHNICAL_GUIDE_FA.md) | Persian translation of the above. |
| [`../CLAUDE.md`](../CLAUDE.md) | Not tracked in git (it is per-checkout), but it is the fastest orientation to the module layout, the build commands, and the architecture notes that bite. Worth reading before the technical guide. |

## Deploying

Ordered from the smallest setup to the largest.

| Document | What it covers |
| --- | --- |
| [`../docker/quick-setup/keycloak/`](../docker/quick-setup/keycloak/README.md) | **Ours.** The full demo stack on docker compose — APIM, Keycloak, nginx edge with HTTPS, Prometheus, Grafana, Kibana, Logstash, Filebeat, and a sample resource server. The closest thing to a single-command reproduction of the production topology. |
| [`../docker/quick-setup/keycloak/service-b/README.md`](../docker/quick-setup/keycloak/service-b/README.md) | **Ours.** The OAuth resource server used as a protected upstream in the tutorials. |
| [nginx-setup/setup-guide.en.md](nginx-setup/setup-guide.en.md) | **Ours.** Putting APIM behind nginx with TLS on a **single production VM**, where APIM already runs under docker compose. Use this when there is no Kubernetes. Persian: [setup-guide.fa.md](nginx-setup/setup-guide.fa.md). |
| [`../helm/prod/DEPLOY-BAREMETAL.md`](../helm/prod/DEPLOY-BAREMETAL.md) | **Ours.** The production runbook: deploying onto an existing bare-metal kubeadm cluster whose MetalLB and ingress-nginx are owned by the platform, with an **air-gapped** image flow and TLS from an internal CA. This is the authoritative deployment document. |
| [`../helm/observability/README.md`](../helm/observability/README.md) | **Ours.** The observability companion chart — Prometheus, Grafana, Kibana, Logstash, Filebeat — installed as a release separate from APIM. Includes the Kibana saved-object provisioning. |
| [`../helm/README.md`](../helm/README.md) | *Upstream.* Reference for every value the APIM chart accepts. Consult it for a value the runbook does not mention; do not treat its defaults as what this deployment uses. |
| [`../helm/TESTS.md`](../helm/TESTS.md) | *Upstream.* Running the chart's own unit tests. |
| [`../docker/README.md`](../docker/README.md) | *Upstream.* The `docker/` quick-setup catalogue — `make help` lists roughly 25 single-concern stacks (postgresql, redis-rate-limit, opensearch, native-kafka, opentelemetry-jaeger, …). Reach for one of these to isolate a single component, not to model production. |

### Deployment overlays worth knowing about

Not documents, but the files the runbook drives and the place to look when a
deploy behaves unexpectedly. Each carries substantial commentary in-file
explaining *why* a value is what it is:

- `../helm/deploy/values-common.yaml` — bugfix overlay shared by every environment
- `../helm/prod/values-prod.yaml` — production hostnames, TLS, single-node data layer
- `../helm/prod/values-airgap.yaml` — repoints every image at the internal registry
- `../helm/prod/values-observability.yaml` — exposes the Gravitee node APIs to Prometheus
- `../helm/prod/mirror-images.sh` — the complete image list, and the mirror/bundle/push flows
- `../helm/kind/` — a local kind cluster that mirrors the production topology (MetalLB + ingress-nginx + TLS), for rehearsing a change before it reaches bare metal
- `../helm/test-backend/` — an in-cluster upstream for answering "is this failure the gateway or the backend?"

---

## Conventions

- **Ours vs upstream** is decided by authorship, not location: the `docs/`
  tree, `helm/prod/`, `helm/observability/`, `helm/kind/`, `helm/test-backend/`
  and `docker/quick-setup/keycloak/` are ours. Everything else under `helm/`
  and `docker/` came from upstream.
- **English and Persian are peers.** Neither is generated from the other; both
  are edited by hand, so both need updating.
- **Add a new document to this index in the same commit.** An index that has to
  be re-derived is one nobody trusts.
