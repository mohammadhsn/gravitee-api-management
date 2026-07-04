# Service-B (OAuth Resource Server)

A minimal Flask OAuth resource server that validates JWT tokens offline against Keycloak.

## Configuration

- **Keycloak URL**: `http://localhost:8080`
- **Realm**: `master`
- **Client ID**: `service-b`

## Setup

```bash
source venv/bin/activate
python app.py
```

## Endpoints

| Endpoint | Auth Required | Description |
|----------|---------------|-------------|
| `/health` | No | Health check |
| `/protected` | Yes | Protected resource |

## Usage

```bash
# Health check (no auth)
curl http://localhost:5000/health

# Protected endpoint (requires token)
curl -H "Authorization: Bearer <your-token>" http://localhost:5000/protected
```

## Token Requirements

Tokens must:
- Be signed with RS256
- Have issuer: `http://localhost:8080/realms/master`
- Have audience: `service-b`
