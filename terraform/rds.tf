/***********
RDS Configuration
************/

# Create the database security group
resource "aws_security_group" "db_security_group" {
  name        = "Database security group"
  description = "Database security group that allows 3306 and 22"
  vpc_id      = aws_vpc.account_vpc.id

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

# RDS INSTANCE
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
