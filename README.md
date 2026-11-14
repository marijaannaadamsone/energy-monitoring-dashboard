# Energy Monitoring Dashboard

Static energy-consumption dashboard and AWS infrastructure configuration.
The current dashboard is a browser-rendered demo: it displays a fixed 24-hour set of hourly readings, calculates estimated cost at EUR 0.22/kWh, highlights readings above 45 kWh, and renders the hourly values as a bar chart.

## What is included

- `index.html` contains the dashboard UI and its sample telemetry.
- `Dockerfile` packages the dashboard as an Nginx container serving port 80.
- `terraform/` provisions the AWS hosting resources:
  - an ECS Fargate cluster and service with one dashboard task;
  - a public security group allowing HTTP on port 80;
  - a Concourse CI EC2 instance and its security group;
  - an S3 bucket used by the Ansible SSM connection.
- `ansible/` connects to the Concourse EC2 instance through AWS Systems Manager, installs Docker, and deploys Concourse CI with Docker Compose.

The Terraform configuration uses the existing bootcamp VPC and public
subnets in `eu-west-1`. The dashboard ECS task expects a container image URI
through the required `container_image` Terraform variable.

## Terraform

Terraform state is stored in the configured encrypted S3 backend. Initialize
Terraform and provide the dashboard image:

```bash
cd terraform
terraform init
terraform plan -var='container_image=REGISTRY_IMAGE_URI'
terraform apply -var='container_image=REGISTRY_IMAGE_URI'
```

The configuration outputs the ECS cluster name, service name, task definition ARN, dashboard security group ID, and AWS region. 

## Ansible and Concourse

The Ansible workflow manages the Concourse CI host. It uses the `amazon.aws.aws_ssm` connection plugin and
the `dev-mfa` AWS profile. The inventory currently contains 1 `concourse-ci` EC2 instance.

See [`ansible/ansible-readme.md`](ansible/ansible-readme.md) for prerequisites,
AWS authentication, collection installation, inventory configuration, and the
full playbook workflow:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook ansible/playbooks/test-connection.yml
ansible-playbook ansible/playbooks/install-docker.yml
ansible-playbook ansible/playbooks/deploy-concourse-ci.yml \
  -e concourse_external_url=https://EC2_PUBLIC_IP
```

The deployment playbook runs Concourse web, worker, and PostgreSQL services with Docker Compose, waits for the local API health check, and saves the generated admin password at `~/.config/concourse/admin-password` on the Ansible controller.
