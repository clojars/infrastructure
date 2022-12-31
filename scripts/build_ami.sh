#!/bin/bash

set -euo pipefail

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "${dir}/../ami"

# Find the latest Amazon Linux 2 AMI
BASE_AMI=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-arm64-gp2" --query 'sort_by(Images,&CreationDate)[-1].ImageId' --region "us-east-2" --output text)

packer build -var source_ami_id="${BASE_AMI}" packer.json

# Find the newly created AMI
NEW_AMI=$(aws ec2 describe-images --owners self --filters "Name=name,Values=clojars-server*" --query 'sort_by(Images,&CreationDate)[-1].ImageId' --region "us-east-2" --output text)

# Set ssm parameter with new amidi
aws ssm put-parameter --name "/clojars/production/ami_id" --value $NEW_AMI --type String --overwrite

echo "New AMI (${NEW_AMI}) stored in '/clojars/production/ami_id'. Apply terraform and run ./scripts/cycle-instance.sh to use this new AMI."
