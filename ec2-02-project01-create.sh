#!/bin/bash

# Set variables
instance_name="ec2-02"
tag_to_delete="todelete"
ami_id="ami-097c4e1feeea169e5"
architecture="x86_64"
instance_type="t2.micro"
key_name="chillexbro"
resource_file="temp-resource.txt"

# Load VPC resources from file
vpc_id=$(grep -oP 'VPC created successfully with ID: \K.*' $resource_file)
private_subnet_id=$(grep -oP 'Private subnet created successfully with ID: \K.*' $resource_file)

# Get security group ID
security_group_id=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values=launch-wizard-1 \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

# Create EC2 instance in private subnet
instance_id=$(aws ec2 run-instances \
    --image-id $ami_id \
    --instance-type $instance_type \
    --key-name $key_name \
    --security-group-ids $security_group_id \
    --subnet-id $private_subnet_id \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name}},{Key=${tag_to_delete},Value=true}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "EC2 instance created successfully in private subnet with ID: $instance_id"
