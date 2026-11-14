# Ansible configuration

This directory contains the Ansible configuration used to connect to the
Concourse EC2 instance through AWS Systems Manager (SSM) and install Docker.

## Directory layout

```text
ansible/
├── requirements.yml
├── inventory/
│   └── hosts.ini
├── playbooks/
│   ├── deploy-concourse-ci.yml
│   ├── install-docker.yml
│   └── test-connection.yml
├── templates/
│   └── concourse.env.j2
├── docker/
│   └── concourse/
│       ├── compose.yml
│       └── .env.example
└── scripts/
    ├── aws-login.sh
    └── install/
        ├── install-ansible.sh
        └── install-aws-tools.sh
```

## Prerequisites

The scripts in this directory target Ubuntu and Bash. The workstation needs:

- AWS CLI
- AWS Session Manager plugin
- Ansible
- The `amazon.aws` Ansible collection
- An AWS profile named `dev-get-token` that can be used for MFA
- Access to the configured AWS account, region, SSM instance, and S3 bucket

The remote EC2 instance must be managed by AWS Systems Manager and have Python
available at `/usr/bin/python3`. The local AWS identity must also be
authorized to start an SSM session and use the configured S3 bucket for the
Ansible SSM connection plugin.

## Configuration

### `ansible.cfg`

The configuration:

- Uses `ansible/inventory/hosts.ini` as the default inventory.
- Disables SSH host-key checking because this setup uses SSM rather than a
  conventional SSH connection.
- Disables retry files.
- Automatically discovers the remote Python interpreter without displaying
  discovery warnings.
- Disables SSH pipelining.

The configuration is stored at the repository root so Ansible discovers it
when commands are run from the repo root. The inventory path is therefore
`ansible/inventory/hosts.ini`.

### `inventory/hosts.ini`

The inventory defines one host:

```text
concourse-ci ansible_host=i-09fdab90632240958
```

The host belongs to the `concourse` group. Group variables configure the
`amazon.aws.aws_ssm` connection:

| Variable | Purpose |
| --- | --- |
| `ansible_connection` | Uses the AWS SSM connection plugin. |
| `ansible_aws_ssm_region` | AWS region used for the SSM session (`eu-west-1`). |
| `ansible_aws_ssm_profile` | AWS CLI profile used by Ansible (`dev-mfa`). |
| `ansible_aws_ssm_bucket_name` | S3 bucket used by the SSM connection plugin. |
| `ansible_python_interpreter` | Remote Python executable (`/usr/bin/python3`). |


## Installation and authentication scripts

### `scripts/install/install-ansible.sh`

This script:

1. Verifies that the operating system is Ubuntu.
2. Requests sudo access.
3. Installs the system packages required by the setup.
4. Configures `pipx`.
5. Installs Ansible with its dependencies unless Ansible is already installed.
6. Prints the installed Ansible version and available `amazon.aws` collections.

Start a new shell, or otherwise reload the shell path, after `pipx ensurepath`
if the `ansible` command is not immediately available.

### `scripts/install/install-aws-tools.sh`

This script installs:

- AWS CLI from the Ubuntu package repository
- AWS Session Manager plugin from the official AWS download URL

It prints both tool versions after installation.

### `scripts/aws-login.sh`

This script prepares `~/.aws`, configures the `dev-get-token` and `dev-mfa`
profiles for `eu-west-1` with JSON output, and runs:

```bash
aws configure mfa-login --profile dev-get-token --update-profile dev-mfa
```

It then verifies the resulting identity with
`aws sts get-caller-identity --profile dev-mfa`.


## Playbooks

### `playbooks/test-connection.yml`

This is the connectivity smoke test. It targets the `concourse` group without
gathering facts, runs `whoami` and reads `/etc/os-release` through the remote
shell, then displays the returned lines.

Run it before making system changes:

```bash
ansible-playbook ansible/playbooks/test-connection.yml
```

### `playbooks/install-docker.yml`

This playbook targets the `concourse` group with privilege escalation. It:

1. Refreshes the apt package cache and safely upgrades installed packages.
2. Installs `ca-certificates` and `curl`.
3. Creates `/etc/apt/keyrings`.
4. Downloads Docker's Ubuntu GPG key.
5. Configures Docker's stable APT repository using the remote Ubuntu release.
6. Installs Docker Engine, the Docker CLI, `containerd`, Buildx, and Compose.
7. Enables and starts the Docker service.
8. Checks and displays the installed Docker and Docker Compose versions.

Run it after the connection test:

```bash
ansible-playbook ansible/playbooks/install-docker.yml
```

The playbook is designed to be repeatable: package installation and service management use Ansible state declarations. 
It performs a safe apt upgrade during host provisioning. Concourse deployment playbook does not upgrade the operating system on every application deployment.

### `playbooks/deploy-concourse-ci.yml`

This playbook deploys Concourse CI on the Docker host. It:

1. Validates the required `concourse_external_url` variable.
2. Creates the Concourse directories under `/opt/concourse`.
3. Generates the Concourse RSA keys and PostgreSQL and admin passwords when
   they do not exist.
4. Copies `docker/concourse/compose.yml` and populates
   `templates/concourse.env.j2`.
5. Starts the Docker Compose services.
6. Waits for the Concourse API to respond before displaying the deployment
   URL and the path to the generated admin password.

Run it after Docker has been installed. The URL must use the `https://` scheme,
for example:

```bash
ansible-playbook ansible/playbooks/deploy-concourse-ci.yml -e concourse_external_url=https://EC2_PUBLIC_IP
```

The playbook creates a self-signed certificate for the hostname or IP address
in the URL and stores it with the private key under `/opt/concourse/tls/`.
The generated secrets are stored on the remote host in `/opt/concourse/secrets/` with restrictive permissions.

## Concourse deployment files

### `docker/concourse/compose.yml`

This Docker Compose configuration defines the Concourse web, worker, and
PostgreSQL services. It:

- uses Concourse `8.3.1` and PostgreSQL `18` images;
- exposes the HTTPS web service on port `443`;
- runs the worker in privileged mode with containerd;
- saves PostgreSQL and worker state in named volumes;
- reads runtime settings from the rendered `/opt/concourse/.env` file;
- restarts services unless they are explicitly stopped.

The web service listens for HTTPS on port `443`, using the self-signed certificate generated by the deployment playbook and mounted from `/opt/concourse/tls/`.

### `templates/concourse.env.j2`

This Ansible template supplies the Compose environment values for the external
URL, PostgreSQL connection, and local Concourse user. The deployment playbook renders it on the remote host with generated passwords.
Generated passwords are not exposed in task output.

### `docker/concourse/.env.example`

Environment variables expected by the compose configuration with placeholders.

## Recommended workflow

From the repository root:

```bash
bash ansible/scripts/install/install-aws-tools.sh
bash ansible/scripts/install/install-ansible.sh
bash ansible/scripts/aws-login.sh
```

Install collection requirements:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

Then validate access and apply the configuration:

```bash
ansible-inventory --graph
ansible-playbook ansible/playbooks/test-connection.yml
ansible-playbook ansible/playbooks/install-docker.yml
ansible-playbook ansible/playbooks/deploy-concourse-ci.yml \
  -e concourse_external_url=https://EC2_PUBLIC_IP
```
