curl -X POST "http://keycloak:8080/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=service-b" \
  -d "client_secret=DbRTryAfEIzjzFuFbltfOHmhTwA7bm5B"
