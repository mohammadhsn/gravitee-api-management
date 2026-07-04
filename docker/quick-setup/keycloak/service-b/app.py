from flask import Flask, jsonify, request
from auth import require_auth

app = Flask(__name__)


@app.route("/health")
def health():
    """Public health check endpoint."""
    return jsonify({"status": "healthy"})


@app.get("/protected")
@require_auth
def protected():
    """Protected endpoint - requires valid token."""
    payload = request.token_payload
    return jsonify({
        "message": "Access granted",
        "user": payload.get("preferred_username"),
        "email": payload.get("email"),
        "sub": payload.get("sub")
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
