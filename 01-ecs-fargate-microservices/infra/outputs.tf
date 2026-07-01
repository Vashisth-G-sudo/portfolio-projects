output "ecr_repository_url" {
  description = "Push your image here (docker build/tag/push)."
  value       = aws_ecr_repository.app.repository_url
}

output "app_url" {
  description = "Open this in a browser once tasks are healthy."
  value       = "http://${aws_lb.main.dns_name}"
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}
