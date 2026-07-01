"""ShopFront API — a tiny stateless microservice for the ECS Fargate demo.

Exposes a small product catalog over HTTP. Deliberately simple so the focus
stays on the ECS/Fargate/ALB architecture rather than application logic.
"""
import os
import socket

from flask import Flask, jsonify, send_from_directory

app = Flask(__name__)

# In a real system this would come from DynamoDB or RDS. Kept in-memory here
# so the demo has zero data-tier cost.
PRODUCTS = [
    {"id": 1, "name": "Trail Runner Shoes", "price": 89.99},
    {"id": 2, "name": "Merino Wool Socks", "price": 18.50},
    {"id": 3, "name": "Insulated Water Bottle", "price": 27.00},
]


@app.get("/health")
def health():
    """ALB target-group health check hits this endpoint."""
    return jsonify(status="ok"), 200


@app.get("/")
def index():
    """Serve the storefront web page."""
    return send_from_directory(os.path.dirname(__file__), "index.html")


@app.get("/api/info")
def info():
    """JSON service info (previously served at /)."""
    return jsonify(
        service="shopfront-api",
        # Task hostname proves requests are load-balanced across tasks.
        served_by=socket.gethostname(),
        version=os.environ.get("APP_VERSION", "1.0.0"),
    )


@app.get("/products")
def products():
    return jsonify(products=PRODUCTS, served_by=socket.gethostname())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
