#!/bin/bash

# Get list of all VPC IDs
vpc_ids=$(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text)

# Check if there are any VPCs
if [ -z "$vpc_ids" ]; then
    echo "No VPCs found."
    exit 0
fi

# Loop through each VPC and delete it
for vpc_id in $vpc_ids; do
    echo "Deleting VPC: $vpc_id"
    
    # Delete associated internet gateways
    igw_ids=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$vpc_id --query 'InternetGateways[*].InternetGatewayId' --output text)
    for igw_id in $igw_ids; do
        aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
        aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
    done

    # Delete associated route tables
    rtb_ids=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc_id --query 'RouteTables[*].RouteTableId' --output text)
    for rtb_id in $rtb_ids; do
        aws ec2 delete-route-table --route-table-id $rtb_id
    done

    # Delete associated security groups
    sg_ids=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc_id --query 'SecurityGroups[*].GroupId' --output text)
    for sg_id in $sg_ids; do
        aws ec2 delete-security-group --group-id $sg_id
    done

    # Delete associated subnets
    subnet_ids=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id --query 'Subnets[*].SubnetId' --output text)
    for subnet_id in $subnet_ids; do
        aws ec2 delete-subnet --subnet-id $subnet_id
    done

    # Delete VPC itself
    aws ec2 delete-vpc --vpc-id $vpc_id
done

echo "All VPCs and associated resources deleted."

