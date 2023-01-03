#!/usr/bin/env bash

set -euo pipefail

SSH_KEYS=$(aws ssm get-parameter --region "us-east-2" \
    --name /clojars/production/ssh_keys --query "Parameter.Value")

IFS=","
read -raSPLIT_KEYS<<< "${SSH_KEYS//\"/}"

echo "ssh_keys:" > /tmp/clojars_vars.yml
for url in "${SPLIT_KEYS[@]}"; do
    echo "  - '$url'" >> /tmp/clojars_vars.yml
done
