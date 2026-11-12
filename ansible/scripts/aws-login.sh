#!/usr/bin/env bash

set -Eeuo pipefail

sudo aws configure mfa-login \
    --profile dev-get-token \
    --update-profile dev-mfa

aws sts get-caller-identity --profile dev-mfa
