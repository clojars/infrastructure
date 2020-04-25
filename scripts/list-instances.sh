#!/bin/bash

aws ec2 describe-instances --region us-east-2 \
        --output table \
        --query 'Reservations[*].Instances[*].{id:InstanceId,started:LaunchTime,public_ip:PublicIpAddress,state:State.Name}'
