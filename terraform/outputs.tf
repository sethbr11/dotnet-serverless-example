# Output the RDS endpoint for use in the application
output "rds_endpoint" {
  value = aws_db_instance.donutdb.endpoint
}

output "rds_username" {
  value = aws_db_instance.donutdb.username
}

output "rds_password" {
  value = aws_db_instance.donutdb.password
  sensitive = true
}