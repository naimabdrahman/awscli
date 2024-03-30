#!/bin/bash

# Set variables
project_prefix="project01"
vpc_cidr_block="10.0.0.0/16"
availability_zone="ap-southeast-1a"
public_subnet_cidr_block="10.0.1.0/24"
private_subnet_cidr_block="10.0.2.0/24"
tag_to_delete="todelete"
resource_file="temp-resource.txt"

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr_block --query 'Vpc.VpcId' --output text --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${project_prefix}-vpc},{Key=${tag_to_delete},Value=true}]")
echo "VPC created successfully with ID: $vpc_id" >> $resource_file

# Enable DNS hostnames and resolution
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"

# Create public subnet
public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $public_subnet_cidr_block --availability-zone $availability_zone --query 'Subnet.SubnetId' --output text --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${project_prefix}-public-subnet},{Key=${tag_to_delete},Value=true}]")
echo "Public subnet created successfully with ID: $public_subnet_id" >> $resource_file

# Create private subnet
private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $private_subnet_cidr_block --availability-zone $availability_zone --query 'Subnet.SubnetId' --output text --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${project_prefix}-private-subnet},{Key=${tag_to_delete},Value=true}]")
echo "Private subnet created successfully with ID: $private_subnet_id" >> $resource_file

# Create internet gateway
internet_gateway_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${project_prefix}-igw},{Key=${tag_to_delete},Value=true}]")
echo "Internet gateway created successfully with ID: $internet_gateway_id" >> $resource_file

# Attach internet gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $internet_gateway_id

# Create route table
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${project_prefix}-route-table},{Key=${tag_to_delete},Value=true}]")
echo "Route table created successfully with ID: $route_table_id" >> $resource_file

# Create route for public subnet
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $internet_gateway_id

# Associate public subnet with route table
aws ec2 associate-route-table --subnet-id $public_subnet_id --route-table-id $route_table_id

# Create NAT gateway
allocation_id=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
nat_gateway_id=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $allocation_id --query 'NatGateway.NatGatewayId' --output text --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${project_prefix}-nat-gateway},{Key=${tag_to_delete},Value=true}]")
echo "NAT gateway created successfully with ID: $nat_gateway_id" >> $resource_file

# Wait for NAT gateway to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids $nat_gateway_id

# Create route table for private subnet
private_route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${project_prefix}-private-route-table},{Key=${tag_to_delete},Value=true}]")
echo "Private route table created successfully with ID: $private_route_table_id" >> $resource_file

# Create route for private subnet
aws ec2 create-route --route-table-id $private_route_table_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gateway_id

# Associate private subnet with route table
aws ec2 associate-route-table --subnet-id $private_subnet_id --route-table-id $private_route_table_id

# Create VPC endpoint for S3
aws ec2 create-vpc-endpoint --vpc-id $vpc_id --service-name com.amazonaws.ap-southeast-1.s3 --route-table-ids $route_table_id --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=${project_prefix}-s3-endpoint},{Key=${tag_to_delete},Value=true}]"

echo "Project infrastructure created successfully."
