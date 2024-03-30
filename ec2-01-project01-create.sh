#!/bin/bash

# Set variables
instance_name="ec2-01"
tag_to_delete="todelete"
ami_id="ami-097c4e1feeea169e5"
architecture="x86_64"
instance_type="t2.micro"
key_name="chillexbro"
security_group_id="sg-0b5fd4b978094205e"
resource_file="temp-resource.txt"

# Load VPC resources from file
vpc_id=$(grep -oP 'VPC created successfully with ID: \K.*' $resource_file)
public_subnet_id=$(grep -oP 'Public subnet created successfully with ID: \K.*' $resource_file)

# Create EC2 instance
instance_id=$(aws ec2 run-instances \
    --image-id $ami_id \
    --instance-type $instance_type \
    --key-name $key_name \
    --security-group-ids $security_group_id \
    --subnet-id $public_subnet_id \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name}},{Key=${tag_to_delete},Value=true}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "EC2 instance created successfully with ID: $instance_id"
