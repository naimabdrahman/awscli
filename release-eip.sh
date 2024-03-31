#!/bin/bash

# Find all Elastic IP addresses
elastic_ips=$(aws ec2 describe-addresses --query 'Addresses[*].AllocationId' --output text)

# Loop through each Elastic IP address and release it
for allocation_id in $elastic_ips; do
    echo "Releasing Elastic IP with Allocation ID: $allocation_id"
    aws ec2 release-address --allocation-id $allocation_id
done

echo "All Elastic IP addresses released successfully."
