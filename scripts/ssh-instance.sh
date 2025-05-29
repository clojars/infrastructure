#!/bin/bash

# Function to SSH into an instance
ssh_to_instance() {
    local instance_ip=$1
    echo "Connecting to instance at $instance_ip..."
    ssh ec2-user@"$instance_ip"
}

# Get running instances
instances=$(aws ec2 describe-instances --region us-east-2 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,LaunchTime]' \
    --output text)

# Count the number of running instances
instance_count=$(echo "$instances" | grep -c .)

if [ "$instance_count" -eq 0 ]; then
    echo "No running instances found."
    exit 1
elif [ "$instance_count" -eq 1 ]; then
    # Single instance - connect directly
    instance_ip=$(echo "$instances" | awk '{print $2}')
    ssh_to_instance "$instance_ip"
else
    # Multiple instances - let user choose
    echo "Multiple running instances found:"
    echo
    
    # Display instances with numbers
    i=1
    while IFS=$'\t' read -r instance_id public_ip launch_time; do
        echo "[$i] Instance: $instance_id, IP: $public_ip, Started: $launch_time"
        ((i++))
    done <<< "$instances"
    
    echo
    read -r -p "Select instance number (1-$instance_count): " selection
    
    # Validate selection
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$instance_count" ]; then
        echo "Invalid selection."
        exit 1
    fi
    
    # Get the selected instance IP
    instance_ip=$(echo "$instances" | sed -n "${selection}p" | awk '{print $2}')
    ssh_to_instance "$instance_ip"
fi
