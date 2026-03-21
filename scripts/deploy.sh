#!/usr/bin/env bash
#

set -euo pipefail

usage() { echo "Usage: $0 version" 1>&2; exit 1; }

version=$1

if [ -z "$version" ]; then
  usage
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

host=$("$dir/select-instance.sh")
[ $? -eq 0 ] || exit 1

"$dir/upload-release.sh" $version

ssh "ec2-user@${host}" sudo -u clojars /home/clojars/bin/deploy-clojars
