/***********
Inputs
************/
variable "vpc_id" {
  description = "The VPC ID to be used by the RDS instance"
  type        = string
}

variable "db_security_group_id" {
  description = "The ID of the security group for the RDS instance"
  type        = string
}