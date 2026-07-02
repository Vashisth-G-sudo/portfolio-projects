# AWS Container Portfolio - ECS & EKS

Two production-shaped, cost-conscious projects that demonstrate container
orchestration depth on AWS. Built to showcase Solutions Architect skills:
containerization, networking, IAM least-privilege, autoscaling, observability,
Infrastructure as Code, and - importantly - **deliberate cost management**.

| # | Project | Focus | Live cost (24/7) | Strategy |
|---|---------|-------|------------------|----------|
| 1 | [ShopFront on ECS Fargate](./01-ecs-fargate-microservices/) | Amazon ECS + Fargate, ALB, ECR, autoscaling | ~$26/month | Runs live for demos |
| 2 | [Orders Platform on EKS](./02-eks-gitops-platform/) | Amazon EKS, Kubernetes, ALB Ingress, HPA, IRSA | ~$80/month if 24/7 | **Ephemeral** - apply, demo, destroy |
| 3 | [CI/CD Pipeline](./03-cicd-pipeline/) | GitHub Actions → ECS, OIDC keyless deploy | $0 | Reuses project 01 |

**Decision memo:** [ECS vs EKS - when to choose which](./ECS-vs-EKS-decision.md)
- an SA-style architecture decision doc tying the projects together.

**Interview prep:** [Cheat sheet](./INTERVIEW-CHEATSHEET.md) - how to present
these projects, talking points, and likely follow-up questions.

## Why two orchestrators?

A Solutions Architect is expected to know *when* to reach for ECS versus EKS.
These projects tell that story directly:

- **ECS Fargate** - lowest operational overhead, no control-plane fee, ideal
  when a team wants containers without Kubernetes. Cheap enough to leave running.
- **EKS** - full Kubernetes API, portability, and ecosystem (Helm, GitOps,
  operators) when an org has standardized on Kubernetes or needs multi-cloud
  portability. Costs more, so I run it as a cost-managed ephemeral environment.

## The cost discipline (the SA angle)

Every design decision is annotated with its cost impact. Each project has a
`COST.md` with a line-item breakdown. The EKS project is intentionally built so
the entire environment is created and destroyed with one command each, keeping
real spend to demo hours only - the same FinOps discipline you'd apply to
non-production environments at a company.

## How to demo these

1. Read each project's `README.md` - written for a non-expert reviewer.
2. `terraform apply` in the `infra/` folder to stand it up.
3. Record a short screen walkthrough (great for a portfolio site or interview).
4. For EKS: `terraform destroy` when done to stop the control-plane charge.
