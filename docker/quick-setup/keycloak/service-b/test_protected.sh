#!/bin/bash

# Configuration
SERVICE_URL="http://localhost:5000"
CLIENT_SECRET="${CLIENT_SECRET:-}"

if [ -z "$CLIENT_SECRET" ]; then
    echo "Usage: CLIENT_SECRET=<your-secret> ./test_protected.sh"
    echo "   or: ./test_protected.sh <your-secret>"

    if [ -n "$1" ]; then
        CLIENT_SECRET="$1"
    else
        exit 1
    fi
fi

# Get token
echo "Fetching token from Keycloak..."
TOKEN=$(python get_token.py -c -s "$CLIENT_SECRET" 2>/dev/null | head -2 | tail -1)

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to get token"
    exit 1
fi

echo "Token received."
echo ""
echo "Calling protected endpoint..."
curl -s -H "Authorization: Bearer $TOKEN" "$SERVICE_URL/protected" | python -m json.tool
