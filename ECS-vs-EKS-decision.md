# Architecture Decision: When to Choose ECS vs EKS

A short decision memo written to accompany the two container projects in this
portfolio. It's the kind of "help a team pick the right service" reasoning a
Solutions Architect does constantly.

## TL;DR

- **Default to ECS + Fargate** for most teams running containers on AWS. Lowest
  operational overhead, no control-plane fee, fastest path to production.
- **Choose EKS** when the organization has standardized on Kubernetes, needs
  its ecosystem (Helm, operators, GitOps), or requires portability across clouds
  / on-prem.
- Don't pick EKS for the resume. Pick it for a real requirement, then justify
  the extra cost and complexity.

## The two projects, side by side

| Dimension | ECS + Fargate (project 01) | EKS (project 02) |
|-----------|----------------------------|------------------|
| Control-plane cost | **$0** | ~$73/month (fixed) |
| Learning curve | Low - AWS-native concepts | High - full Kubernetes |
| Operational overhead | Minimal | Cluster + add-ons to manage |
| Ecosystem / portability | AWS-only | Huge; portable across clouds |
| Autoscaling | Application Auto Scaling | HPA + Cluster Autoscaler/Karpenter |
| Load balancing | Native ALB integration | ALB via Load Balancer Controller |
| IAM for workloads | Task roles | IRSA / Pod Identity |
| Best when… | You just want containers | You want/need Kubernetes |

## Decision guide

```
Do you (or will you) run Kubernetes elsewhere, or need its ecosystem?
├── No  → Do you want minimum ops overhead and lowest cost?
│         ├── Yes → ECS + Fargate            ✅ (most teams land here)
│         └── Need fine-grained node control / GPUs / bin-packing?
│                   → ECS on EC2  or  EKS
└── Yes → Need multi-cloud portability, Helm/operators, GitOps, or a
          large existing K8s skill base?
          └── Yes → EKS
```

## Cost reality (the part people skip)

The single biggest practical difference is the **fixed control-plane fee**:

- ECS adds nothing on top of the compute you'd pay for anyway.
- EKS costs ~$73/month **before a single pod runs**, plus nodes, NAT, and ALBs.

For non-production or demo environments, the right move with EKS is to treat the
cluster as **ephemeral** - codify it in Terraform and destroy it when idle
(exactly what project 02 does). In production, you justify the control-plane fee
against the value Kubernetes delivers, and you drive per-workload cost down with
Spot, right-sizing, Karpenter, and Savings Plans / Compute Savings Plans.

## Common mistakes I'd flag as an SA

1. **Choosing EKS by default.** Most teams don't need Kubernetes; ECS ships
   faster and cheaper.
2. **Running EKS control planes 24/7 for dev/test.** Use ephemeral or shared
   non-prod clusters.
3. **One NAT Gateway per AZ in non-prod.** A single NAT is fine for demos and
   saves ~$33/month per AZ removed.
4. **On-demand everything.** Spot for stateless/fault-tolerant workloads is a
   ~70% saving in both ECS and EKS.
5. **Long-lived CI credentials.** Use OIDC federation (see project 03) instead
   of stored access keys.

## How this maps to the portfolio

- **Project 01 (ECS)** is the "default choice" reference implementation.
- **Project 02 (EKS)** is the "we need Kubernetes" reference implementation, run
  cost-consciously as an ephemeral environment.
- **Project 03 (CI/CD)** shows how either target gets safe, automated,
  keyless deployments.

Together they demonstrate not just that I *can* build on ECS and EKS, but that I
know *which one to recommend and why* - including the cost trade-offs.
