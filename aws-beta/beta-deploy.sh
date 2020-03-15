#!/usr/bin/env bash
#

set -euo pipefail

usage() { echo "Usage: $0 host version" 1>&2; exit 1; }

host=$1
version=$2

if [ -z "$host" ] || [ -z "$version" ]; then
  usage
fi

echo "Ensuring artifact index exists..."
ssh "$host" sudo -u clojars /home/clojars/bin/ensure-index

echo "Building and deploying Clojars $version..."
ssh "$host" sudo -u clojars /home/clojars/bin/deploy-clojars "$version"


