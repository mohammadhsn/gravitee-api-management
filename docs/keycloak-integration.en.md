# Integrating Gravitee APIM with an Existing Keycloak

These instructions are for a Keycloak administrator who already operates a Keycloak instance (and realm) in production and needs to onboard Gravitee API Management as a new OIDC client. They reproduce the `gio` realm setup shipped in `docker/quick-setup/keycloak/realm/realm-gio.json`, but applied to your existing realm — you do **not** need to import that JSON.

## 1. Pick a realm

Use any existing realm (for example `gio`, `corp`, etc.). Note its name; Gravitee endpoint URLs will use `/realms/<REALM>/...`.

## 2. Create a client for the Gravitee Management Console

| Setting | Value |
|---|---|
| Client ID | `gravitee-client` (any value, must match the Gravitee config) |
| Protocol | OpenID Connect |
| Client authentication | **On** (confidential) |
| Standard flow | Enabled (Authorization Code) |
| Direct access grants | Enabled (optional) |
| Service accounts roles | Enabled |
| Valid redirect URIs | `https://<console-host>/*` (dev: `http://localhost:8084/*`) |
| Valid post-logout redirect URIs | `https://<console-host>/*` |
| Web origins | `https://<console-host>` (dev: `http://localhost:8084`), or `+` to mirror redirect URIs |
| Root URL / Home URL | `https://<console-host>` |

After saving, open **Credentials** and copy the **Client secret** — Gravitee needs it. In the bundled dev realm the value is `00dc0118-2a0d-4249-86a3-3e133f5de145`; generate a fresh one for production.

## 3. (Optional) Developer Portal client

If you also want SSO on the Developer Portal, create a second client with the same settings but with redirect URIs / web origins pointing at the Portal host (dev: `http://localhost:8085`).

## 4. Client scopes

The default `openid`, `profile`, and `email` scopes are sufficient. Gravitee requests `openid` and `profile`. No custom mappers are required for the baseline integration; the standard `sub`, `email`, `family_name`, `given_name`, and `picture` claims are what Gravitee maps.

## 5. Roles and users

- Any realm/client roles you want Gravitee to consume can be left as-is. Gravitee's compose sets `syncMappings=false`, so no automatic role mapping happens — admins manage roles inside Gravitee unless you opt into mapping later.
- Existing users in the realm will be able to log in to Gravitee after consenting on first login.

## 6. Hand the following back to the Gravitee operator

```
ISSUER_BASE   = https://<keycloak-host>/realms/<REALM>
CLIENT_ID     = gravitee-client
CLIENT_SECRET = <copied from step 2>
```

The Gravitee Management API will then be configured (via env vars or `gravitee.yml`) with:

```yaml
security:
  providers:
    - type: oidc
      id: keycloak
      clientId: ${CLIENT_ID}
      clientSecret: ${CLIENT_SECRET}
      tokenEndpoint:                 ${ISSUER_BASE}/protocol/openid-connect/token
      tokenIntrospectionEndpoint:    ${ISSUER_BASE}/protocol/openid-connect/token/introspect
      authorizeEndpoint:             ${ISSUER_BASE}/protocol/openid-connect/auth
      userInfoEndpoint:              ${ISSUER_BASE}/protocol/openid-connect/userinfo
      userLogoutEndpoint:            ${ISSUER_BASE}/protocol/openid-connect/logout
      scopes: [ openid, profile ]
      syncMappings: false
      userMapping:
        id: sub
        email: email
        lastname: lastname
        firstname: family_name
        picture: picture
```

The equivalent environment-variable form is already in `docker/quick-setup/keycloak/docker-compose.yml` (lines 155–172) as `gravitee_security_providers_2_*`.

## 7. Production cautions

- **TLS:** production Keycloak should be served over HTTPS. Set `KC_HOSTNAME` and avoid `start-dev`; use `start` with proper hostname/proxy settings.
- **Reachability:** the Management API container must be able to resolve the Keycloak hostname you place in the endpoints. The dev compose uses `auth.localhost` via an nginx proxy plus `links:` — in production just use the public Keycloak DNS name.
- **Secret rotation:** rotate the `gravitee-client` secret on a schedule and update the Gravitee env/secret store when you do.
- **Redirect URIs:** keep them strict — no host wildcards, only path wildcards — and add only the real console/portal URLs.

That is all that is required on the Keycloak side: one confidential client per Gravitee UI, plus the issuer URL and client secret handed back to the team running Gravitee.
