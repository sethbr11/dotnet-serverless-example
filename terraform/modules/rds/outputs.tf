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