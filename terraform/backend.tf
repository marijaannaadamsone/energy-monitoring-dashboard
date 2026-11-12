terraform {
  backend "s3" {
    bucket       = "energy-dashboard-tfstate-597765856364"
    key          = "energy-monitoring-dashboard/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
