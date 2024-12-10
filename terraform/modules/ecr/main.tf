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
Outputs
************/
output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repository.repository_url
  description = "URL of the ECR repository"
}


