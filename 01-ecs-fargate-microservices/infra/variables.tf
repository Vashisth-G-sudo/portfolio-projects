variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "container_image" {
  description = "Full ECR image URI (e.g. <acct>.dkr.ecr.us-east-1.amazonaws.com/shopfront:latest). Leave blank on first apply to create ECR only."
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "Baseline number of Fargate tasks."
  type        = number
  default     = 1
}

variable "use_fargate_spot" {
  description = "Run tasks on Fargate Spot for ~70% savings. Great for demos."
  type        = bool
  default     = true
}
