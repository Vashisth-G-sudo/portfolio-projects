# Interview Cheat Sheet — Presenting This Portfolio

A quick reference for talking through these projects in a Solutions Architect
interview. Lead with the *decision*, then the *design*, then the *cost*.

## 30-second pitch (memorize this)

> "I built three projects to show container depth on AWS. One runs on ECS
> Fargate — the low-overhead default. One runs on EKS to show Kubernetes depth,
> which I run as an ephemeral, cost-managed environment because the control
> plane is a fixed ~$73/month. And a CI/CD pipeline deploys to them with keyless
> OIDC auth. I also wrote a decision memo on when to choose ECS vs EKS, because
> the real SA skill is picking the right tool, not just using every tool."

## The story arc (how to sequence it)

1. **Problem framing** → "Teams need to run containers on AWS. The first
   question isn't *how*, it's *which orchestrator*."
2. **Project 1 (ECS)** → the pragmatic default.
3. **Project 2 (EKS)** → when Kubernetes is actually justified.
4. **Project 3 (CI/CD)** → shipping safely to either.
5. **Decision memo** → the judgment that ties it together.

## Per-project talking points

### Project 1 — ShopFront on ECS Fargate
- **What:** Containerized API on ECS Fargate behind an ALB, autoscaling 1→4.
- **Why it's cheap:** No control-plane fee, Fargate Spot, no NAT Gateway,
  smallest task size. ~$26/month.
- **Security one-liner:** "Tasks only accept traffic from the ALB's security
  group, run as non-root, and the task role is least-privilege."
- **Depth probe answers:** awsvpc networking gives each task an ENI; target-type
  `ip` is required for Fargate; health checks gate traffic at the ALB.

### Project 2 — Orders Platform on EKS
- **What:** Same style of app on EKS with Deployment/Service/Ingress/HPA.
- **The honest cost point:** "EKS can't hit $50/month running 24/7 — the control
  plane alone is ~$73. So I treated it like a non-prod environment: fully
  codified in Terraform, `apply` to demo, `destroy` when idle. Real spend was
  demo hours — cents."
- **Security one-liner:** "Workers in private subnets, IRSA for least-privilege
  pod permissions, ALB is the only public entry point."
- **Depth probe answers:** HPA needs metrics-server; Ingress → ALB needs the AWS
  Load Balancer Controller; IRSA maps a K8s service account to an IAM role via
  the OIDC provider.

### Project 3 — CI/CD Pipeline
- **What:** GitHub Actions builds, pushes to ECR, registers a new task def,
  rolling-deploys to ECS, waits for stable.
- **Security headline:** "No stored AWS keys — GitHub assumes an IAM role via
  OIDC, scoped to only the main branch of one repo."
- **Depth probe answers:** commit-SHA image tags for traceability/rollback;
  `iam:PassRole` constrained to `ecs-tasks.amazonaws.com`; deploy fails if tasks
  don't stabilize.

## Cost discipline soundbites (SAs love these)

- "Spot for stateless workloads is ~70% off in both ECS and EKS."
- "Single NAT Gateway in non-prod saves ~$33/month per AZ removed."
- "Ephemeral clusters for dev/test — don't pay for an idle control plane."
- "Everything is `terraform destroy`-able, so idle cost trends to zero."

## Likely follow-up questions + crisp answers

**"When would you NOT use Fargate?"**
> Fine-grained node control, GPU workloads, daemonsets, or when bin-packing many
> small tasks on shared EC2 is cheaper. Then ECS-on-EC2 or EKS with managed
> nodes.

**"How would you make the EKS project production-ready?"**
> Private API endpoint or restricted CIDRs, one NAT per AZ for HA, Karpenter for
> node autoscaling, Savings Plans for the baseline, GitOps (Argo CD/Flux) instead
> of `kubectl apply`, and observability with Container Insights or Prometheus.

**"How do you roll back a bad deploy?"**
> Each deploy is a new task-def revision. Roll back by pointing the service at
> the previous revision — or the pipeline auto-fails because `services-stable`
> never returns.

**"Why Terraform over CloudFormation/CDK?"**
> Multi-cloud familiarity, mature module ecosystem (I used the community VPC/EKS
> modules), and a clean plan/apply/destroy loop. CDK is a fine choice too if the
> team prefers a programming language.

## Don'ts

- Don't claim the EKS project is "under $50/month running 24/7." It isn't — own
  the ephemeral strategy instead. Honesty about cost *is* the strong answer.
- Don't oversell complexity. The apps are intentionally simple so the
  architecture is the star.
