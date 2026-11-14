#!/usr/bin/env bash

set -Eeuo pipefail

AWS_REGION="eu-west-1"
AWS_DIR="$HOME/.aws"
AWS_CONFIG="$AWS_DIR/config"
AWS_CREDENTIALS="$AWS_DIR/credentials"

GET_TOKEN_PROFILE="dev-get-token"
MFA_PROFILE="dev-mfa"

echo "> Preparing AWS configuration files..."

mkdir -p "$AWS_DIR"
chmod 700 "$AWS_DIR"

touch "$AWS_CONFIG" "$AWS_CREDENTIALS"
chmod 600 "$AWS_CONFIG" "$AWS_CREDENTIALS"

echo "> Checking source credentials..."

if [[ -z "$(aws configure get aws_access_key_id --profile "$GET_TOKEN_PROFILE" 2>/dev/null || true)" ||
      -z "$(aws configure get aws_secret_access_key --profile "$GET_TOKEN_PROFILE" 2>/dev/null || true)" ]]; then
    echo "> Source credentials are missing. Please enter them."
    aws configure --profile "$GET_TOKEN_PROFILE"
fi

echo "> Checking MFA device..."

if [[ -z "$(aws configure get mfa_serial --profile "$GET_TOKEN_PROFILE" 2>/dev/null || true)" ]]; then
    read -rp "MFA device ARN: " MFA_SERIAL

    if [[ -z "$MFA_SERIAL" ]]; then
        echo "> Error: MFA device ARN is required."
        exit 1
    fi

    aws configure set mfa_serial "$MFA_SERIAL" --profile "$GET_TOKEN_PROFILE"
fi

echo "> Configuring AWS CLI profiles..."

aws configure get region --profile "$GET_TOKEN_PROFILE" >/dev/null 2>&1 ||
    aws configure set region "$AWS_REGION" --profile "$GET_TOKEN_PROFILE"

aws configure get output --profile "$GET_TOKEN_PROFILE" >/dev/null 2>&1 ||
    aws configure set output json --profile "$GET_TOKEN_PROFILE"

aws configure get region --profile "$MFA_PROFILE" >/dev/null 2>&1 ||
    aws configure set region "$AWS_REGION" --profile "$MFA_PROFILE"

aws configure get output --profile "$MFA_PROFILE" >/dev/null 2>&1 ||
    aws configure set output json --profile "$MFA_PROFILE"

echo "> Refreshing MFA credentials..."

aws configure mfa-login \
    --profile "$GET_TOKEN_PROFILE" \
    --update-profile "$MFA_PROFILE"

echo "> Verifying AWS identity..."

if ! aws sts get-caller-identity --profile "$MFA_PROFILE" >/dev/null; then
    echo "> Error: AWS identity verification failed."
    exit 1
fi

echo "> AWS authentication completed successfully."