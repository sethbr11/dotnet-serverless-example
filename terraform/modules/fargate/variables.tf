/***********
Inputs
************/
variable "vpc_id" {
  description = "The VPC ID to be used by the fargate service"
  type        = string
}

variable "db_endpoint" {
  description = "The endpoint of the donut database"
  type        = string
}

variable "db_port" {
  description = "The port of the donut database"
  type        = number
}

variable "db_user" {
  description = "The user of the donut database"
  type        = string
}

variable "db_password" {
  description = "The password of the donut database"
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet"
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
  type        = string
}

variable "web_security_group_id" {
  description = "The security group to be used by the fargate service"
  type        = string
}