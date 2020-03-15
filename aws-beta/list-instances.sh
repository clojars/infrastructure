#!/bin/bash

dev-aws aws ec2 describe-instances --region us-east-2 \
        --output table \
        --query 'Reservations[*].Instances[*].{id:InstanceId,started:LaunchTime,ip:PublicIpAddress,state:State.Name}'
