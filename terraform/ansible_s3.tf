# Create a dedicated private S3 bucket for Ansible SSM
resource "aws_s3_bucket" "ansible_ssm" {
  bucket = "energy-dashboard-ansible-ssm-597765856364"

  tags = {
    Name    = "energy-dashboard-ansible-ssm"
    Project = "EnergyMonitoringDashboard"
  }
}
