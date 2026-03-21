#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

instance_ip=$("$SCRIPT_DIR/select-instance.sh")
[ $? -eq 0 ] || exit 1

echo "Connecting to instance at $instance_ip..."
ssh ec2-user@"$instance_ip"
