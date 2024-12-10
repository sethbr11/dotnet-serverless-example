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


