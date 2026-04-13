#!/bin/bash
set -euo pipefail

ASG_NAME=prod-asg

REFRESH_ID=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name="$ASG_NAME" \
  --query 'InstanceRefreshId' \
  --output text)

echo "Started instance refresh: $REFRESH_ID"

while true; do
  read -r STATUS PERCENT < <(aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name="$ASG_NAME" \
    --instance-refresh-ids "$REFRESH_ID" \
    --query 'InstanceRefreshes[0].[Status,PercentageComplete]' \
    --output text)

  if [ "$PERCENT" = "None" ]; then
    echo "Status: $STATUS"
  else
    echo "Status: $STATUS (${PERCENT}% complete)"
  fi

  case "$STATUS" in
    Successful)
      echo "Instance refresh completed successfully."
      exit 0
      ;;
    Failed|Cancelled|RollbackFailed|RollbackSuccessful)
      echo "Instance refresh ended with status: $STATUS" >&2
      exit 1
      ;;
  esac

  sleep 30
done
