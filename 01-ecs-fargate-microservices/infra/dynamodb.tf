# --- DynamoDB table (the dynamic data store) --------------------------------
# On-demand (pay-per-request) billing keeps this within the free tier for a
# demo - effectively $0/month. Stores the product catalog that the app now
# creates, reads, updates, and deletes.

resource "aws_dynamodb_table" "products" {
  name         = "shopfront-products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.tags
}
