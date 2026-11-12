
#!/usr/bin/env bash

set -Eeuo pipefail

AWS_REGION="eu-west-1"

if [[ ! -f /etc/os-release ]] || ! grep -q '^ID=ubuntu$' /etc/os-release; then
    echo "This script is intended for Ubuntu."
    exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
    echo "Run this script as your normal user, not as root."
    exit 1
fi

echo "Requesting sudo permissions..."
sudo -v

echo "Installing AWS CLI and dependencies..."
sudo apt update
sudo apt install -y awscli curl ca-certificates jq python3

echo "Installing Session Manager plugin..."

curl -fsSL \
    https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb \
    -o "session-manager-plugin.deb"

sudo apt install -y "session-manager-plugin.deb"

echo "Configuring AWS CLI profiles..."

for PROFILE in dev-get-token dev-mfa; do
    aws configure set region "$AWS_REGION" --profile "$PROFILE"
    aws configure set output json --profile "$PROFILE"
done

echo
echo "AWS tools installation completed."
aws --version
session-manager-plugin --version
echo
echo "Configured profiles: dev-get-token, dev-mfa"
