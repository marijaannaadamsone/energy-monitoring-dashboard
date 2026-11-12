# Terraform configuration for Energy Monitoring Dashboard

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Existing Bootcamp VPC
data "aws_vpc" "bootcamp" {
  id = "vpc-04b6091923e283784"
}

# Existing Bootcamp Subnets
data "aws_subnet" "public_1a" {
  id = "subnet-09499899162c048f7"
}

data "aws_subnet" "public_1b" {
  id = "subnet-0085786c1374a372c"
}

# Security Group for Energy Monitoring Dashboard
resource "aws_security_group" "dashboard" {
  name        = "energy-dashboard-fargate-sg"
  description = "Security group for Energy Dashboard on ECS Fargate"
  vpc_id      = data.aws_vpc.bootcamp.id

  ingress {
    description = "Public HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "energy-dashboard-fargate-sg"
    Project = "EnergyMonitoringDashboard"
  }
}

# ECS Cluster for Energy Monitoring Dashboard
resource "aws_ecs_cluster" "dashboard" {
  name = "energy-dashboard-cluster"

  tags = {
    Name    = "energy-dashboard-cluster"
    Project = "EnergyMonitoringDashboard"
  }
}

# Existing ECS Task Execution Role
data "aws_iam_role" "ecs_execution" {
  name = "ecsTaskExecutionRole"
}

# CloudWatch Logs for Energy Monitoring Dashboard
resource "aws_cloudwatch_log_group" "dashboard" {
  name              = "/ecs/energy-monitoring-dashboard"
  retention_in_days = 7

  tags = {
    Name    = "energy-dashboard-logs"
    Project = "EnergyMonitoringDashboard"
  }
}

# ECS Task Definition for Energy Monitoring Dashboard
resource "aws_ecs_task_definition" "dashboard" {
  family                   = "energy-monitoring-dashboard"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = data.aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "energy-dashboard"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dashboard.name
          "awslogs-region"        = "eu-west-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name    = "energy-dashboard-task"
    Project = "EnergyMonitoringDashboard"
  }
}

# ECS Fargate Service for Energy Monitoring Dashboard
resource "aws_ecs_service" "dashboard" {
  name            = "energy-dashboard-service"
  cluster         = aws_ecs_cluster.dashboard.id
  task_definition = aws_ecs_task_definition.dashboard.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      data.aws_subnet.public_1a.id,
      data.aws_subnet.public_1b.id
    ]

    security_groups = [
      aws_security_group.dashboard.id
    ]

    assign_public_ip = true
  }

  tags = {
    Name    = "energy-dashboard-service"
    Project = "EnergyMonitoringDashboard"
  }
}
