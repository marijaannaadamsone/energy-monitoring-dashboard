# Terraform outputs for Energy Monitoring Dashboard

# ECS Cluster Name
output "ecs_cluster_name" {
  description = "Name of the Energy Dashboard ECS cluster"
  value       = aws_ecs_cluster.dashboard.name
}

# ECS Service Name
output "ecs_service_name" {
  description = "Name of the Energy Dashboard ECS service"
  value       = aws_ecs_service.dashboard.name
}

# ECS Task Definition ARN
output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.dashboard.arn
}

# Security Group ID
output "security_group_id" {
  description = "Security Group ID for the Dashboard"
  value       = aws_security_group.dashboard.id
}

# AWS Region
output "aws_region" {
  description = "AWS region used by the project"
  value       = "eu-west-1"
}
