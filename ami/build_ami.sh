#!/bin/bash

# Find the latest Amazon Linux 2 AMI
BASE_AMI=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --query 'sort_by(Images,&CreationDate)[-1].ImageId' --region "us-east-2" --output text)

packer build -var source_ami_id="${BASE_AMI}" packer.json
