variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "Worker node size. t3.small keeps the demo cheap."
  type        = string
  default     = "t3.small"
}

variable "use_spot" {
  description = "Run worker nodes on Spot for ~70% savings."
  type        = bool
  default     = true
}
