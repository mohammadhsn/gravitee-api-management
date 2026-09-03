# Gravitee 4.x + Keycloak: Production How-To Guide

> **Audience:** Engineers operating a self-hosted Gravitee 4.x API Management platform.
> **Scope:** Practical, step-by-step instructions for creating, securing, exposing, auditing, and documenting APIs.
> **Version:** 2.0 — adds Audit Logging & Analysis and API Documentation features.

---

## Table of Contents

1. [Core Concepts & Terminology](#1-core-concepts--terminology)
2. [Create and Publish Your First API](#2-create-and-publish-your-first-api)
   - 2.1 [Create an API](#21-create-an-api)
   - 2.2 [Add Security — API Key](#22-add-security--api-key)
   - 2.3 [Add Security — JWT via Keycloak](#23-add-security--jwt-via-keycloak)
   - 2.4 [Add Policies](#24-add-policies)
   - 2.5 [Publish the API](#25-publish-the-api)
   - 2.6 [Add API Documentation](#26-add-api-documentation)
3. [Use Case Tutorials](#3-use-case-tutorials)
   - 3.1 [Rate Limit REST APIs](#31-rate-limit-rest-apis)
   - 3.2 [Configure JWT Security](#32-configure-jwt-security)
   - 3.3 [Add RBAC to JWT Plans](#33-add-rbac-to-jwt-plans)
   - 3.4 [Configure Dynamic Client Registration (DCR)](#34-configure-dynamic-client-registration-dcr)
   - 3.5 [Secure and Expose gRPC Services](#35-secure-and-expose-grpc-services)
   - 3.6 [Expose SOAP Web Services as REST APIs](#36-expose-soap-web-services-as-rest-apis)
   - 3.7 [Create and Publish an API via Management API](#37-create-and-publish-an-api-via-management-api)
   - 3.8 [Connect an Endpoint Using SSE](#38-connect-an-endpoint-using-sse)
4. [Deep Dive: Transparent Service-to-Service Token Flow](#4-deep-dive-transparent-service-to-service-token-flow)
5. [Audit Logging and API Analysis](#5-audit-logging-and-api-analysis)
   - 5.1 [Understanding What Gets Audited](#51-understanding-what-gets-audited)
   - 5.2 [Accessing and Filtering Audit Logs](#52-accessing-and-filtering-audit-logs)
   - 5.3 [API-Level Analytics](#53-api-level-analytics)
   - 5.4 [Platform-Level Analytics](#54-platform-level-analytics)
   - 5.5 [Analyzing Subscription and Consumer Activity](#55-analyzing-subscription-and-consumer-activity)
   - 5.6 [Exporting Audit and Analytics Data](#56-exporting-audit-and-analytics-data)
   - 5.7 [Forwarding Logs to External Systems](#57-forwarding-logs-to-external-systems)
6. [Documenting Features and Options](#6-documenting-features-and-options)
   - 6.1 [Documentation Page Types](#61-documentation-page-types)
   - 6.2 [Documentation Sources](#62-documentation-sources)
   - 6.3 [Organizing Documentation with Folders](#63-organizing-documentation-with-folders)
   - 6.4 [Managing Visibility and Access](#64-managing-visibility-and-access)
   - 6.5 [API Metadata and Categorization](#65-api-metadata-and-categorization)
   - 6.6 [Attaching Documentation to Plans](#66-attaching-documentation-to-plans)
   - 6.7 [Syncing Docs from Git (GitHub / GitLab)](#67-syncing-docs-from-git-github--gitlab)
   - 6.8 [Documentation Reference — All Options](#68-documentation-reference--all-options)

---

## 1. Core Concepts & Terminology

Before working with Gravitee, align on this terminology. These terms are used throughout the Dashboard and this guide.

| Term | What it means in Gravitee |
|---|---|
| **API** | The logical definition of your API — its entrypoints, endpoints, plans, and policies. Represents your service contract. |
| **Application** | A consumer-side entity (e.g., a frontend app or a microservice) that subscribes to a Plan in order to call an API. |
| **Gateway** | The runtime proxy that enforces all policies (security, rate limiting, transformations) on every inbound request. Traffic flows through it — never directly to your backend. |
| **Proxy** | The mode of operation where the Gateway forwards requests to a backend service. This is the standard deployment model for REST, SOAP, and most HTTP APIs. |
| **Entrypoint** | How consumers reach your API through the Gateway. Defines the protocol and path (e.g., `https://gateway.company.com/service-a/v1`). |
| **Endpoint** | The backend service the Gateway forwards requests to (e.g., `http://service-a.internal:8080`). Not exposed directly to consumers. |
| **Plan** | A set of access rules attached to an API. Defines security type (API Key, JWT, OAuth2, Keyless) and any quotas or restrictions. Consumers subscribe to a Plan. |
| **Policy** | A processing step applied to a request or response (e.g., add a header, rate limit, call an external service). Policies are chained in a flow. |
| **Deployment** | The act of pushing your API configuration from the Management API to the Gateway runtime. An API is not live until it is deployed. |
| **Dashboard Settings** | The Gravitee Management Console UI. All actions in this guide that reference "Dashboard" refer to this web interface, accessible at `https://console.company.com` (port `8084` by default). |

---

## 2. Create and Publish Your First API

### 2.1 Create an API

**Goal:** Register a backend service (`service-a`) behind the Gravitee Gateway.

1. Open the **Dashboard** → left sidebar → **APIs** → click **+ Create API**.
2. Select **Create a V4 API** (Gravitee 4.x native model).
3. Fill in the **General** tab:
   - **Name:** `service-a`
   - **Version:** `1.0.0`
   - **Description:** `Internal Service A — exposed via Gravitee`
4. Click **Next** → **Entrypoints** tab:
   - Select **HTTP Proxy** as the entrypoint type.
   - **Path:** `/service-a/v1`
   - Leave the virtual host blank unless you use multi-domain routing.
5. Click **Next** → **Endpoints** tab:
   - Click **+ Add endpoint group**.
   - **Name:** `service-a-backend`
   - **Target URL:** `http://service-a.internal:8080`
   - Set **Load Balancing:** `Round Robin` (adjust if only one instance).
6. Click **Next** → **Security** tab — skip for now (covered in §2.2).
7. Click **Next** → review the summary → click **Create & deploy** or **Save**.

> At this point the API exists but has **no Plan**, meaning no consumer can subscribe. Continue to §2.2.

---

### 2.2 Add Security — API Key

**Goal:** Protect the API with API Key authentication.

1. In the Dashboard → **APIs** → open `service-a`.
2. Left sidebar → **Plans** → click **+ Add plan**.
3. **Plan type:** select **API Key**.
4. Fill in:
   - **Name:** `service-a-apikey-plan`
   - **Description:** `API Key access for service-a`
   - **Security:** `API Key` (pre-selected)
5. **Validation:** set to **Automatic** (or Manual if you want to approve each subscription).
6. Click **Next** → optionally add rate limiting (see §3.1) → click **Save**.
7. Click **Publish** next to the plan to make it subscribable.
8. Go to **Deployment** → click **Deploy** to push changes to the Gateway.

**To generate an API Key for a consumer:**

1. Dashboard → **Applications** → create an Application (name: `consumer-app-1`).
2. Inside the application → **Subscriptions** → **+ Subscribe** → select `service-a` → select `service-a-apikey-plan`.
3. After approval, the API Key appears under **Subscriptions → API Keys**.

**Using the API Key:**

```http
GET https://gateway.company.com/service-a/v1/health
X-Gravitee-Api-Key: <your-api-key>
```

---

### 2.3 Add Security — JWT via Keycloak

**Goal:** Accept JWTs issued by Keycloak on a separate plan.

**Prerequisites in Keycloak:**
- A Realm named `company-realm` exists.
- A client named `gravitee-gateway` exists with **Access Type:** `confidential`.
- Fetch the JWKS URI: `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs`

**Steps:**

1. Dashboard → **APIs** → open `service-a` → **Plans** → **+ Add plan**.
2. **Plan type:** select **JWT**.
3. Fill in:
   - **Name:** `service-a-jwt-plan`
   - **Security:** `JWT`
4. In the **JWT** configuration section:
   - **Signature algorithm:** `RS256`
   - **JWKS resolver:** `JWKS_URL`
   - **JWKS URL:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs`
   - **Issuer:** `https://keycloak.company.com/realms/company-realm`
   - **Audiences:** `gravitee-gateway` (must match the `aud` claim in the JWT)
5. Click **Save** → **Publish** → **Deploy**.

**Consumer request:**

```http
GET https://gateway.company.com/service-a/v1/resource
Authorization: Bearer <keycloak-issued-jwt>
```

---

### 2.4 Add Policies

**Goal:** Add processing logic (e.g., add a header, transform a response) to the API flow.

1. Dashboard → **APIs** → open `service-a` → **Policy Studio**.
2. The canvas shows **Request** and **Response** flows. Click **+ Add policy** on the flow phase where you want to apply it.
3. Example — **Add a custom request header:**
   - Phase: **Request**
   - Policy: **Transform Headers**
   - Action: **Add / Replace**
   - Header name: `X-Internal-Source`
   - Header value: `gravitee-gateway`
4. Click **Save** → **Deploy**.

> Policies execute in the order listed. Drag to reorder them on the canvas.

**Common policies and their use:**

| Policy | Typical Use |
|---|---|
| Transform Headers | Inject, remove, or rewrite HTTP headers |
| Rate Limit | Throttle requests (see §3.1) |
| JWT | Validate JWT tokens |
| Callout HTTP | Call an external HTTP endpoint during the flow (e.g., fetch a token — see §4) |
| Cache | Cache upstream responses or intermediate data |
| Assign Content | Override response body |
| GeoIP Filtering | Block or allow by geography |
| Resource Filtering | Restrict access by HTTP method or path |

---

### 2.5 Publish the API

An API must be published to appear in the Developer Portal and be callable through the Gateway.

1. Dashboard → **APIs** → open `service-a`.
2. Top-right → click the **Publish** button (cloud icon) → confirm.
3. Ensure the API **State** shows **Started**.
4. Go to **Deployment** → click **Deploy** if there are pending changes (shown by a yellow badge).

> **Important:** Saving changes in the Dashboard does **not** automatically update the Gateway. Always click **Deploy** after configuration changes.

---

### 2.6 Add API Documentation

1. Dashboard → **APIs** → open `service-a` → left sidebar → **Documentation**.
2. Click **+ Add page**.
3. Choose the format:
   - **Markdown** — for narrative docs.
   - **OpenAPI (Swagger)** — paste or upload your `openapi.yaml`.
   - **AsyncAPI** — for event-driven APIs.
4. For OpenAPI:
   - **Source:** `File` or `URL` (e.g., `http://service-a.internal:8080/v3/api-docs`).
   - Toggle **Published** to `ON`.
5. Click **Save** → **Deploy**.

The documentation appears in the Developer Portal under the API's page.

---

## 3. Use Case Tutorials

---

### 3.1 Rate Limit REST APIs

**Goal:** Restrict consumers to a set number of requests per time window.

1. Dashboard → **APIs** → open your API → **Policy Studio**.
2. Select the **Plan flow** you want to rate limit (e.g., `service-a-apikey-plan`).
3. Click **+ Add policy** → **Request** phase → select **Rate Limit**.
4. Configure:
   - **Key:** `{#request.headers['X-Gravitee-Api-Key']}` (per API key) or `{#context.attributes['application']}` (per application)
   - **Max requests:** `100`
   - **Time period:** `1`
   - **Time unit:** `MINUTES`
   - **Limit header:** enable (sends `X-Rate-Limit-Remaining` in responses)
5. Click **Save** → **Deploy**.

**Alternative — set rate limiting at the Plan level:**

1. Dashboard → **APIs** → **Plans** → edit the plan.
2. Under **Rate Limiting** section → toggle ON → set the same values.
3. **Save** → **Deploy**.

> Plan-level rate limiting applies globally across all flows. Policy-level gives more granular control per path or method.

---

### 3.2 Configure JWT Security

**Goal:** Full step-by-step JWT plan configuration with Keycloak as the identity provider.

**Step 1 — Prepare Keycloak:**

1. Keycloak Admin Console → select `company-realm` → **Clients** → **Create**.
2. Client settings:
   - **Client ID:** `api-consumer-client`
   - **Access Type:** `confidential`
   - **Standard Flow:** OFF
   - **Direct Access Grants:** OFF
   - **Service Accounts:** ON (for client_credentials if needed)
3. **Save** → copy the **Client Secret** from the **Credentials** tab.
4. Confirm the JWKS endpoint is reachable:
   ```
   GET https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs
   ```

**Step 2 — Create the JWT Plan in Gravitee:**

1. Dashboard → **APIs** → open your API → **Plans** → **+ Add plan** → **JWT**.
2. Configure as described in §2.3.
3. Additionally set:
   - **Extract JWT Claims:** ON → this makes claims available as `{#context.attributes['jwt.claims']['claim-name']}` in policies.
   - **Client ID Claim:** `azp` or `client_id` (match what Keycloak puts in the token).

**Step 3 — Test:**

Get a token from Keycloak:
```bash
curl -X POST https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=api-consumer-client" \
  -d "client_secret=<client-secret>"
```

Call the API:
```bash
curl -H "Authorization: Bearer <access_token>" \
  https://gateway.company.com/service-a/v1/resource
```

---

### 3.3 Add RBAC to JWT Plans

**Goal:** Restrict access to specific paths or methods based on roles inside the JWT.

**Step 1 — Add roles to Keycloak tokens:**

1. Keycloak → `company-realm` → **Clients** → `api-consumer-client` → **Client Roles** → **Add Role**.
   - Example roles: `read`, `write`, `admin`
2. Assign roles to users or service accounts: **Users** → select user → **Role Mappings** → **Client Roles** → select `api-consumer-client` → add roles.
3. Verify the JWT includes roles:
   ```json
   {
     "resource_access": {
       "api-consumer-client": {
         "roles": ["read"]
       }
     }
   }
   ```

**Step 2 — Add a Resource Filtering policy in Gravitee:**

1. Dashboard → **APIs** → open your API → **Policy Studio**.
2. Select the JWT plan flow → **+ Add policy** → **Request** phase → **Resource Filtering**.
3. Configure rules:

   | Path | Methods | Allowed | Role expression |
   |---|---|---|---|
   | `/service-a/v1/**` | GET | YES | `{#context.attributes['jwt.claims']['resource_access']['api-consumer-client']['roles'].contains('read')}` |
   | `/service-a/v1/**` | POST, PUT, DELETE | YES | `{#context.attributes['jwt.claims']['resource_access']['api-consumer-client']['roles'].contains('write')}` |

4. Click **Save** → **Deploy**.

> If the role expression evaluates to `false`, the Gateway returns `403 Forbidden` before the request reaches the backend.

---

### 3.4 Configure Dynamic Client Registration (DCR)

**Goal:** Allow the Developer Portal to automatically create Keycloak clients when an Application registers.

**Step 1 — Configure Keycloak for DCR:**

1. Keycloak → `company-realm` → **Realm Settings** → **Client Registration** → **Client Registration Policies**.
2. Enable **Trusted Hosts** and whitelist your Gravitee Management API host.
3. Create a **Registration Access Token** (or use a confidential client with `manage-clients` role):
   - **Clients** → **Create** → Client ID: `gravitee-dcr-client`
   - **Access Type:** `confidential`
   - **Service Accounts:** ON
   - **Service Account Roles** → **Client Roles** → `realm-management` → add `manage-clients`
4. Note the **Client Secret**.

**Step 2 — Configure DCR in Gravitee:**

1. Dashboard → **Settings** → **Authentication** → **+ Add identity provider** → **OpenID Connect**.
2. Fill in:
   - **Name:** `keycloak-company-realm`
   - **Client ID:** `gravitee-dcr-client`
   - **Client Secret:** `<secret from step 1>`
   - **Token Endpoint:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token`
   - **Authorization Endpoint:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/auth`
   - **Userinfo Endpoint:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/userinfo`
   - **JWKS URI:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs`
3. **Save**.

**Step 3 — Enable DCR on a Plan:**

1. Dashboard → **APIs** → open your API → **Plans** → edit the OAuth2 or JWT plan.
2. Enable **Dynamic Client Registration**.
3. Select the identity provider configured above.
4. **Save** → **Deploy**.

Now when a consumer creates an Application in the Portal and subscribes to this plan, Gravitee will automatically register a client in Keycloak and return the credentials to the consumer.

---

### 3.5 Secure and Expose gRPC Services

**Goal:** Expose a backend gRPC service through the Gravitee Gateway.

**Prerequisites:**
- Gravitee 4.x Gateway with gRPC support enabled.
- Backend gRPC service running at `grpc://service-a.internal:50051`.
- Proto file for `service-a`.

**Step 1 — Create the API:**

1. Dashboard → **APIs** → **+ Create API** → **V4 API**.
2. **Entrypoints** tab → select **gRPC**.
   - **Path:** `/service-a.ServiceA` (must match the gRPC service package and name).
   - **Host:** `gateway.company.com`
   - **Port:** `9443` (Gravitee gRPC listener port — confirm with your ops team).
3. **Endpoints** tab → **+ Add endpoint group**:
   - **Target:** `grpc://service-a.internal:50051`
   - Enable **TLS** if the backend gRPC service requires it.
4. **Security** tab → select **API Key** or **JWT plan** as needed.
5. **Save** → **Deploy**.

**Step 2 — Add API Key security (gRPC metadata):**

gRPC consumers pass the API Key in the request metadata:
```
Metadata:
  X-Gravitee-Api-Key: <api-key>
```

**Step 3 — Test with grpcurl:**

```bash
grpcurl \
  -H "X-Gravitee-Api-Key: <api-key>" \
  -proto service-a.proto \
  gateway.company.com:9443 \
  service_a.ServiceA/MethodName
```

> For mutual TLS (mTLS) between Gateway and backend gRPC service, configure the endpoint's **SSL** settings in the endpoint group and supply the client certificate and private key.

---

### 3.6 Expose SOAP Web Services as REST APIs

**Goal:** Wrap a legacy SOAP backend and expose it as a REST API through Gravitee.

**Step 1 — Create the API:**

1. Dashboard → **APIs** → **+ Create API** → **V4 API**.
2. **Entrypoints** tab → **HTTP Proxy**.
   - **Path:** `/legacy-service/v1`
3. **Endpoints** tab → backend URL:
   - `http://legacy-service.internal:8080/ws/LegacyService`
4. **Save**.

**Step 2 — Add SOAP-to-REST transformation policies:**

1. Dashboard → **APIs** → open the API → **Policy Studio**.
2. **Request** phase → **+ Add policy** → **Transform Headers**:
   - Add header: `Content-Type` → `text/xml; charset=utf-8`
   - Add header: `SOAPAction` → `"urn:GetResource"` (match the WSDL action)
3. **Request** phase → **+ Add policy** → **Assign Content**:
   - Replace the incoming REST body with a SOAP envelope:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
     <soap:Body>
       <GetResource xmlns="urn:legacy-service">
         <Id>{#request.params['id']}</Id>
       </GetResource>
     </soap:Body>
   </soap:Envelope>
   ```
   - Use `{#request.params['field']}` or `{#request.content}` to map REST inputs to SOAP fields.
4. **Response** phase → **+ Add policy** → **Transform Headers**:
   - Replace `Content-Type` header with `application/json`.
5. **Response** phase → **+ Add policy** → **Assign Content** or **XSLT Transformation**:
   - Use an XSLT stylesheet to extract the SOAP response body and reshape it as JSON.
6. Click **Save** → **Deploy**.

**Consumer request (looks like a normal REST call):**

```bash
curl "https://gateway.company.com/legacy-service/v1/resource?id=123" \
  -H "X-Gravitee-Api-Key: <api-key>"
```

---

### 3.7 Create and Publish an API via Management API

**Goal:** Automate API creation without using the Dashboard — useful for CI/CD pipelines.

**Step 1 — Authenticate:**

```bash
TOKEN=$(curl -s -X POST https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/user/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<password>"}' | jq -r '.token')
```

**Step 2 — Create the API:**

```bash
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "service-b",
    "version": "1.0.0",
    "description": "Service B via Management API",
    "proxy": {
      "virtual_hosts": [{ "path": "/service-b/v1" }],
      "groups": [{
        "name": "service-b-backend",
        "endpoints": [{
          "name": "default",
          "target": "http://service-b.internal:8081",
          "weight": 1
        }]
      }]
    }
  }'
```

Note the `id` returned in the response (e.g., `api_id=abc-123`).

**Step 3 — Create a Plan:**

```bash
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis/abc-123/plans" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "service-b-apikey-plan",
    "security": "API_KEY",
    "status": "PUBLISHED",
    "validation": "AUTO"
  }'
```

**Step 4 — Publish and Deploy:**

```bash
# Publish the API to the portal
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis/abc-123/publish" \
  -H "Authorization: Bearer $TOKEN"

# Deploy to the Gateway
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis/abc-123/deployments" \
  -H "Authorization: Bearer $TOKEN"
```

> For full API specs refer to the Gravitee Management API Swagger UI at `https://console.company.com/management/swagger-ui`.

---

### 3.8 Connect an Endpoint Using SSE

**Goal:** Expose a Server-Sent Events (SSE) backend stream through the Gravitee Gateway.

**Step 1 — Create the API:**

1. Dashboard → **APIs** → **+ Create API** → **V4 API**.
2. **Entrypoints** tab → select **HTTP GET** (Gravitee 4.x exposes SSE via HTTP GET entrypoint with streaming).
3. **Path:** `/service-a/v1/events`
4. **Endpoints** tab → **+ Add endpoint group**:
   - **Type:** `HTTP`
   - **Target URL:** `http://service-a.internal:8080/events` (the SSE stream endpoint on your backend)
5. In the endpoint configuration → enable **Allow chunked encoding** and **Keep-alive**.

**Step 2 — Configure the SSE response:**

1. **Policy Studio** → **Response** phase → **+ Add policy** → **Transform Headers**:
   - Set `Content-Type` → `text/event-stream`
   - Set `Cache-Control` → `no-cache`
   - Set `Connection` → `keep-alive`
2. **Save** → **Deploy**.

**Step 3 — Test:**

```bash
curl -N \
  -H "X-Gravitee-Api-Key: <api-key>" \
  https://gateway.company.com/service-a/v1/events
```

Expected output:
```
data: {"event":"status","value":"ok"}

data: {"event":"update","value":"new-data"}
```

---

## 4. Deep Dive: Transparent Service-to-Service Token Flow

### Overview

This section covers the most critical production pattern: **the client sends a request to the Gateway without any token, and the Gateway transparently fetches a token from Keycloak using `client_credentials`, then injects it into the request before forwarding it to the downstream service.**

The downstream service (e.g., `service-b`) is protected and requires a valid Bearer token. The calling client (e.g., a frontend, mobile app, or another service) is **completely unaware** that a token exchange is happening.

```
Client
  │
  │  Request (API Key or no token)
  ▼
Gravitee Gateway
  │
  ├──[1] Callout HTTP Policy → POST /token to Keycloak
  │         grant_type=client_credentials
  │         client_id=gateway-internal-client
  │         client_secret=<secret>
  │
  ├──[2] Extract access_token from Keycloak response
  │
  ├──[3] Cache the token (avoid calling Keycloak on every request)
  │
  ├──[4] Inject:  Authorization: Bearer <access_token>
  │
  ▼
service-b.internal:8081
  │
  (validates token against Keycloak JWKS — token is trusted)
```

---

### 4.1 Keycloak Setup

**Step 1 — Create the Gateway's internal Keycloak client:**

1. Keycloak Admin Console → `company-realm` → **Clients** → **Create**.
2. Configure:
   - **Client ID:** `gateway-internal-client`
   - **Access Type:** `confidential`
   - **Standard Flow Enabled:** OFF
   - **Direct Access Grants:** OFF
   - **Service Accounts Enabled:** ON ← required for `client_credentials`
3. **Save** → go to **Credentials** tab → copy the **Client Secret**.

**Step 2 — Assign the correct scopes/roles:**

1. Inside `gateway-internal-client` → **Service Account Roles** tab.
2. Assign the roles that `service-b` expects in the token (e.g., `service-b-caller`).

**Step 3 — Verify the token endpoint works:**

```bash
curl -X POST \
  https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=gateway-internal-client" \
  -d "client_secret=<secret>"
```

Expected response:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5...",
  "expires_in": 300,
  "token_type": "Bearer"
}
```

Note the `expires_in` value (e.g., `300` seconds). You will use it in the cache TTL.

---

### 4.2 Gravitee Setup — API and Plan

**Step 1 — Create or open the API:**

This flow is configured on the API that **proxies to `service-b`** — the protected downstream. If you haven't created it yet:

1. Dashboard → **APIs** → **+ Create API** → **V4 API**.
2. **Entrypoints:** `/service-b/v1`
3. **Endpoints:** `http://service-b.internal:8081`
4. **Plan:** `API Key` (so clients call the Gateway using an API key — the token exchange happens internally).
5. **Save**.

> The client authenticates to the Gateway using an **API Key**. The token exchange with Keycloak is an **internal Gateway operation** — invisible to the client.

---

### 4.3 Configure the Cache Resource

Before building the flow, create a shared cache resource to store the token between requests.

1. Dashboard → **APIs** → open the API → left sidebar → **Resources**.
2. Click **+ Add resource** → **Cache Resource**.
3. Configure:
   - **Name:** `keycloak-token-cache`
   - **Cache Resource Name (Key Prefix):** `kc-token`
   - **Time to Live (TTL):** `270` (set slightly below Keycloak's `expires_in` of 300 to avoid using expired tokens)
   - **Max entries:** `100`
4. **Save**.

---

### 4.4 Build the Policy Flow — Step by Step

Go to **APIs** → open your API → **Policy Studio** → select the plan's **Request** flow.

You will add policies in this exact order:

```
[Request Phase]
  1. Cache Lookup      ← check if token is already cached
  2. Callout HTTP      ← fetch token from Keycloak (skipped if cache hit)
  3. Assign Attributes ← extract access_token from callout response
  4. Cache Store       ← save token to cache (skipped if cache hit)
  5. Transform Headers ← inject Authorization: Bearer <token>
```

---

#### Policy 1 — Cache Lookup

1. **+ Add policy** → **Request** phase → **Cache**.
2. Set to **Lookup** mode.
3. Configure:
   - **Cache Resource:** `keycloak-token-cache`
   - **Cache Key:** `gateway-internal-client-token` (static — all requests share one token since it's a service account)
   - **Time to Live:** leave blank (uses resource TTL)
4. **On Cache Hit:** select **Skip remaining policies in this phase up to Cache Store policy** — or use a condition on the Callout policy (see next step).
5. **Save**.

> When the cache has a valid token, the Callout HTTP policy is skipped and the flow jumps directly to header injection.

---

#### Policy 2 — Callout HTTP (Fetch Token from Keycloak)

1. **+ Add policy** → **Request** phase → **Callout HTTP**.
2. Configure:

   | Field | Value |
   |---|---|
   | **HTTP Method** | `POST` |
   | **URL** | `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token` |
   | **Request Body** | `grant_type=client_credentials&client_id=gateway-internal-client&client_secret=<secret>` |
   | **Content-Type Header** | `application/x-www-form-urlencoded` |
   | **Response Variable** | `keycloak-response` |
   | **Fire & Forget** | OFF (we need the response) |
   | **Exit on Error** | ON (abort if Keycloak is unreachable) |
   | **Error Status** | `503` |

3. **Condition** (to skip on cache hit):
   - Enable **Condition** → enter:
     ```
     {#context.attributes['keycloak-token-cache'] == null}
     ```
   - This ensures the callout only fires when the cache does **not** have a token.

4. **Save**.

> **Security note:** Do not hardcode the `client_secret` in plain text in a production system. Use Gravitee's **Secret Provider** integration or store it in a **Resource** of type `OAuth2`. See §4.6 for the secure alternative.

---

#### Policy 3 — Assign Attributes (Extract the Token)

1. **+ Add policy** → **Request** phase → **Assign Attributes**.
2. Add one attribute:

   | Attribute Name | Attribute Value |
   |---|---|
   | `internal-bearer-token` | `{#jsonPath(#context.attributes['keycloak-response'].content, '$.access_token')}` |

3. **Condition:**
   ```
   {#context.attributes['keycloak-response'] != null}
   ```
   (Only execute if the callout actually ran.)

4. **Save**.

---

#### Policy 4 — Cache Store (Save the Token)

1. **+ Add policy** → **Request** phase → **Cache** (second instance).
2. Set to **Store** mode.
3. Configure:
   - **Cache Resource:** `keycloak-token-cache`
   - **Cache Key:** `gateway-internal-client-token`
   - **Value to Cache:** `{#context.attributes['internal-bearer-token']}`
   - **Time to Live:** `270`
4. **Condition:**
   ```
   {#context.attributes['internal-bearer-token'] != null}
   ```
5. **Save**.

---

#### Policy 5 — Transform Headers (Inject the Bearer Token)

1. **+ Add policy** → **Request** phase → **Transform Headers**.
2. **Actions:**

   | Action | Header Name | Header Value |
   |---|---|---|
   | **Add / Replace** | `Authorization` | `Bearer {#context.attributes['internal-bearer-token']}` |

3. **On Cache Hit:** if using cache-based token retrieval, set the value to read from the cache attribute instead:
   ```
   Bearer {#context.attributes['keycloak-token-cache'] != null
     ? #context.attributes['keycloak-token-cache']
     : #context.attributes['internal-bearer-token']}
   ```
   Or simplify by always populating `internal-bearer-token` from either source in Policy 3.

4. **Save** → **Deploy**.

---

### 4.5 Complete Flow Summary

After deployment, the end-to-end flow for every client request looks like this:

```
1. Client sends:
   GET https://gateway.company.com/service-b/v1/resource
   X-Gravitee-Api-Key: <api-key>

2. Gateway validates the API Key → OK.

3. Cache Lookup:
   - HIT  → load token from cache → skip to step 6.
   - MISS → continue to step 4.

4. Callout HTTP → POST to Keycloak:
   grant_type=client_credentials
   client_id=gateway-internal-client
   client_secret=<secret>
   ← Response: { "access_token": "eyJ...", "expires_in": 300 }

5. Extract + Cache:
   - Store access_token in context attribute 'internal-bearer-token'.
   - Save to 'keycloak-token-cache' with TTL=270s.

6. Transform Headers:
   - Remove or ignore any client-provided Authorization header.
   - Set: Authorization: Bearer eyJ...

7. Forward to downstream:
   GET http://service-b.internal:8081/resource
   Authorization: Bearer eyJ...

8. service-b validates the token against Keycloak JWKS — passes.

9. Response flows back to the client normally.
```

**The client never sees the token. The client never needs a Keycloak account. The downstream service is fully protected.**

---

### 4.6 Secure the Client Secret (Production Requirement)

Hardcoding the `client_secret` in a Callout policy body is **not acceptable for production**. Use one of these approaches:

**Option A — Gravitee Secret Provider (recommended):**

1. Dashboard → **Settings** → **Secret Providers** → configure a Vault or Kubernetes Secrets backend.
2. Reference the secret in the policy using:
   ```
   {#secrets.get('gateway-internal-client-secret')}
   ```

**Option B — OAuth2 Resource:**

1. Dashboard → **APIs** → **Resources** → **+ Add resource** → **OAuth2 - Keycloak Adapter**.
2. Configure with `gateway-internal-client` credentials.
3. In the Callout policy, replace the manual POST body with a reference to this resource — Gravitee handles token retrieval and caching automatically.

   > This is the cleanest production approach. The OAuth2 Resource manages token lifecycle, refresh, and caching internally.

**Option C — Environment Variables:**

Set the secret as a Gateway environment variable (e.g., `GATEWAY_CLIENT_SECRET`) and reference it:
```
{#system.getenv('GATEWAY_CLIENT_SECRET')}
```

---

### 4.7 Stripping the Client's Authorization Header (Optional but Recommended)

If there is any chance a client sends an `Authorization` header (e.g., with an API Key in the header instead of the query param), strip it before injecting the internal token.

1. **Policy Studio** → **Request** phase → **Transform Headers** policy (add before the injection policy).
2. **Actions:**
   - **Remove:** `Authorization`
3. Place this policy **before** the Callout HTTP policy in the chain.

---

### 4.8 Testing the Full Flow

**Test with no token from the client side:**

```bash
curl -v \
  -H "X-Gravitee-Api-Key: <api-key>" \
  https://gateway.company.com/service-b/v1/resource
```

**Verify on service-b's side** (via logs or a debug endpoint) that the request arrived with:
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Verify cache is working** by checking that the second request completes without a new Keycloak callout. You can observe this via:
- Gravitee Gateway logs (enable `DEBUG` temporarily).
- Keycloak admin → **Events** → confirm only one token issue event for multiple API calls within the TTL window.

---

### 4.9 Keycloak Configuration Reference

| Setting | Value |
|---|---|
| Realm | `company-realm` |
| Token Endpoint | `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token` |
| JWKS URI | `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs` |
| Internal Client ID | `gateway-internal-client` |
| Grant Type | `client_credentials` |
| Token TTL (Keycloak) | `300s` (configure in Keycloak realm → Tokens tab) |
| Cache TTL (Gravitee) | `270s` (10s safety margin) |

---

---

## 5. Audit Logging and API Analysis

Gravitee records two distinct categories of data you need to understand before building any audit or analysis workflow:

- **Audit Logs** — Who changed what and when. Configuration events: API created, plan published, subscription approved, policy modified, deployment triggered. These are write-time records of management actions.
- **Analytics** — What traffic is flowing. Runtime metrics: request count, latency, status codes, consumer breakdown, error rates. These are read-time records of Gateway activity.

Both are accessible from the Dashboard without any external tooling, though both can also be exported.

---

### 5.1 Understanding What Gets Audited

Gravitee automatically creates an audit trail for all management actions. The following events are captured at the **platform level** and **API level**:

| Event Category | Example Events Logged |
|---|---|
| **API Lifecycle** | Created, Updated, Published, Unpublished, Deleted, Deployed |
| **Plan Management** | Plan created, Plan published, Plan closed, Plan updated |
| **Subscription** | Subscription created, Subscription approved, Subscription rejected, Subscription closed, API Key renewed |
| **Policy / Flow** | Policy added, Policy removed, Policy reordered, Flow updated |
| **Application** | Application created, Application updated, Application archived |
| **Members & Access** | Member added, Role changed, Member removed |
| **Authentication** | Admin login, failed login attempts |
| **Portal Settings** | Documentation page published/unpublished, Portal settings changed |

Every audit entry captures:
- **Date and time** (UTC)
- **Actor** — the username or API token that triggered the action
- **Event type** — the specific action taken
- **Target** — which API, Plan, Application, or resource was affected
- **Patch** — the before/after diff of the changed configuration (available for most events)

---

### 5.2 Accessing and Filtering Audit Logs

#### Platform-wide Audit Logs

1. Dashboard → left sidebar → **Settings** → **Audit**.
2. The audit table displays all events across all APIs and applications, sorted by most recent.

**Filtering options:**

| Filter | How to use it |
|---|---|
| **Date range** | Set a start and end date to narrow the window |
| **Event** | Select a specific event type from the dropdown (e.g., `API_UPDATED`, `SUBSCRIPTION_CREATED`) |
| **Environment** | Filter by environment if you run multiple (e.g., `staging`, `production`) |
| **Actor** | Type a username to see all actions made by a specific engineer or service account |

3. Click any row to expand the **detail view**, which shows the full JSON patch (before/after diff).

#### API-level Audit Logs

1. Dashboard → **APIs** → open any API → left sidebar → **Audit**.
2. The same filter controls apply, but results are scoped to that specific API only.

> Use API-level audit when investigating an incident on a specific service (e.g., "who changed the JWT policy on `service-a` between 14:00 and 16:00 yesterday?").

---

### 5.3 API-Level Analytics

**Goal:** Understand traffic patterns, error rates, and consumer behaviour for a specific API.

1. Dashboard → **APIs** → open your API → left sidebar → **Analytics**.
2. Set the **date range** (top-right date picker) — options include last hour, last 24h, last 7 days, custom range.

The Analytics view contains the following panels:

#### Traffic Overview

| Metric | Description |
|---|---|
| **Requests/sec** | Request rate over the selected window |
| **Total Hits** | Absolute count of requests |
| **Failed Requests** | Requests that resulted in a 4xx or 5xx response |
| **Success Rate** | % of 2xx responses |
| **Average Latency** | End-to-end response time (Gateway receipt → response to client) |
| **Response Time Breakdown** | Gateway processing time vs. backend response time |

#### Status Code Distribution

A bar or pie chart showing the proportion of `2xx`, `4xx`, and `5xx` responses. Use this to quickly detect error spikes.

- High `401` / `403` → authentication or authorization issue (check your JWT plan or API Key config).
- High `429` → rate limiting is being hit — review your quota settings (§3.1).
- High `502` / `503` → backend is down or the endpoint is misconfigured.

#### Top Paths

Shows the most frequently called paths on this API. Helps identify hotspots and misuse patterns.

1. Dashboard → **APIs** → your API → **Analytics** → scroll to **Top paths**.
2. Click any path to drill down into its specific request count and error rate.

#### Top Consumers

Lists the Applications or API Keys generating the most traffic.

1. Dashboard → **APIs** → your API → **Analytics** → **Top applications**.
2. Identify consumers that are approaching or exceeding their rate limits.

---

### 5.4 Platform-Level Analytics

**Goal:** Get a cross-API view of Gateway traffic — useful for capacity planning and detecting anomalies across services.

1. Dashboard → left sidebar → **Analytics** (the top-level item, not inside an API).
2. The platform dashboard shows aggregated metrics across all APIs in the selected environment.

Key panels at this level:

| Panel | What it shows |
|---|---|
| **Requests over time** | Total Gateway traffic across all APIs |
| **Top APIs** | Ranked list of APIs by request volume |
| **Top Applications** | Ranked list of consumer applications by traffic |
| **Response status distribution** | Overall 2xx / 4xx / 5xx breakdown |
| **Average response time** | Mean latency across all APIs |
| **Top Failed APIs** | APIs with the highest error rates — prioritize for investigation |

**To compare two APIs side by side:**

1. Platform Analytics → **Top APIs** table → click the first API to filter.
2. Use the **API filter** dropdown to add a second API.
3. Both are now overlaid on the time-series chart.

---

### 5.5 Analyzing Subscription and Consumer Activity

**Goal:** Track which applications are using which APIs and flag unusual subscription behaviour.

#### View all subscriptions for an API

1. Dashboard → **APIs** → open your API → **Subscriptions**.
2. Table columns: Application name, Plan subscribed to, Status, Created date, API Key (masked).
3. Filter by **Status**: `ACCEPTED`, `PENDING`, `PAUSED`, `CLOSED`.

#### View all subscriptions for an Application

1. Dashboard → **Applications** → open the Application → **Subscriptions**.
2. Shows every API and Plan this application is subscribed to, with the current API Key or token.

#### Identify and act on inactive subscriptions

1. Dashboard → **APIs** → your API → **Analytics** → **Top applications**.
2. Applications not appearing in the analytics window have sent zero traffic during that period.
3. Cross-reference with **Subscriptions** → consider pausing or closing stale subscriptions.

**To pause or close a subscription:**

1. Dashboard → **APIs** → your API → **Subscriptions** → find the subscription.
2. Click the row → **Pause** (temporary) or **Close** (permanent, revokes access immediately).

---

### 5.6 Exporting Audit and Analytics Data

#### Export Audit Logs as CSV

1. Dashboard → **Settings** → **Audit**.
2. Apply your filters (date range, event type, actor).
3. Click **Export** (top-right) → download as `.csv`.

The CSV includes: timestamp, event, actor, API/resource name, environment, and the raw patch JSON in a single column.

#### Export Analytics Data

1. Dashboard → **APIs** → your API → **Analytics**.
2. Set the date range and any filters.
3. Click **Export** → download as `.csv`.

Exported analytics columns include: date bucket, request count, success count, failure count, average latency (ms), min latency, max latency, p50, p95, p99.

> The built-in export is suitable for ad-hoc analysis in spreadsheet tools. For continuous pipeline ingestion, use log forwarding instead (see §5.7).

---

### 5.7 Forwarding Logs to External Systems

For teams who need audit and analytics data in a central log management system (e.g., Elasticsearch, Datadog, Splunk), Gravitee supports log reporters at the Gateway level.

#### Enable Elasticsearch Reporter

This is configured in the **Gateway's** `gravitee.yml` configuration file (outside the Dashboard):

```yaml
reporters:
  elasticsearch:
    enabled: true
    endpoints:
      - http://elasticsearch.internal:9200
    index: gravitee
    bulk:
      actions: 1000
      flush_interval: 1
    security:
      username: elastic
      password: <password>
```

Once the reporter is active, the Gateway pushes the following data to Elasticsearch in near real-time:

| Index Pattern | Content |
|---|---|
| `gravitee-request-*` | One document per API request: path, method, status, latency, consumer, API name |
| `gravitee-monitor-*` | Gateway health metrics: JVM, CPU, thread pools |
| `gravitee-log-*` | Full request/response body logs (if body logging is enabled per API) |

#### Enable Per-API Request Body Logging

> ⚠️ Enable this only for debugging. Body logging has a performance cost and may capture sensitive data.

1. Dashboard → **APIs** → open your API → **Settings** → **Logging**.
2. Toggle **Logging** to `ON`.
3. Configure:
   - **Mode:** `CLIENT_PROXY` (logs both the client request and what was sent to backend)
   - **Content:** `HEADERS_AND_PAYLOAD`
   - **Condition:** optionally limit to specific status codes, e.g. `{#response.status >= 500}`
4. **Save** → **Deploy**.

Logs appear in Dashboard → **APIs** → your API → **Logs** and in the `gravitee-log-*` Elasticsearch index.

---

## 6. Documenting Features and Options

Gravitee has a rich documentation system built into the Developer Portal. Every API can carry its own documentation, and the Portal is the single place consumers discover, read, and subscribe to APIs. This section covers every documentation feature available and how to use each one.

---

### 6.1 Documentation Page Types

When you add documentation to an API or the Portal, you choose a **page type**. Each serves a different purpose:

| Page Type | Best For | Rendered As |
|---|---|---|
| **Markdown** | Narrative docs, guides, changelogs, how-tos | Styled HTML in the Portal |
| **OpenAPI (Swagger)** | REST API contract: endpoints, schemas, request/response examples | Interactive Swagger UI or Redoc |
| **AsyncAPI** | Event-driven API contract: channels, messages, bindings | AsyncAPI rendered spec |
| **AsciiDoc** | Technical documentation with advanced formatting | Styled HTML |
| **Link** | Shortcut to an external URL (e.g., Confluence page, Postman collection) | Clickable link in the Portal sidebar |
| **Folder** | Groups related pages under a collapsible heading | Navigation section only |

**To add any page type:**

1. Dashboard → **APIs** → open your API → **Documentation** → **+ Add page**.
2. Select the page type.
3. Fill in **Name** (used as the sidebar label) and the content or source.
4. Toggle **Published** to control whether it's visible in the Portal.
5. **Save**.

---

### 6.2 Documentation Sources

For each page (regardless of type), you choose where the content comes from:

#### Inline Editor

Type or paste content directly into the built-in editor inside the Dashboard.

- Best for: small Markdown pages, quick notes, changelogs.
- Changes are saved immediately. Toggle **Published** to control visibility.

#### File Upload

Upload a local `.md`, `.yaml`, `.adoc`, or `.json` file.

1. **+ Add page** → select type → **Source: File** → upload the file.
2. The content is stored in Gravitee and is not re-fetched. To update it, upload a new file.

#### External URL

Fetch content from a publicly accessible URL at render time.

1. **Source: URL** → enter the URL (e.g., `https://raw.githubusercontent.com/company/service-a/main/docs/api.yaml`).
2. Configure **Fetch interval** (e.g., every 1 hour) to keep the content fresh.
3. Gravitee fetches the URL on the configured schedule and caches the result.

> Best for: OpenAPI specs served by your backend (`/v3/api-docs`) or maintained in a public repository.

#### GitHub / GitLab

Sync documentation directly from a Git repository branch. Covered in detail in §6.7.

---

### 6.3 Organizing Documentation with Folders

Use **Folder** pages to group related documentation under collapsible sections in the Portal sidebar.

**Create a folder:**

1. Dashboard → **APIs** → your API → **Documentation** → **+ Add page** → **Folder**.
2. **Name:** e.g., `Getting Started`
3. **Save**.

**Move pages into the folder:**

1. In the documentation list, drag the page under the folder **or** edit the page → set **Parent** to the folder name.
2. The folder appears as a collapsible heading in the Portal. Pages inside it appear as sub-items.

**Recommended folder structure for a production API:**

```
📁 Getting Started
   ├── Overview              (Markdown)
   ├── Authentication Guide  (Markdown)
   └── Quick Start           (Markdown)
📁 API Reference
   └── OpenAPI Specification (OpenAPI)
📁 Guides
   ├── Rate Limiting         (Markdown)
   └── Error Codes           (Markdown)
📄 Changelog                 (Markdown)
🔗 Postman Collection        (Link)
```

---

### 6.4 Managing Visibility and Access

Each documentation page has independent visibility controls.

| Setting | Behaviour |
|---|---|
| **Published: ON** | Page is visible in the Developer Portal to anyone who can view the API |
| **Published: OFF** | Page exists in the Dashboard but is hidden from the Portal — useful for drafts |
| **Private: ON** | Page is visible only to users who are logged into the Portal (not anonymous visitors) |
| **Private: OFF** | Page is visible to anonymous Portal users (if the API itself is publicly visible) |

**To set visibility on a page:**

1. Dashboard → **APIs** → your API → **Documentation** → click the page row.
2. Toggle **Published** and **Private** as needed.
3. **Save**.

**Controlling API-level Portal visibility:**

An API's documentation is only reachable if the API itself is visible. Set this at:

1. Dashboard → **APIs** → your API → **Settings** → **General**.
2. **Visibility:** `PUBLIC` (visible to all Portal users including anonymous) or `PRIVATE` (visible only to Portal members with explicit access).

---

### 6.5 API Metadata and Categorization

Metadata makes APIs discoverable in the Developer Portal and helps consumers find the right API.

#### Setting API Metadata

1. Dashboard → **APIs** → open your API → **Settings** → **General**.
2. Fill in:

   | Field | Purpose | Example |
   |---|---|---|
   | **Name** | Display name in Portal | `Service A — Resource API` |
   | **Version** | Shown alongside the name | `2.1.0` |
   | **Description** | Short summary shown in API cards | `Provides access to core resource data` |
   | **Labels** | Free-form tags for filtering | `internal`, `v2`, `deprecated` |
   | **Categories** | Curated groupings (defined in Portal Settings) | `Data`, `Internal`, `Partner` |
   | **Image / Logo** | Shown in Portal API cards | Upload a 200×200px PNG |

3. **Save** → **Deploy**.

#### Creating Categories (Admin)

1. Dashboard → **Settings** → **Categories** → **+ Add category**.
2. **Name:** e.g., `Internal Services`
3. **Description** and optional image.
4. **Save**.
5. Assign APIs to this category via the API's **Settings → General → Categories** field.

#### Adding Custom Metadata Fields

For fields not covered by the defaults (e.g., `team-owner`, `SLA`, `data-classification`):

1. Dashboard → **APIs** → your API → **Metadata** → **+ Add metadata**.
2. **Name:** `team-owner`
3. **Value:** `platform-team`
4. **Format:** `STRING` (or `NUMERIC`, `BOOLEAN`, `DATE`, `URL`)
5. **Save**.

Custom metadata is visible in the Portal and can be retrieved via the Management API.

---

### 6.6 Attaching Documentation to Plans

You can link a specific documentation page to a Plan so that subscribers see plan-specific instructions (e.g., different guides for API Key vs. JWT consumers).

1. Dashboard → **APIs** → your API → **Plans** → edit a plan.
2. In the plan editor → **General** tab → **Characteristics** section.
3. **Documentation page:** select the page to attach from the dropdown.
4. **Save** → **Deploy**.

The linked page appears in the Portal on the Plan's detail view, visible to consumers before they subscribe.

---

### 6.7 Syncing Docs from Git (GitHub / GitLab)

**Goal:** Keep documentation automatically in sync with files committed to your Git repository. When the repo changes, the Portal updates.

**Step 1 — Configure Git fetcher (Admin):**

1. Dashboard → **Settings** → **Documentation** → **Fetchers**.
2. Click **+ Add fetcher** → **GitHub** or **GitLab**.
3. Fill in:
   - **Name:** `service-a-docs-github`
   - **GitHub API URL:** `https://api.github.com` (or your GitHub Enterprise URL)
   - **Repository:** `company/service-a`
   - **Branch:** `main`
   - **Personal Access Token:** `<github-pat-with-repo-read-scope>`
4. **Save**.

**Step 2 — Link a documentation page to the fetcher:**

1. Dashboard → **APIs** → your API → **Documentation** → **+ Add page** → **Markdown**.
2. **Source:** select **GitHub** (or **GitLab**).
3. Select the fetcher configured above.
4. **File path in repo:** `docs/getting-started.md`
5. **Auto-fetch:** ON → set interval (e.g., `1 HOURS`).
6. Toggle **Published** → ON.
7. **Save**.

When the file at `docs/getting-started.md` is updated in the `main` branch, Gravitee fetches it on the next scheduled interval and updates the Portal page automatically.

**Syncing an entire folder from Git:**

1. **+ Add page** → **Folder** type → **Source: GitHub**.
2. **Directory path in repo:** `docs/` (the directory, not a single file).
3. Gravitee imports all Markdown and OpenAPI files in that directory as individual pages under the folder.

---

### 6.8 Documentation Reference — All Options

A complete reference of every configurable option on a documentation page.

| Option | Values | Description |
|---|---|---|
| **Name** | Free text | Sidebar label and page title in the Portal |
| **Type** | `MARKDOWN`, `OPENAPI`, `ASYNCAPI`, `ASCIIDOC`, `LINK`, `FOLDER` | Controls how content is rendered |
| **Source** | `INLINE`, `FILE`, `URL`, `GITHUB`, `GITLAB` | Where content is fetched from |
| **Published** | `ON` / `OFF` | Visible in Portal when ON |
| **Private** | `ON` / `OFF` | Requires Portal login when ON |
| **Order** | Integer | Controls sort position within the parent folder or root |
| **Parent** | Folder page name | Nests this page inside a folder |
| **Homepage** | `ON` / `OFF` | Sets this page as the API's default landing page in the Portal |
| **Auto-fetch** | `ON` / `OFF` | Re-fetches from URL or Git source on a schedule |
| **Fetch interval** | Integer + unit | How often to re-fetch (e.g., `1 HOURS`, `30 MINUTES`) |
| **Content-type override** | e.g., `application/json` | Forces a specific MIME type for URL-sourced content |
| **Characteristics (Plan link)** | Plan name | Associates this page with a specific Plan |
| **Try-it enabled** | `ON` / `OFF` | Shows the "Try it" button on OpenAPI pages |
| **Try-it URL** | URL | The base URL used by the Swagger UI try-it feature (defaults to the Gateway entrypoint) |
| **Show URL** | `ON` / `OFF` | Displays the source URL on the Portal page (for Link type) |
| **OpenAPI display** | `Swagger UI` / `Redoc` | Which renderer to use for OpenAPI pages |
| **Access Control** | Group names | Restrict page visibility to specific Portal user groups |

---

*Document version: 2.0 | Gravitee 4.x | Last updated: 2026*
