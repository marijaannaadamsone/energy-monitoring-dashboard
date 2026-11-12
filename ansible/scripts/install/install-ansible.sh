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

echo "> Requesting sudo permissions..."
sudo -v

echo "> Updating apt lists..."
sudo apt update

echo "> Installing deps..."
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

echo "> Installing Ansible..."
if pipx list --json | jq -e '.venvs.ansible' >/dev/null; then
    echo "> Ansible is already installed."
else
    pipx install --include-deps ansible
fi

echo "> Installation completed."
echo

ansible --version
ansible-galaxy collection list amazon.aws
