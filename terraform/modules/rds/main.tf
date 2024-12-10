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
  vpc_security_group_ids = [var.db_security_group_id] 
  skip_final_snapshot = true
  tags = { Name = "donutdb" } 
}