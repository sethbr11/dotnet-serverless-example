/***********
Inputs
************/
variable "vpc_id" {
  description = "The VPC ID to be used by the ECR repository"
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

variable "security_group_id" {
  description = "The ID of the security group"
  type        = string
}

/***********
ECR Repository
************/
resource "aws_ecr_repository" "app_repository" {
  name = "donut-rds-app"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "FargateRDSAppRepository"
  }
}

/***********
VPC Endpoint
************/
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.us-east-2.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [var.public_subnet_id, var.private_subnet_id]
  security_group_ids = [var.security_group_id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.us-east-2.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [var.public_subnet_id, var.private_subnet_id]
  security_group_ids = [var.security_group_id]
}

/***********
Outputs
************/
output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repository.repository_url
  description = "URL of the ECR repository"
}


