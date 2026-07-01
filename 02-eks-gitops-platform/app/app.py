"""Orders API — stateless service for the EKS demo.

Kept intentionally simple. The interesting engineering is in the Kubernetes
manifests and the EKS platform, not the app itself.
"""
import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/healthz")
def healthz():
    """Kubernetes liveness/readiness probes hit this."""
    return jsonify(status="ok"), 200


@app.get("/")
def index():
    return jsonify(
        service="orders-api",
        # Pod name is injected via the Downward API in the Deployment manifest.
        pod=os.environ.get("POD_NAME", socket.gethostname()),
        node=os.environ.get("NODE_NAME", "unknown"),
        version=os.environ.get("APP_VERSION", "1.0.0"),
    )


@app.get("/orders")
def orders():
    return jsonify(
        orders=[
            {"id": "A-1001", "item": "Trail Runner Shoes", "qty": 1},
            {"id": "A-1002", "item": "Merino Wool Socks", "qty": 3},
        ],
        pod=os.environ.get("POD_NAME", socket.gethostname()),
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
