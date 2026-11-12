
#!/usr/bin/env bash

set -Eeuo pipefail

if [[ ! -f /etc/os-release ]] || ! grep -q '^ID=ubuntu$' /etc/os-release; then
    echo "> This script is intended for Ubuntu."
    exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
    echo "> Run this script as your normal user, not as root."
    exit 1
fi

echo "> Requesting sudo permissions..."
sudo -v

echo "> Installing AWS CLI and dependencies..."
sudo apt update
sudo apt install -y awscli

echo "> Installing Session Manager plugin..."

curl -fsSL \
    https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb \
    -o "session-manager-plugin.deb"

sudo apt install -y "./session-manager-plugin.deb"

echo
echo "> AWS tools installation completed."
aws --version
session-manager-plugin --version
