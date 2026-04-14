# Gateway Third-Party Authentication Strategy

> **Context Document for Claude Code Sessions**
> Last Updated: 2025-01-25

## Problem Statement

We have a Gravitee API Gateway integrated with Keycloak as our SSO solution. The gateway sits in front of multiple third-party services (e.g., accounting, ERP), each with their own authentication requirements.

### Requirements

1. **Users authenticate only with Keycloak** - They should not deal with third-party auth
2. **Third-party services are Keycloak clients** - Each service is registered in Keycloak
3. **Gateway handles token lifecycle** - Fetch, refresh, and inject tokens transparently
4. **Service account tokens are acceptable** - No need to maintain per-user identity for third-party calls

### Architecture Diagram

```
                         ┌─────────────────┐
                         │    Keycloak     │
                         │  (Central SSO)  │
                         └────────┬────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
    ┌────▼────┐             ┌─────▼─────┐            ┌─────▼─────┐
    │ Client: │             │  Client:  │            │  Client:  │
    │  user-  │             │ accounting│            │  erp-     │
    │  app    │             │ -service  │            │  service  │
    └─────────┘             └───────────┘            └───────────┘
         │                        ▲                        ▲
         │                        │                        │
    User Auth              Gateway uses              Gateway uses
                           client_credentials        client_credentials
```

## Chosen Solution: Fresh Token Per Request

### Decision Rationale

| Consideration | Decision |
|---------------|----------|
| Token caching for performance | NOT a priority |
| Token expiration/refresh handling | CRITICAL |
| User identity in third-party calls | NOT required (service account OK) |

**Result**: Fetch a fresh token from Keycloak on every request. This eliminates all expiration/refresh complexity since tokens are always fresh.

### Trade-offs Accepted

| Aspect | Impact |
|--------|--------|
| Latency | +20-50ms per request (Keycloak token call) |
| Keycloak load | 1 token request per API request |
| Simplicity | Maximum - no state management |
| Reliability | Token always valid |

## Implementation Details

### Flow Per Request

```
User Request → [Validate User's Keycloak JWT] → Gateway
                                                   │
                                    ┌──────────────┴──────────────┐
                                    │ 1. HTTP Callout to Keycloak │
                                    │    - client_credentials     │
                                    │    - Get fresh token        │
                                    ├─────────────────────────────┤
                                    │ 2. Transform Headers        │
                                    │    - Add Authorization      │
                                    └──────────────┬──────────────┘
                                                   │
                                                   ▼
                                           Third-Party Backend
```

### Gravitee Policy Configuration

#### Policy 1: HTTP Callout (Request Phase)

```json
{
  "name": "http-callout",
  "policy": "policy-http-callout",
  "configuration": {
    "method": "POST",
    "url": "https://keycloak.example.com/realms/{REALM}/protocol/openid-connect/token",
    "headers": [
      {
        "name": "Content-Type",
        "value": "application/x-www-form-urlencoded"
      }
    ],
    "body": "grant_type=client_credentials&client_id={#properties['backend_client_id']}&client_secret={#properties['backend_client_secret']}",
    "variables": [
      {
        "name": "backend_token",
        "value": "{#jsonPath(#calloutResponse.content, '$.access_token')}"
      }
    ],
    "exitOnError": true,
    "errorCondition": "{#calloutResponse.status >= 400}",
    "errorStatusCode": "503",
    "errorContent": "Unable to authenticate with backend service"
  }
}
```

#### Policy 2: Transform Headers (Request Phase)

```json
{
  "name": "transform-headers",
  "policy": "policy-transformheaders",
  "configuration": {
    "addHeaders": [
      {
        "name": "Authorization",
        "value": "Bearer {#context.attributes['backend_token']}"
      }
    ]
  }
}
```

### API Properties Configuration

Store credentials securely in API properties:

```yaml
properties:
  keycloak_realm: "your-realm"
  keycloak_url: "https://keycloak.example.com"
  backend_client_id: "accounting-service"
  backend_client_secret: "your-client-secret"  # Use secrets manager in production
```

### Keycloak Client Setup

For each third-party service, configure the Keycloak client:

```
Client ID: accounting-service (or erp-service, etc.)
Client Protocol: openid-connect
Access Type: confidential
Service Accounts Enabled: ON
Direct Access Grants: OFF (not needed)
```

## Multiple Third-Party Services

### Option A: Separate API per Backend

Each Gravitee API targets one third-party service with its own credentials.

```
/api/accounting/* → Accounting API (uses accounting-service client)
/api/erp/*        → ERP API (uses erp-service client)
```

### Option B: Dynamic Backend Selection (Future Enhancement)

Use conditional flows or dynamic properties based on request path.

## Future Enhancements (If Needed)

### If Latency Becomes an Issue: Add Token Caching

```
Options:
1. Groovy policy with in-memory cache (TTL = token_expiry - 60s)
2. Redis cache resource
3. Custom Gravitee Resource plugin for Keycloak tokens
```

### If Per-User Identity Needed: Token Exchange

Switch from `client_credentials` to Keycloak Token Exchange (RFC 8693):
- Exchange user's token for a token scoped to the third-party service
- Maintains user identity for audit/authorization

## Reference Links

- [Gravitee HTTP Callout Policy](https://documentation.gravitee.io/apim/create-and-configure-apis/apply-policies/policy-reference/http-callout)
- [Gravitee Transform Headers Policy](https://documentation.gravitee.io/apim/policies/transform-headers)
- [Keycloak Client Credentials Grant](https://www.keycloak.org/docs/latest/securing_apps/#_client_credentials_grant)
- [Keycloak Token Exchange](https://www.keycloak.org/docs/latest/securing_apps/#_token-exchange)

## Session Notes

- **2025-01-25**: Initial architecture discussion. Decided on "fresh token per request" approach for simplicity. Service account tokens acceptable. Performance optimization (caching) deferred.

---

*This document serves as context for future Claude Code sessions on this project.*
