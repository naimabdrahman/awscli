#!/bin/bash

# Get list of all EC2 instance IDs
instance_ids=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)

# Check if there are any instances running
if [ -z "$instance_ids" ]; then
    echo "No EC2 instances found."
    exit 0
fi

# Loop through each instance and terminate it
for instance_id in $instance_ids; do
    echo "Terminating EC2 instance: $instance_id"
    aws ec2 terminate-instances --instance-ids $instance_id
done

echo "All EC2 instances terminated."

