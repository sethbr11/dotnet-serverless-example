/***********
Provider Configuration
************/

terraform { 
  required_providers { 
    aws = { 
      source  = "hashicorp/aws" 
      version = "~> 5.0" 
    } 
  } 
} 

provider "aws" { 
  region = "us-east-2"
    access_key = var.aws_access_key 
    secret_key = var.aws_secret_key 
} 

/***********
Modules
************/
module "networking" {
  source = "./modules/networking"
}

module "rds" {
  source = "./modules/rds"
  vpc_id = module.networking.vpc_id
  db_security_group_id = module.networking.db_security_group_id
}

module "fargate" {
  source = "./modules/fargate"
  vpc_id = module.networking.vpc_id
  db_endpoint = module.rds.rds_endpoint
  db_port = module.rds.rds_port
  db_user = module.rds.rds_username
  db_password = module.rds.rds_password
  public_subnet_id = module.networking.public_subnet_id
  public_subnet2_id = module.networking.public_subnet2_id
  private_subnet_id = module.networking.private_subnet_id
  ecr_repository_url = module.ecr.ecr_repository_url
  web_security_group_id = module.networking.web_security_group_id
}

module "ecr" {
  source = "./modules/ecr"
}