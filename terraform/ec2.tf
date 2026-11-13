# Create a Security Group for the Concourse CI server
resource "aws_security_group" "concourse" {
  name        = "energy-dashboard-concourse-sg"
  description = "Security group for Concourse CI EC2"
  vpc_id      = data.aws_vpc.bootcamp.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "energy-dashboard-concourse-sg"
  }
}

# Create an EC2 instance using the Bootcamp AMI
resource "aws_instance" "concourse" {
  ami                    = "ami-0a3ef1de594e520c9"
  instance_type          = "t3.medium"
  subnet_id              = data.aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.concourse.id]
  iam_instance_profile   = "Bootcamp-Instance-Profile"

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name    = "energy-dashboard-concourse"
    Project = "EnergyMonitoringDashboard"
  }
}
