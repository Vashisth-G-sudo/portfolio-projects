terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "orders-eks"
  tags = {
    Project     = "orders-eks"
    ManagedBy   = "terraform"
    Environment = "ephemeral" # this stack is meant to be created and destroyed
    auto-delete = "no"        # opt out of account auto-cleanup automation
  }
}
