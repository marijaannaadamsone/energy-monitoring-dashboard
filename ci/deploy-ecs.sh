
#!/usr/bin/env bash
set -euo pipefail

REGION="eu-west-1"
CLUSTER="energy-dashboard-cluster"
SERVICE="energy-dashboard-service"
CONTAINER="energy-dashboard"

IMAGE_URI="${1:?Usage: deploy-ecs.sh IMAGE_URI [plan|apply]}"
MODE="${2:-plan}"

if [[ "$MODE" != "plan" && "$MODE" != "apply" ]]; then
  echo "Mode must be plan or apply"
  exit 1
fi

command -v aws >/dev/null || { echo "AWS CLI is required"; exit 1; }
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

CURRENT_TASK=$(aws ecs describe-services \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --query 'services[0].taskDefinition' \
  --output text)

if [[ -z "$CURRENT_TASK" || "$CURRENT_TASK" == "None" ]]; then
  echo "ECS service or Task Definition not found"
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

aws ecs describe-task-definition \
  --region "$REGION" \
  --task-definition "$CURRENT_TASK" \
  --query taskDefinition \
  --output json > "$TMP_DIR/current.json"

jq -e --arg name "$CONTAINER" \
  '.containerDefinitions | any(.name == $name)' \
  "$TMP_DIR/current.json" >/dev/null || {
    echo "Container not found: $CONTAINER"
    exit 1
  }

jq --arg name "$CONTAINER" --arg image "$IMAGE_URI" '
  {
    family,
    taskRoleArn,
    executionRoleArn,
    networkMode,
    containerDefinitions: (
      .containerDefinitions |
      map(if .name == $name then .image = $image else . end)
    ),
    volumes,
    placementConstraints,
    requiresCompatibilities,
    cpu,
    memory,
    runtimePlatform,
    ephemeralStorage,
    proxyConfiguration,
    pidMode,
    ipcMode
  }
  | with_entries(select(.value != null))
' "$TMP_DIR/current.json" > "$TMP_DIR/new.json"

echo "Current Task Definition: $CURRENT_TASK"
echo "Requested Docker image: $IMAGE_URI"

if [[ "$MODE" == "plan" ]]; then
  echo "PLAN ONLY: no changes made to AWS."
  exit 0
fi

NEW_TASK=$(aws ecs register-task-definition \
  --region "$REGION" \
  --cli-input-json "file://$TMP_DIR/new.json" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$NEW_TASK" \
  --output json >/dev/null

aws ecs wait services-stable \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE"

echo "ECS deployment stabilized: $NEW_TASK"
