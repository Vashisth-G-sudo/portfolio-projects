# CI/CD Pipeline — GitHub Actions → Amazon ECS

Automated, keyless deployments for the [ShopFront ECS app](../01-ecs-fargate-microservices/).
Push to `main` → build image → push to ECR → rolling deploy to ECS, with zero
long-lived AWS credentials stored anywhere.

## The Big Picture

I wanted every code change to ship to production automatically and safely. This
pipeline does that in one workflow: when I push to `main`, GitHub Actions builds
a fresh Docker image, pushes it to ECR, registers a new ECS task definition
pointing at that image, and triggers a **rolling update** — old tasks drain only
after new ones pass their health checks.

Here's how a change flows:

```
git push → GitHub Actions → (OIDC) assume AWS role → build+push to ECR
        → register new task def → ECS rolling update → wait for stable
```

## What Each Piece Does

### 1. GitHub Actions (the automation)
The `deploy.yml` workflow runs on every push to `main` that touches the app. It
can also be triggered manually from the Actions tab.

### 2. OIDC federation (the keyless auth)
Instead of storing an AWS access key as a GitHub secret, GitHub exchanges its
signed workflow token for **short-lived** AWS credentials by assuming an IAM
role. The trust policy only allows the `main` branch of one specific repo to
assume it. This is the modern, recommended way to connect CI to AWS — nothing
long-lived to leak or rotate.

### 3. ECR (the image store)
The built image is tagged with the Git commit SHA (immutable, traceable) and
also `latest` (convenient). Reusing the same repo from project 01.

### 4. Task definition registration (the version bump)
The workflow pulls the current task definition, swaps in the new image, strips
the read-only fields, and registers a new revision. Each deploy is a distinct,
rollback-able task-def revision.

### 5. ECS rolling update (the safe deploy)
`update-service` points the service at the new revision; ECS launches new tasks,
waits for them to pass ALB health checks, then drains the old ones. The workflow
blocks on `ecs wait services-stable`, so a failed deploy fails the pipeline.

## How I Kept It Secure

- **No stored AWS keys.** OIDC issues short-lived credentials per run.
- **Scoped trust.** Only `main` of the named repo can assume the role
  (`token.actions.githubusercontent.com:sub` condition).
- **Least-privilege IAM.** The deploy role can push to *this* ECR repo and
  update *this* ECS service — nothing else. `iam:PassRole` is constrained to
  `ecs-tasks.amazonaws.com`.
- **Immutable image tags** (commit SHA) for traceability and clean rollbacks.

## Why This Is Cost-Effective

- **GitHub Actions** is free for public repos and has a generous free tier for
  private ones.
- **No extra AWS infrastructure** — it reuses the ECR repo and ECS service from
  project 01. The pipeline itself costs nothing to keep around.

## Set it up

```bash
# 1. Create the OIDC provider + deploy role
cd infra
terraform init
terraform apply -var="github_repo=<your-gh-username>/portfolio-projects"

# 2. Copy the role ARN into a GitHub repo secret named AWS_DEPLOY_ROLE_ARN
terraform output deploy_role_arn
#   GitHub → Settings → Secrets and variables → Actions → New repository secret

# 3. Push a change to the app on main and watch the Actions tab
```

> The workflow lives at [`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml)
> in the **repository root** (that's the only place GitHub executes workflows
> from). Its `paths` filter watches `01-ecs-fargate-microservices/app/**`.

## What this demonstrates to a reviewer

CI/CD design, GitHub Actions, OIDC keyless federation to AWS, least-privilege
deploy roles, immutable image tagging, ECS task-definition versioning, safe
rolling deployments with health-gated cutover, and rollback readiness — the
DevOps half of a Solutions Architect's toolkit.

Built with the help of [Kiro](https://kiro.dev), Amazon's AI-powered IDE.
