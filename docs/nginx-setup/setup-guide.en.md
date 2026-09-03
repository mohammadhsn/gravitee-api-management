# Nginx Setup Guide for Gravitee APIM (Production)

This guide walks a sysadmin through putting Gravitee API Management behind Nginx with TLS on a single production VM, where Gravitee is already running via `docker-compose`.

The companion file `gravitee.conf` in this directory is the Nginx server-block config you will deploy.

## What you get

Three public HTTPS endpoints, all served by one Nginx on the VM:

| Domain | Purpose | Backend (localhost) |
|---|---|---|
| `gateway.example.com` | Gateway — runtime API traffic | `127.0.0.1:8082` |
| `console.example.com` | Admin Console SPA + Management REST (`/management`) | `127.0.0.1:8084` + `127.0.0.1:8083` |
| `portal.example.com` | Developer Portal SPA + Portal REST (`/portal`) | `127.0.0.1:8085` + `127.0.0.1:8083` |

## Prerequisites

- A Linux VM with Docker + docker-compose, running the Gravitee stack from `docker/quick-setup/keycloak/docker-compose.yml` (or your own variant).
- `sudo` access on the VM.
- Three DNS A/AAAA records pointing the chosen domains at the VM's public IP.
- Port `80` and `443` open in the VM's firewall / security group.

## 1. Install Nginx and Certbot

Ubuntu / Debian:

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

RHEL / Rocky / Alma:

```bash
sudo dnf install -y nginx certbot python3-certbot-nginx
sudo systemctl enable --now nginx
```

Verify Nginx serves the default page on port 80 before continuing:

```bash
curl -I http://<vm-public-ip>/
```

## 2. Lock the Docker ports to localhost

By default the compose binds `0.0.0.0:8083`, `0.0.0.0:8084`, `0.0.0.0:8085` — that exposes the upstreams directly. Edit your `docker-compose.yml` so only Nginx (running on the host) can reach them:

```yaml
  management_api:
    ports:
      - "127.0.0.1:8083:8083"

  management_ui:
    ports:
      - "127.0.0.1:8084:8080"

  portal_ui:
    ports:
      - "127.0.0.1:8085:8080"

  gateway:
    ports:
      - "127.0.0.1:8082:8082"   # leave 0.0.0.0 only if Nginx is on a different host
```

## 3. Tell the SPAs about the public URLs

The Console and Portal images bake the API URL into the SPA at container start. Update the env vars to use the public HTTPS URL:

```yaml
  management_ui:
    environment:
      - MGMT_API_URL=https://console.example.com/management/

  portal_ui:
    environment:
      - PORTAL_API_URL=https://portal.example.com/portal
```

Recreate the containers so the new values take effect:

```bash
docker compose up -d --force-recreate management_ui portal_ui
```

## 4. Drop in the Nginx server config

Copy `gravitee.conf` into Nginx's drop-in directory and replace `example.com` with your real domain:

```bash
sudo cp gravitee.conf /etc/nginx/conf.d/gravitee.conf
sudo sed -i 's/example\.com/yourdomain.tld/g' /etc/nginx/conf.d/gravitee.conf
```

If your `nginx.conf` already defines `proxy_set_header`, `proxy_http_version`, or a `map $http_upgrade ...` block at `http {}` scope, **delete those lines from the top of `gravitee.conf`** to avoid duplicate-directive errors. The cleanest place for shared defaults is a separate file at `/etc/nginx/conf.d/00-defaults.conf`.

Validate the config (it will fail until certs exist — that's expected; the next step fixes it):

```bash
sudo nginx -t
```

## 5. Issue TLS certificates

Use Certbot's nginx integration to issue and auto-install certs for all three domains in one go:

```bash
sudo certbot --nginx \
  -d gateway.example.com \
  -d console.example.com \
  -d portal.example.com
```

If you prefer to keep the `gravitee.conf` paths exactly as written, use `certonly` instead and let Nginx pick up the cert files from the standard location:

```bash
sudo certbot certonly --nginx \
  -d gateway.example.com \
  -d console.example.com \
  -d portal.example.com
```

Certbot installs a systemd timer for automatic renewal. Verify it:

```bash
systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

## 6. Reload Nginx

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Open `https://console.example.com` in a browser. You should see the Gravitee Console login. Same for `https://portal.example.com`.

## 7. (If you also use Keycloak) update OIDC redirect URIs

If you followed the Keycloak setup in [`../en-gravitee-howto-guide.md`](../en-gravitee-howto-guide.md), update the `gravitee-client` Keycloak client:

- **Valid Redirect URIs:** `https://console.example.com/*`, `https://portal.example.com/*`
- **Web Origins:** `https://console.example.com`, `https://portal.example.com`

And update the Management API OIDC env vars to point at the public Keycloak issuer URL (e.g. `https://auth.example.com/realms/<REALM>/...`) instead of `http://auth.localhost/...`.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `502 Bad Gateway` on `/` | UI container not running, or port not bound on `127.0.0.1`. Check `docker ps`. |
| SPA loads but API calls fail with CORS or `401` | `MGMT_API_URL` / `PORTAL_API_URL` not updated, or Nginx not proxying `/management` / `/portal`. |
| Login redirect loops back to login | Keycloak redirect URIs / web origins still point at `localhost`. Update them. |
| Logs show client IP as `127.0.0.1` | Add the `set_real_ip_from <trusted-proxy>` + `real_ip_header X-Forwarded-For` directives to Nginx if you sit behind another proxy/CDN. |
| Streaming endpoints (SSE / chunked) buffer | `proxy_buffering off` must be in scope; verify it is not overridden inside a `location` block. |

## Hardening checklist

- Add HSTS once you are confident TLS is stable: `add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;` inside each HTTPS `server {}`.
- Add a sensible `Content-Security-Policy` for the Console / Portal hosts.
- Restrict the Gateway domain by IP allowlist if it is internal-only.
- Send Nginx access logs to your log shipper; the Management API logs already go to `./.logs/apim-management-api`.
- Schedule `certbot renew` testing into your monthly checks even though the timer runs automatically.
