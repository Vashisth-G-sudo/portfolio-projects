# Deployed Resources - ShopFront on ECS Fargate

Deployed to AWS account `471112712607`, region `us-east-1` on 2026-07-01.
All resources tagged `auto-delete = no`, `Project = shopfront-ecs`,
`ManagedBy = terraform`, `Environment = demo`.

**Live app (HTTPS, phone-friendly):** https://d1wfp69cotudi8.cloudfront.net
**Live app (direct ALB, HTTP):** http://shopfront-2120594299.us-east-1.elb.amazonaws.com

## Resource inventory (with ARNs)

| Type | Name | ARN / ID |
|------|------|----------|
| VPC | main | `arn:aws:ec2:us-east-1:471112712607:vpc/vpc-024d8bfb8ca3f52c9` |
| Subnet | public[0] | `arn:aws:ec2:us-east-1:471112712607:subnet/subnet-04ba47585bed8c34d` |
| Subnet | public[1] | `arn:aws:ec2:us-east-1:471112712607:subnet/subnet-0c11a199e94a5780f` |
| Internet Gateway | main | `arn:aws:ec2:us-east-1:471112712607:internet-gateway/igw-02ff6a435c6ec606e` |
| Route Table | public | `arn:aws:ec2:us-east-1:471112712607:route-table/rtb-010273448b6c59e1b` |
| Route Table Assoc | public[0] | `rtbassoc-01338bee6e2148939` |
| Route Table Assoc | public[1] | `rtbassoc-0dd298a3041e6aca4` |
| Security Group | alb | `arn:aws:ec2:us-east-1:471112712607:security-group/sg-09f67962a93efca7a` |
| Security Group | task | `arn:aws:ec2:us-east-1:471112712607:security-group/sg-0d6f2009fa02cdd58` |
| ALB | main | `arn:aws:elasticloadbalancing:us-east-1:471112712607:loadbalancer/app/shopfront/39e2214827205f67` |
| ALB Listener | http | `arn:aws:elasticloadbalancing:us-east-1:471112712607:listener/app/shopfront/39e2214827205f67/3a335d4995fddb69` |
| ALB Target Group | app | `arn:aws:elasticloadbalancing:us-east-1:471112712607:targetgroup/shopfront/253b147faac4ea12` |
| ECR Repository | app | `arn:aws:ecr:us-east-1:471112712607:repository/shopfront` |
| ECR Lifecycle Policy | app | (attached to repo `shopfront`) |
| ECS Cluster | main | `arn:aws:ecs:us-east-1:471112712607:cluster/shopfront` |
| ECS Capacity Providers | main | (FARGATE, FARGATE_SPOT on cluster `shopfront`) |
| ECS Task Definition | app | `arn:aws:ecs:us-east-1:471112712607:task-definition/shopfront:1` |
| ECS Service | app | `arn:aws:ecs:us-east-1:471112712607:service/shopfront/shopfront` |
| IAM Role | execution | `arn:aws:iam::471112712607:role/shopfront-exec-20260701225406727500000001` |
| IAM Role Policy Attachment | execution | (AmazonECSTaskExecutionRolePolicy) |
| CloudWatch Log Group | app | `arn:aws:logs:us-east-1:471112712607:log-group:/ecs/shopfront` |
| App Auto Scaling Target | app | `arn:aws:application-autoscaling:us-east-1:471112712607:scalable-target/0ec57701b9de9cafb12f3843eaa335a5` |
| App Auto Scaling Policy | cpu | `arn:aws:autoscaling:us-east-1:471112712607:scalingPolicy:.../shopfront-cpu-scaling` |
| CloudFront Distribution | app | `arn:aws:cloudfront::471112712607:distribution/E20MI37DCKPIBD` (domain `d1wfp69cotudi8.cloudfront.net`) |
| DynamoDB Table | products | `arn:aws:dynamodb:us-east-1:471112712607:table/shopfront-products` |
| IAM Task Role | task | `arn:aws:iam::471112712607:role/shopfront-task-...` |
| IAM Task Role Policy | task_dynamodb | (inline `shopfront-dynamodb` on the task role) |

**Total: 27 created resources.** The app is now dynamic - products are stored in DynamoDB with full create/read/update/delete.

## Tear down

```bash
cd infra
terraform destroy
```

This removes every resource above and stops all charges.
