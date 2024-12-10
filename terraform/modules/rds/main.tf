/***********
Inputs
************/
variable "vpc_id" {
  description = "The VPC ID to be used by the RDS instance"
  type        = string
}

/***********
Security Group Configuration
************/

# Create the database security group
resource "aws_security_group" "db_security_group" {
  name        = "Database security group"
  description = "Database security group that allows 3306 and 22"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/***********
RDS Configuration
************/

resource "aws_db_instance" "donutdb" { 
  allocated_storage    = 20 
  storage_type         = "gp2" 
  engine               = "mysql" 
  engine_version       = "8.0.39" 
  instance_class       = "db.m5.large"
  username             = "admin" 
  password             = "password" 
  db_subnet_group_name = "donutdb_subnet_group" 
  vpc_security_group_ids = [aws_security_group.db_security_group.id] 
  skip_final_snapshot = true
  tags = { Name = "donutdb" } 
}

/***********
Outputs
************/
output "rds_endpoint" {
  value = aws_db_instance.donutdb.endpoint
  description = "The endpoint of the RDS instance."
}

output "rds_port" {
  value = aws_db_instance.donutdb.port
  description = "RDS database port"
}

output "rds_username" {
  value = aws_db_instance.donutdb.username
  description = "The username for the RDS instance."
}

output "rds_password" {
  value = aws_db_instance.donutdb.password
  sensitive = true
  description = "The password for the RDS instance."
}