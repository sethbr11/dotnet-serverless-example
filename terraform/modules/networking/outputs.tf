/***********
Outputs
************/
output "vpc_id" {
  value       = aws_vpc.account_vpc.id
  description = "The ID of the VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.donuteast2a_public_sn.id
  description = "The ID of the public subnet"
}

output "private_subnet_id" {
  value       = aws_subnet.donuteast2b_private_sn.id
  description = "The ID of the private subnet"
}

output "web_security_group_id" {
  value       = aws_security_group.web_security_group.id
  description = "The ID of the web security group"
}

output "db_security_group_id" {
  value       = aws_security_group.db_security_group.id
  description = "The ID of the database security group"
}