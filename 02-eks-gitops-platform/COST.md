# Cost Breakdown — Orders Platform on Amazon EKS

Region: `us-east-1`. Approximate; verify with the
[AWS Pricing Calculator](https://calculator.aws).

## The honest math

EKS is **not** a "few dollars a month" service the way the serverless projects
are. The control plane alone is a fixed hourly charge, so keeping this under $50
requires **operational** cost control, not just architectural choices.

### If left running 24/7

| Component | Basis | Est. monthly |
|-----------|-------|-------------:|
| EKS control plane | $0.10/hr × ~730 hrs | **~$73** |
| 2× t3.small Spot nodes | ~$0.006/hr each × 730 | **~$9** |
| NAT Gateway (single) | ~$0.045/hr + data | **~$33** |
| ALB (from Ingress) | ~$0.0225/hr + LCU | **~$16** |
| ECR + CloudWatch | low volume | **~$2** |
| **Total (24/7)** | | **~$130+ / month** ❌ |

That busts the $50 budget — mostly the control plane, NAT, and ALB fixed costs.

### The strategy: ephemeral environment ✅

This stack is built to be created and destroyed on demand:

| Usage pattern | Approx cost |
|---------------|------------:|
| 2-hour demo / recording session | **~$0.30** |
| ~10 hours of tinkering in a month | **~$1.50** |
| Left up for a full weekend (48h) | **~$8** |

`terraform apply` → demo or record → `terraform destroy`. You pay only for the
hours the cluster exists. This mirrors how teams run non-production Kubernetes
environments to control spend.

## Cost levers I built in

- **Ephemeral lifecycle** — the single biggest lever. One command up, one down.
- **Spot worker nodes** (`use_spot = true`) — ~70% off compute.
- **`t3.small` nodes** — smallest practical size for a demo workload.
- **Single NAT Gateway** instead of one per AZ — saves ~$33/month.
- **ECR lifecycle policy** — keep only the last 5 images.

## Talking point for interviews

> "EKS costs more than ECS because of the managed control-plane fee. For this
> portfolio I treated the cluster like a non-production environment: fully
> codified in Terraform and destroyed when idle, so actual spend was demo hours
> only. If this were production, I'd justify the control-plane cost with the
> Kubernetes ecosystem benefits — portability, GitOps, operators — and drive
> per-workload cost down with Spot, Karpenter/right-sizing, and Savings Plans."
