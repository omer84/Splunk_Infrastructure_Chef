# VPC ID
output "vpc_id" {
  value = aws_vpc.splunk_vpc.id
}

# ID of subnet in AZ1 
output "public_subnet_az1_id" {
  value = aws_subnet.public_subnet_az1.id
}

# ID of subnet in AZ2
output "public_subnet_az2_id" {
  value = aws_subnet.public_subnet_az2.id
}

# ID of subnet in AZ3
output "public_subnet_az3_id" {
  value = aws_subnet.public_subnet_az3.id
}

# Internet Gateway ID
output "internet_gateway" {
  value = aws_internet_gateway.splunk_internet_gateway.id
}
