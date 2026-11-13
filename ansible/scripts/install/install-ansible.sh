
#!/usr/bin/env bash

set -Eeuo pipefail

echo "> Checking if running on Ubuntu..."
if [[ ! -f /etc/os-release ]] || ! grep -q '^ID=ubuntu$' /etc/os-release; then
    echo "> This script is intended to be run on Ubuntu."
    exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
    echo "> Do not run this script as root. Run it as your normal user."
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
COLLECTION_REQUIREMENTS="$ANSIBLE_DIR/requirements.yml"

if [[ ! -f "$COLLECTION_REQUIREMENTS" ]]; then
    echo "> Ansible collection requirements file not found: $COLLECTION_REQUIREMENTS"
    exit 1
fi

echo "> Requesting sudo permissions..."
sudo -v

echo "> Updating apt lists..."
sudo apt update

echo "> Installing dependencies..."
sudo apt install -y \
    ca-certificates \
    curl \
    git \
    jq \
    unzip \
    python3 \
    python3-venv \
    pipx

echo "> Configuring pipx..."
pipx ensurepath
source ~/.bashrc

PIPX_BIN_DIR="$(pipx environment --value PIPX_BIN_DIR)"
export PATH="$PIPX_BIN_DIR:$PATH"

echo "> Installing Ansible..."
if pipx list --json | jq -e '.venvs.ansible' >/dev/null; then
    echo "> Ansible is already installed."
else
    pipx install --include-deps ansible
fi

echo "> Installing AWS Python dependencies..."
pipx inject ansible boto3 botocore

echo "> Installing Ansible collections..."
ansible-galaxy collection install -r "$COLLECTION_REQUIREMENTS"

echo "> Verifying Ansible installation..."
ansible --version

echo "> Verifying AWS Python dependencies..."
pipx runpip ansible show boto3 botocore

echo "> Verifying Ansible collections..."
ansible-galaxy collection list amazon.aws

echo "> Installation completed."
