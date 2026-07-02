# Cost Breakdown - ShopFront on ECS Fargate

Region: `us-east-1`. Prices are approximate and for illustration; check the
[AWS Pricing Calculator](https://calculator.aws) for current rates.

## Running 24/7 (baseline: 1 task)

| Component | Basis | Est. monthly |
|-----------|-------|-------------:|
| Application Load Balancer | ~$0.0225/hr + LCU | **~$16.20** |
| Fargate Spot task (0.25 vCPU, 0.5 GB) | ~730 hrs, Spot pricing | **~$3.50** |
| ECR storage | < 0.5 GB, last-5 lifecycle | **~$0.05** |
| CloudWatch logs + Container Insights | 7-day retention, low volume | **~$3-5** |
| Data transfer | light demo traffic | **~$1** |
| **Total** | | **~$24-26 / month** |

> ECS itself has **no control-plane charge** - you only pay for the Fargate
> compute and the supporting resources. This is the main reason this project
> comfortably fits the $50/month budget with room to spare.

## Cost levers I built in

- **Fargate Spot** (`use_fargate_spot = true`) - ~70% off vs on-demand Fargate.
- **No NAT Gateway** - saves ~$32/month by running tasks in public subnets
  behind an ALB-only security group.
- **Smallest task size** - 0.25 vCPU / 0.5 GB.
- **7-day log retention** and **ECR lifecycle policy** keep storage near-zero.
- **`terraform destroy`** drops everything to ~$0 when not demoing.

## The biggest line item

The ALB (~$16/month fixed) is the largest cost. For an even cheaper demo you
could replace the ALB with a single task behind a public IP, but the ALB is
worth keeping because health checks, multi-AZ, and autoscaling are exactly the
skills this project is meant to show.
