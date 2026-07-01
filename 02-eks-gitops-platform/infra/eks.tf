# --- EKS cluster (official AWS module) --------------------------------------
# A managed control plane plus a small managed node group. IRSA (IAM Roles for
# Service Accounts) is enabled so pods get least-privilege AWS permissions.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  # Public endpoint so you can reach it with kubectl from your laptop for the
  # demo. In production you'd restrict this to known CIDRs or go private.
  cluster_endpoint_public_access = true

  enable_irsa = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Give the identity running terraform admin on the cluster.
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = [var.node_instance_type]
      capacity_type  = var.use_spot ? "SPOT" : "ON_DEMAND"
    }
  }

  tags = local.tags
}
