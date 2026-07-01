# Private container registry for the ShopFront image.
resource "aws_ecr_repository" "app" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true # lets `terraform destroy` clean up images too

  image_scanning_configuration {
    scan_on_push = true # basic vulnerability scanning at no cost
  }
  tags = local.tags
}

# Keep only the 5 most recent images so ECR storage stays near-free.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
