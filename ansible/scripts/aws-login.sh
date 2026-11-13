#!/usr/bin/env bash

set -Eeuo pipefail

AWS_REGION="eu-west-1"
AWS_DIR="$HOME/.aws"
AWS_CONFIG="$AWS_DIR/config"
AWS_CREDENTIALS="$AWS_DIR/credentials"

echo "> Preparing AWS configuration files..."

sudo mkdir -p "$AWS_DIR"
sudo chown -R "$(id -u):$(id -g)" "$AWS_DIR"

chmod 700 "$AWS_DIR"

touch "$AWS_CONFIG" "$AWS_CREDENTIALS"
chmod 600 "$AWS_CONFIG" "$AWS_CREDENTIALS"

echo "> Configuring AWS CLI profiles..."

for PROFILE in dev-get-token dev-mfa; do
    aws configure set region "$AWS_REGION" --profile "$PROFILE"
    aws configure set output json --profile "$PROFILE"
done

echo "> AWS CLI profiles configured."

echo "> Performing MFA login..."

aws configure mfa-login \
    --profile dev-get-token \
    --update-profile dev-mfa

echo "> Verifying AWS identity..."

aws sts get-caller-identity --profile dev-mfa

echo "> AWS authentication completed successfully."
