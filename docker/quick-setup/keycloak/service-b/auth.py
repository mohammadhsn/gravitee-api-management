import requests
from functools import wraps
from flask import request, jsonify
from jose import jwt, JWTError
import config

# Cache for JWKS keys
_jwks_cache = None


def get_jwks():
    """Fetch and cache JWKS from Keycloak (only fetched once at startup)."""
    global _jwks_cache
    if _jwks_cache is None:
        response = requests.get(config.JWKS_URL)
        response.raise_for_status()
        _jwks_cache = response.json()
    return _jwks_cache


def validate_token(token):
    """Validate JWT token offline using cached JWKS."""
    try:
        jwks = get_jwks()

        # Decode and validate the token
        # Note: Keycloak uses 'azp' (authorized party) for client ID, not 'aud'
        payload = jwt.decode(
            token,
            jwks,
            algorithms=["RS256"],
            issuer=config.ISSUER,
            options={"verify_aud": False}
        )

        # Verify the authorized party (azp) matches our client
        if payload.get("azp") != config.CLIENT_ID:
            raise ValueError(f"Invalid authorized party: expected {config.CLIENT_ID}")

        return payload
    except JWTError as e:
        raise ValueError(f"Token validation failed: {str(e)}")


def require_auth(f):
    """Decorator to protect routes with token validation."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return jsonify({"error": "Missing Authorization header"}), 401

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return jsonify({"error": "Invalid Authorization header format"}), 401

        token = parts[1]

        try:
            payload = validate_token(token)
            request.token_payload = payload
        except ValueError as e:
            return jsonify({"error": str(e)}), 401
        except Exception as e:
            return jsonify({"error": f"Authentication failed: {str(e)}"}), 401

        return f(*args, **kwargs)

    return decorated
