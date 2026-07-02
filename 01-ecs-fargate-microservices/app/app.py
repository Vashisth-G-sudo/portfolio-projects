"""ShopFront API — a dynamic, database-backed product catalog on ECS Fargate.

Products are stored in DynamoDB (create / read / update / delete). The task's
IAM role grants least-privilege access to a single table.
"""
import decimal
import hashlib
import os
import socket
import uuid

import boto3
from botocore.exceptions import ClientError
from flask import Flask, jsonify, request, send_from_directory

app = Flask(__name__)

TABLE_NAME = os.environ.get("TABLE_NAME", "shopfront-products")
REGION = os.environ.get("AWS_REGION", "us-east-1")

_dynamodb = boto3.resource("dynamodb", region_name=REGION)
_table = _dynamodb.Table(TABLE_NAME)

# Seeded on first boot if the table is empty.
SEED = [
    {"name": "Trail Runner Shoes", "price": 89.99},
    {"name": "Merino Wool Socks", "price": 18.50},
    {"name": "Insulated Water Bottle", "price": 27.00},
]


def _to_json(item):
    """Convert DynamoDB Decimals to floats for clean JSON output."""
    return {
        "id": item["id"],
        "name": item["name"],
        "price": float(item["price"]) if isinstance(item["price"], decimal.Decimal) else item["price"],
    }


def _seed_if_empty():
    try:
        existing = _table.scan(Limit=1).get("Items", [])
        if not existing:
            for p in SEED:
                # Deterministic id per seed name so concurrent workers overwrite
                # the same row instead of creating duplicates.
                seed_id = hashlib.md5(p["name"].encode()).hexdigest()[:8]
                _table.put_item(Item={
                    "id": seed_id,
                    "name": p["name"],
                    "price": decimal.Decimal(str(p["price"])),
                })
    except ClientError as e:
        app.logger.warning("Seed skipped: %s", e)


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


@app.get("/")
def index():
    return send_from_directory(os.path.dirname(__file__), "index.html")


@app.get("/api/info")
def info():
    return jsonify(
        service="shopfront-api",
        served_by=socket.gethostname(),
        version=os.environ.get("APP_VERSION", "1.0.0"),
        store="dynamodb",
    )


@app.get("/products")
def list_products():
    items = _table.scan().get("Items", [])
    products = sorted((_to_json(i) for i in items), key=lambda p: p["name"])
    return jsonify(products=products, served_by=socket.gethostname())


@app.post("/products")
def create_product():
    body = request.get_json(silent=True) or {}
    name = (body.get("name") or "").strip()
    price = body.get("price")
    if not name or price is None:
        return jsonify(error="name and price are required"), 400
    item = {
        "id": uuid.uuid4().hex[:8],
        "name": name,
        "price": decimal.Decimal(str(price)),
    }
    _table.put_item(Item=item)
    return jsonify(_to_json(item)), 201


@app.put("/products/<pid>")
def update_product(pid):
    body = request.get_json(silent=True) or {}
    updates, names, values = [], {}, {}
    if "name" in body:
        updates.append("#n = :n")
        names["#n"] = "name"
        values[":n"] = body["name"].strip()
    if "price" in body:
        updates.append("price = :p")
        values[":p"] = decimal.Decimal(str(body["price"]))
    if not updates:
        return jsonify(error="nothing to update"), 400
    resp = _table.update_item(
        Key={"id": pid},
        UpdateExpression="SET " + ", ".join(updates),
        ExpressionAttributeNames=names or None,
        ExpressionAttributeValues=values,
        ReturnValues="ALL_NEW",
    )
    return jsonify(_to_json(resp["Attributes"]))


@app.delete("/products/<pid>")
def delete_product(pid):
    _table.delete_item(Key={"id": pid})
    return jsonify(deleted=pid), 200


_seed_if_empty()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
