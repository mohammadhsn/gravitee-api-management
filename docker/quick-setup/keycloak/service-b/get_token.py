#!/usr/bin/env python3
"""
Script to request an access token from Keycloak for service-b.
"""
import requests

# Keycloak configuration
KEYCLOAK_URL = "http://localhost:8080"
REALM = "master"
CLIENT_ID = "service-b"

# Token endpoint
TOKEN_URL = f"{KEYCLOAK_URL}/realms/{REALM}/protocol/openid-connect/token"


def get_token(username: str, password: str, client_secret: str = None) -> dict:
    """
    Request an access token using Resource Owner Password Credentials grant.
    """
    data = {
        "grant_type": "password",
        "client_id": CLIENT_ID,
        "username": username,
        "password": password,
    }

    if client_secret:
        data["client_secret"] = client_secret

    response = requests.post(TOKEN_URL, data=data)
    response.raise_for_status()
    return response.json()


def get_token_client_credentials(client_secret: str) -> dict:
    """
    Request an access token using Client Credentials grant.
    (For service-to-service authentication)
    """
    data = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": client_secret,
    }

    response = requests.post(TOKEN_URL, data=data)
    response.raise_for_status()
    return response.json()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Get access token from Keycloak")
    parser.add_argument("--username", "-u", help="Username for password grant")
    parser.add_argument("--password", "-p", help="Password for password grant")
    parser.add_argument("--client-secret", "-s", help="Client secret (if confidential client)")
    parser.add_argument("--client-credentials", "-c", action="store_true",
                        help="Use client credentials grant instead of password grant")

    args = parser.parse_args()

    try:
        if args.client_credentials:
            if not args.client_secret:
                print("Error: --client-secret required for client credentials grant")
                exit(1)
            token_response = get_token_client_credentials(args.client_secret)
        else:
            if not args.username or not args.password:
                print("Error: --username and --password required for password grant")
                print("\nUsage examples:")
                print("  Password grant:     python get_token.py -u admin -p admin")
                print("  Client credentials: python get_token.py -c -s <client-secret>")
                exit(1)
            token_response = get_token(args.username, args.password, args.client_secret)

        print("Access Token:")
        print(token_response.get("access_token"))
        print("\n--- Full Response ---")
        print(f"Token Type: {token_response.get('token_type')}")
        print(f"Expires In: {token_response.get('expires_in')} seconds")

    except requests.exceptions.HTTPError as e:
        print(f"Error: {e}")
        print(f"Response: {e.response.text}")
    except requests.exceptions.ConnectionError:
        print(f"Error: Could not connect to Keycloak at {KEYCLOAK_URL}")
