# Gravitee APIM + Keycloak — docker compose

APIM (Gateway, Management API, Console, Developer Portal) with Keycloak as the
OIDC identity provider, plus a `service-b` demo backend.

## Prerequisites

- Docker + Docker Compose v2
- The custom images referenced in `docker-compose.yml` must be reachable
  (`service-b`, `gravitee-portal-ui-fa`) — pull/push tags or build them.

## Setup

### 1. Configuration

```sh
cp .env.dist .env
```

Local use: leave the defaults. On a VM, set `PUBLIC_HOST` to the machine's
public IP (and adjust ports if needed) — every browser-facing URL is derived
from it.

### 2. Create the bind-mount directories (required on Linux)

The compose bind-mounts host directories for logs, plugins and the license.
If they don't exist, Docker creates them **as root**, and the in-container
service users (e.g. UID 1000) then can't write — containers fail to start or
log. Pre-create them with open permissions:

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

> On macOS Docker Desktop this isn't strictly required (ownership is mapped
> automatically), but running it anyway is harmless.

### 3. (Optional) License & secured-API plugin

- Enterprise features: drop your license file into `.license/`.
- To run the `secured-api.json` OAuth2 demo: `./download-plugins-ext.sh`
  (populates `.plugins/`), then import `secured-api.json` in the Console.

## Run

```sh
docker compose up -d
```

To rebuild from a clean slate (wipes Keycloak realm/users, Mongo, ES):

```sh
docker compose down -v && docker compose up -d
```

## Access

| Service           | URL (local)             | Credentials                              |
|-------------------|-------------------------|------------------------------------------|
| APIM Console      | http://localhost:8084   | `admin` / `admin`                        |
| Developer Portal  | http://localhost:8085   | `devportal` / `password` (via Keycloak)  |
| API Gateway       | http://localhost:8082   | —                                        |
| Management API    | http://localhost:8083   | —                                        |
| Keycloak          | http://localhost:8080   | `admin` / `password`                     |

On a VM, replace `localhost` with `PUBLIC_HOST` and open ports
`8080, 8082, 8083, 8084, 8085` in the firewall.
