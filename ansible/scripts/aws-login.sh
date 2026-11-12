#!/usr/bin/env bash

set -Eeuo pipefail

AWS_REGION="eu-west-1"
AWS_DIR="$HOME/.aws"
AWS_CONFIG="$AWS_DIR/config"
AWS_CREDENTIALS="$AWS_DIR/credentials"

echo "> Preparing AWS configuration files..."

mkdir -p "$AWS_DIR"
sudo chmod -R 700 "$AWS_DIR"

for FILE in "$AWS_CONFIG" "$AWS_CREDENTIALS"; do
    if [[ ! -e "$FILE" ]]; then
        touch "$FILE"
    fi

    if [[ ! -O "$FILE" ]]; then
        echo "> Fixing ownership of $FILE..."
        sudo chown "$(id -u):$(id -g)" "$FILE"
    fi

    sudo chmod 600 "$FILE"
done

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