# ShopFront on ECS Fargate

**Live demo:** `http://<your-alb-dns>` (after deploy)

## The Big Picture

I built ShopFront to run a containerized web service on AWS **without managing a
single server**. The application is a small product-catalog API packaged as a
Docker container. Amazon ECS with the Fargate launch type runs that container
for me — I never touch an EC2 instance, patch an OS, or manage a cluster of
nodes. AWS runs the container, I just say "run 1 of these, keep it healthy, and
add more when it gets busy."

Here's how a request flows:

```
You (Browser) → Application Load Balancer → ECS Fargate Task(s) → in-memory catalog
```

Four moving parts in a straight line. The browser hits the load balancer, the
load balancer forwards to a healthy container task, and the task returns JSON.
When traffic rises, ECS launches more tasks automatically; when it drops, it
scales back down.

## What Each Piece Does

### 1. The Container (the application)
A small Python Flask app served by gunicorn, packaged in a slim Docker image.
It exposes `/products`, a `/health` endpoint for load-balancer checks, and a
`/` endpoint that returns the task hostname — handy for *proving* that requests
are being balanced across multiple tasks. It runs as a non-root user inside the
container for defense in depth.

### 2. Amazon ECR (the image registry)
The private registry that stores my Docker image. It scans images for
vulnerabilities on push, and a lifecycle policy keeps only the last 5 images so
storage stays effectively free.

### 3. ECS + Fargate (the runtime)
ECS is the orchestrator; Fargate is the serverless compute that actually runs
the container. I define a **task** (0.25 vCPU, 0.5 GB — the smallest size) and a
**service** that keeps the desired number of tasks running and registered with
the load balancer. There is **no control-plane fee** with ECS, which is the key
reason this project is cheap enough to leave running 24/7.

### 4. Application Load Balancer (the front door)
The ALB receives HTTP requests and forwards them only to healthy tasks. It runs
health checks against `/health` and automatically stops sending traffic to any
task that fails. It spans two Availability Zones, so the app survives an AZ
outage.

### 5. Application Auto Scaling (the elasticity)
A target-tracking policy watches average CPU. Above 60% it adds tasks (up to 4);
when things calm down it scales back to 1. This is the core "elastic containers"
story an SA needs to tell — pay for what you use, absorb spikes automatically.

## How I Kept It Secure

- **Tasks are not exposed to the internet directly.** The task security group
  only accepts traffic on port 8080 **from the ALB's security group** — nothing
  else can reach the containers.
- **Least-privilege IAM.** The task execution role has only the managed policy
  needed to pull from ECR and write logs. Nothing more.
- **Non-root containers.** The image runs as an unprivileged user.
- **Image scanning.** ECR scans every pushed image for known CVEs.
- **Two-AZ resilience.** The ALB and tasks span two Availability Zones.
- **Short log retention** (7 days) limits how long data is kept.

## Why This Is Cost-Effective

Every choice here is aimed at a low, predictable bill:

- **Fargate Spot** for the tasks — up to ~70% cheaper than on-demand Fargate.
- **Smallest task size** (0.25 vCPU / 0.5 GB).
- **No NAT Gateway.** Tasks run in public subnets with a public IP so they can
  pull images directly — this deliberately avoids the ~$32/month NAT charge. The
  tasks stay protected because only the ALB can reach them.
- **No always-on EC2, no data tier.** The catalog is in-memory for the demo.

Full breakdown in [COST.md](./COST.md) — roughly **$26/month** running 24/7, and
you can `terraform destroy` to drop it to near-zero when you're not demoing.

## Infrastructure as Code

The entire stack — VPC, subnets, ALB, ECR, ECS cluster, task definition,
service, IAM roles, and autoscaling — is defined in Terraform under `infra/`.
One command builds it, one command tears it down. Nothing is clicked together
in the console.

## Deploy it

```bash
cd infra

# 1. Create ECR + networking first (image doesn't exist yet)
terraform init
terraform apply -target=aws_ecr_repository.app

# 2. Build and push the image
REPO=$(terraform output -raw ecr_repository_url)
REGION=us-east-1
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin ${REPO%/*}
docker build -t shopfront ../app
docker tag shopfront:latest $REPO:latest
docker push $REPO:latest

# 3. Stand up the rest
terraform apply

# 4. Open the app
terraform output app_url

# 5. Tear it all down when done
terraform destroy
```

## What this demonstrates to a reviewer

Containerization, Amazon ECS/Fargate, ECR, ALB with health checks, target-group
routing, awsvpc networking, security-group chaining, least-privilege IAM,
target-tracking autoscaling, multi-AZ design, and cost-aware architecture — all
codified in Terraform.

Built with the help of [Kiro](https://kiro.dev), Amazon's AI-powered IDE.
