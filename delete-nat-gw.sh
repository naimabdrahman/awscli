#!/bin/bash

# Get all NAT gateway IDs
nat_gateway_ids=$(aws ec2 describe-nat-gateways --query 'NatGateways[].NatGatewayId' --output text)

# Check if there are any NAT gateways
if [ -z "$nat_gateway_ids" ]; then
    echo "No NAT gateways found."
else
    # Loop through each NAT gateway ID and delete it
    for nat_gateway_id in $nat_gateway_ids; do
        echo "Deleting NAT gateway with ID: $nat_gateway_id"
        aws ec2 delete-nat-gateway --nat-gateway-id $nat_gateway_id
    done
fi

echo "NAT gateways deletion completed."
