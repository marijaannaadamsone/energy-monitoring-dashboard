# Terraform variables for Energy Monitoring Dashboard

# Docker image used by ECS Fargate
variable "container_image" {
  description = "Docker image URI for Energy Monitoring Dashboard"
  type        = string
}
