#!/usr/bin/env bash
#

set -euo pipefail

usage() { echo "Usage: $0 version" 1>&2; exit 1; }

version=$1

if [ -z "$version" ]; then
  usage
fi

bucket="s3://clojars-deployment-artifacts"
artifact="clojars-${version}.zip"
artifact_path="${bucket}/${artifact}"
build_dir=/tmp/clojars-build

# check for release on s3
set +e
aws s3 ls $artifact_path
result=$?
set -e

if [[ $result -ne 0 ]]; then
  echo "==> $artifact_path not found - downloading source, building, and uploading..."
  rm -rf $build_dir
  mkdir -p $build_dir
  cd $build_dir
  wget -q "https://github.com/clojars/clojars-web/archive/${version}.zip" --output-document clojars-archive.zip
  unzip -q clojars-archive.zip
  mv "clojars-web-${version}" clojars-web
  rm clojars-archive.zip
  cd clojars-web
  # Including the production profile is a workaround for https://codeberg.org/leiningen/leiningen/issues/5
  lein with-profile production uberjar
  
  # build zip of jar & scripts
  mv "target/uberjar/clojars-web-${version}-standalone.jar" .
  zip $artifact *.jar scripts/*
  
  # upload to s3
  aws s3 cp $artifact $artifact_path
fi

# upload current-release.txt
echo "==> Setting ${bucket}/current-release.txt to ${version}"
echo $version > /tmp/current-release.txt
aws s3 cp /tmp/current-release.txt "${bucket}"
