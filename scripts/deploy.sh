#!/usr/bin/env bash
#

set -euo pipefail

usage() { echo "Usage: $0 host version" 1>&2; exit 1; }

host=$1
version=$2

if [ -z "$host" ] || [ -z "$version" ]; then
  usage
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

"$dir/upload-release.sh" $version

ssh -i $CLOJARS_SSH_KEY_FILE "ec2-user@${host}" sudo -u clojars /home/clojars/bin/deploy-clojars 

