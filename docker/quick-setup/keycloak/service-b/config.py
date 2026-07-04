import os

# Keycloak Configuration
#
# KEYCLOAK_URL        : internal URL used for server-to-server calls (JWKS fetch).
#                       Must be reachable FROM this container -> the in-network
#                       service name, NOT localhost.
# KEYCLOAK_ISSUER_URL : public base URL that appears in the token's `iss` claim,
#                       i.e. Keycloak's KC_HOSTNAME. Validation compares against it,
#                       so it must match how tokens are minted (here: localhost:8080;
#                       on a VM set it to http://<PUBLIC_HOST>:8080).
KEYCLOAK_URL = os.getenv("KEYCLOAK_URL", "http://keycloak:8080")
KEYCLOAK_ISSUER_URL = os.getenv("KEYCLOAK_ISSUER_URL", "http://localhost:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "master")
CLIENT_ID = os.getenv("CLIENT_ID", "service-b")

# JWKS endpoint for offline token validation (fetched over the internal URL)
JWKS_URL = f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/certs"
# Expected issuer (must equal the token's `iss`)
ISSUER = f"{KEYCLOAK_ISSUER_URL}/realms/{KEYCLOAK_REALM}"
