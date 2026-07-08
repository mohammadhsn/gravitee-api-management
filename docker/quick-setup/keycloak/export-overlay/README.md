# Gravitee APIM + Keycloak — docker compose

APIM (Gateway, Management API, Console, Developer Portal) with Keycloak as the
OIDC identity provider, a `service-b` demo backend, and an observability stack:
**ELK** (Elasticsearch + Kibana + Logstash/Filebeat) for logs and **Prometheus +
Grafana** for metrics.

Everything sits behind a **single edge nginx** — one published port, path-per-service
routing (`/auth`, `/console`, `/devportal`, `/management`, `/portal`, `/kibana`,
`/grafana`, `/prometheus`, gateway at `/`).

## Prerequisites

- Docker + Docker Compose v2
- Internet access to pull images. The custom images (`service-b`, the Developer
  Portal) are pulled from Docker Hub (`docker.io/mohammadhsn/*`) — **no local build**.

## Setup

### 1. Configuration

```sh
cp .env.dist .env
```

Set **`PUBLIC_BASE_URL`** — the single public origin everything is reached through:
- Local: `http://localhost` (default)
- VM: `http://<public-ip>` (add `:<port>` only if you change `EDGE_PORT` from 80)

### 2. Create the bind-mount directories (required on Linux)

The compose bind-mounts host directories for logs, plugins and the license.
If they don't exist, Docker creates them **as root** and the in-container service
users (UID 1000) can't write — containers fail to start or log. Pre-create them:

```sh
mkdir -p \
  .logs/apim-gateway \
  .logs/apim-management-api \
  .logs/apim-management-ui \
  .logs/apim-mongodb \
  .logs/apim-portal-ui \
  .plugins \
  .license

chmod -R 777 .logs .plugins .license
```

> On macOS Docker Desktop this isn't strictly required, but it's harmless.

### 3. (Optional) License & secured-API plugin

- Enterprise features: drop your license file into `.license/`.
- To run the `secured-api.json` OAuth2 demo: `./download-plugins-ext.sh`
  (populates `.plugins/`), then import `secured-api.json` in the Console.

## Run

```sh
docker compose up -d
```

Clean slate (wipes Keycloak realm/users, Mongo, ES, and all observability data):

```sh
docker compose down -v && docker compose up -d
```

## Access — one entrypoint, path-per-service

With `PUBLIC_BASE_URL=http://localhost`:

| Service           | URL                              | Credentials                             |
|-------------------|----------------------------------|-----------------------------------------|
| APIM Console      | http://localhost/console/        | `admin` / `admin`                       |
| Developer Portal  | http://localhost/devportal/      | `devportal` / `password` (via Keycloak) |
| API Gateway       | http://localhost/`<api-path>`    | —                                       |
| Keycloak          | http://localhost/auth/           | `admin` / `password`                    |
| Kibana (logs)     | http://localhost/kibana/         | —                                       |
| Prometheus        | http://localhost/prometheus/     | —                                       |
| Grafana           | http://localhost/grafana/        | `admin` / `admin`                       |

On a VM, replace `localhost` with your `PUBLIC_BASE_URL` and open **only `EDGE_PORT`
(80)** in the firewall — every backend port is internal.

## Observability

- **Logs (ELK):** Filebeat ships every container's logs → Logstash → Elasticsearch
  (`logs-*` indices). In **Kibana** (`/kibana/`) create a `logs-*` data view
  (time field `@timestamp`). Gravitee analytics live in `gravitee-*` indices.
- **Metrics (Prometheus + Grafana):** Prometheus scrapes the gateway and
  management-api node endpoints. **Grafana** (`/grafana/`) ships two pre-provisioned
  dashboards under the **Gravitee** folder: *Node Runtime & JVM* and *HTTP Server & Client*.
