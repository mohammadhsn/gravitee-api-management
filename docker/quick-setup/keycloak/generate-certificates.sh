#!/usr/bin/env bash
#
# Generate the TLS material the nginx edge needs to serve this stack over HTTPS.
#
#   ./generate-certificates.sh                 # host: localhost
#   ./generate-certificates.sh apim.mycorp.lan # a real hostname
#   HOSTS="a.lan,b.lan" ./generate-certificates.sh a.lan   # extra SANs
#
# Produces, in .certificates/ (gitignored via docker/quick-setup/**/.certificates):
#   ca.pem      the local CA cert  -> trust this to get a clean padlock, see README
#   ca.key      the local CA key
#   nginx.cer   server cert for $HOST, signed by that CA
#   nginx.key   server key (unencrypted -- nginx cannot prompt for a passphrase)
#
# This is adapted from ../https-nginx/generate-certificates.sh, with the client
# keystore / truststore parts REMOVED. That setup is an mTLS demo: it serves only the
# gateway on 443 with `ssl_verify_client on`, and leaves the console/APIs on plain :80.
# Here we want the opposite -- the WHOLE stack behind one server cert, no client certs.
#
# ⚠️ Self-signed. Fine for a local stack; see the README note about trusting ca.pem.
set -euo pipefail
cd "$(dirname "$0")"

HOST="${1:-localhost}"
OUT=".certificates"
DAYS_CA=3650
DAYS_CERT=1460

mkdir -p "$OUT"

# Build the SAN list. The hostname MUST be in the SAN -- a matching CN alone is
# rejected by every current browser. `localhost` is always included so the stack keeps
# working when reached that way, and an IP SAN is added automatically if $HOST is an IP
# (Gravitee itself rejects IP literals in its installation URLs, but the cert can still
# cover one for direct curl testing).
SANS="DNS:${HOST}"
[ "$HOST" != "localhost" ] && SANS="${SANS},DNS:localhost"
if printf '%s' "$HOST" | grep -qE '^[0-9]+(\.[0-9]+){3}$'; then
    SANS="${SANS},IP:${HOST}"
fi
# Optional extra names: HOSTS="a.lan,b.lan" ./generate-certificates.sh
if [ -n "${HOSTS:-}" ]; then
    IFS=',' read -ra EXTRA <<< "$HOSTS"
    for h in "${EXTRA[@]}"; do
        [ -n "$h" ] && [ "$h" != "$HOST" ] && SANS="${SANS},DNS:${h}"
    done
fi

echo ">> host: $HOST"
echo ">> SANs: $SANS"

if [ -f "$OUT/ca.pem" ] && [ -f "$OUT/ca.key" ]; then
    echo ">> reusing existing CA ($OUT/ca.pem) -- delete it to start over"
else
    echo ">> generating local CA"
    # -nodes: unencrypted CA key. This is a local demo CA; a passphrase here only
    # means every re-run prompts. Do not reuse this CA for anything real.
    openssl req -x509 -newkey rsa:4096 -nodes \
        -days "$DAYS_CA" \
        -keyout "$OUT/ca.key" -out "$OUT/ca.pem" \
        -subj "/CN=Gravitee local demo CA/O=GraviteeSource/OU=Demo" \
        -addext "basicConstraints=critical,CA:TRUE" \
        -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
fi

echo ">> generating server key + CSR"
openssl genrsa -out "$OUT/nginx.key" 2048 2>/dev/null
openssl req -new -key "$OUT/nginx.key" -out "$OUT/nginx.csr" -sha256 \
    -subj "/CN=${HOST}/O=GraviteeSource/OU=Demo" 2>/dev/null

# The SAN and the server/EKU extensions have to be applied at SIGNING time, not from
# the CSR, otherwise openssl silently drops them and you get a cert browsers reject.
cat > "$OUT/nginx.ext" <<EOF
basicConstraints = CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = ${SANS}
EOF

echo ">> signing server cert with the CA"
openssl x509 -req -in "$OUT/nginx.csr" \
    -CA "$OUT/ca.pem" -CAkey "$OUT/ca.key" -CAcreateserial \
    -days "$DAYS_CERT" -sha256 \
    -extfile "$OUT/nginx.ext" \
    -out "$OUT/nginx.cer" 2>/dev/null
rm -f "$OUT/nginx.csr" "$OUT/nginx.ext"

echo ">> verifying"
# 1. key matches cert -- these two hashes must be identical
a=$(openssl x509 -in "$OUT/nginx.cer" -noout -pubkey | openssl sha256 | awk '{print $2}')
b=$(openssl pkey -in "$OUT/nginx.key" -pubout | openssl sha256 | awk '{print $2}')
[ "$a" = "$b" ] || { echo "   ✗ key does not match cert"; exit 1; }
echo "   key matches cert"
# 2. SAN actually made it in
openssl x509 -in "$OUT/nginx.cer" -noout -ext subjectAltName | tail -1 | sed 's/^/   SAN:/'
# 3. chain verifies against our CA
openssl verify -CAfile "$OUT/ca.pem" "$OUT/nginx.cer" | sed 's/^/   /'
openssl x509 -in "$OUT/nginx.cer" -noout -dates | sed 's/^/   /'

echo
echo ">> done. Files in $OUT/ :"
ls -1 "$OUT" | sed 's/^/     /'
echo
echo "   nginx serves nginx.cer + nginx.key."
echo "   To avoid browser warnings, trust $OUT/ca.pem (see README)."
