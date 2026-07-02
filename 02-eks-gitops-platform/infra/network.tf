# --- VPC (official AWS module) ----------------------------------------------
# Public + private subnets across 2 AZs. A single NAT Gateway (not one per AZ)
# keeps cost down for an ephemeral environment.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = "10.30.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.30.1.0/24", "10.30.2.0/24"]
  public_subnets  = ["10.30.101.0/24", "10.30.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # one NAT instead of two - cheaper for a demo

  # Tags required by the AWS Load Balancer Controller for subnet discovery.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}
