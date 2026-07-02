# Orders Platform on Amazon EKS

**An ephemeral, cost-managed Kubernetes environment** - stand it up to demo or
record a walkthrough, then tear it down so you only pay for the hours you use.

## The Big Picture

I built this to run a containerized service on **Amazon EKS** - AWS's managed
Kubernetes. Where the ECS project shows the "containers with minimum overhead"
path, this one shows the "full Kubernetes platform" path: the same kind of
workload, but deployed the way a Kubernetes-standardized organization would run
it, with Deployments, Services, an Ingress-provisioned load balancer, and a
Horizontal Pod Autoscaler.

Here's how a request flows:

```
You (Browser) → ALB (created by the Ingress) → Kubernetes Service → Pod(s) on EKS worker nodes
```

AWS manages the Kubernetes control plane. I manage the workloads declaratively
with YAML manifests. Terraform builds the cluster; `kubectl apply` deploys the
app.

## What Each Piece Does

### 1. The Container (the application)
A small Python Flask "Orders API" packaged as a Docker image in ECR. It reports
back which **pod** and **node** served each request (via the Kubernetes Downward
API), which makes load balancing and autoscaling visible during a demo.

### 2. Amazon EKS (the control plane)
The managed Kubernetes control plane. AWS runs and scales the API server and
etcd across multiple AZs. This is what makes the cluster "just work" - but it's
also the ~$73/month line item, which is why I run this environment ephemerally.

### 3. Managed Node Group (the workers)
A managed group of `t3.small` **Spot** instances (1-3 nodes) where pods actually
run. Managed node groups handle provisioning, draining, and rolling updates for
me. Spot capacity cuts the compute bill by ~70%.

### 4. Deployment + Service (the workload)
- **Deployment** runs 2 replicas of the app with CPU/memory requests+limits and
  liveness/readiness probes, so Kubernetes self-heals and only routes traffic to
  ready pods.
- **Service** (ClusterIP) gives the pods a stable internal address.

### 5. AWS Load Balancer Controller + Ingress (the front door)
The Ingress manifest is annotated so the AWS Load Balancer Controller
automatically provisions an internet-facing ALB and points it at the pods. This
is the idiomatic "Kubernetes-native" way to expose a service on EKS.

### 6. Horizontal Pod Autoscaler (the elasticity)
The HPA watches average pod CPU and scales replicas between 2 and 6. Combined
with the node group's scaling, the platform grows and shrinks with load - the
Kubernetes equivalent of the ECS autoscaling story.

### 7. IRSA (least-privilege for pods)
IAM Roles for Service Accounts is enabled so workloads (like the Load Balancer
Controller) get **only** the AWS permissions they need, scoped to a specific
Kubernetes service account - not broad node-level permissions.

## How I Kept It Secure

- **Workers in private subnets.** Nodes have no public IPs; outbound traffic
  goes through a NAT Gateway. Only the ALB is internet-facing.
- **IRSA / least-privilege.** Pods assume narrowly scoped IAM roles instead of
  inheriting node permissions.
- **Health probes** ensure traffic only reaches healthy pods.
- **Resource limits** prevent a single pod from starving a node.
- **ECR image scanning** on push.
- **Multi-AZ** control plane (managed by AWS) and 2-AZ node placement.

## Why This Is Cost-Effective

EKS is inherently more expensive than ECS because of the control-plane fee, so
the cost strategy here is **operational, not just architectural** - exactly the
FinOps thinking expected of a Solutions Architect:

- **Ephemeral by design.** One command builds the cluster, one destroys it.
  Real spend = demo hours only. Left running 24/7 it's ~$80/month; run for a
  2-hour demo it's roughly **$0.30**.
- **Spot worker nodes** - ~70% cheaper than on-demand.
- **`t3.small` nodes** and a **single NAT Gateway** (not one per AZ).
- **ECR lifecycle policy** keeps image storage near-zero.

Full breakdown in [COST.md](./COST.md).

## Deploy it

```bash
cd infra
terraform init
terraform apply                     # ~15 min to build the cluster

# Point kubectl at the cluster
$(terraform output -raw configure_kubectl)

# Build + push the image
REPO=$(terraform output -raw ecr_repository_url)
REGION=us-east-1
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin ${REPO%/*}
docker build -t orders-api ../app
docker tag orders-api:latest $REPO:latest
docker push $REPO:latest

# Install metrics-server (needed for the HPA) and the AWS Load Balancer Controller
# - see docs links in COST.md / below.

# Deploy the workload (edit k8s/deployment.yaml image to $REPO:latest first)
kubectl apply -f ../k8s/namespace.yaml
kubectl apply -f ../k8s/

# Find the ALB URL the Ingress created
kubectl get ingress -n orders

# IMPORTANT: tear it down to stop the control-plane charge
terraform destroy
```

### Add-ons you'll install once

- **metrics-server** (for the HPA):
  `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
- **AWS Load Balancer Controller** (for the Ingress → ALB): install via Helm
  following the [official guide](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html).
  IRSA is already enabled in the Terraform to support it.

## What this demonstrates to a reviewer

Amazon EKS, Kubernetes fundamentals (Deployments, Services, Ingress, probes,
resource management), the Horizontal Pod Autoscaler, the AWS Load Balancer
Controller, IRSA least-privilege, private-subnet worker design, Spot cost
optimization, Terraform with community modules, and - critically - an
**ephemeral environment discipline** to keep a pricey service affordable.

Built with the help of [Kiro](https://kiro.dev), Amazon's AI-powered IDE.
