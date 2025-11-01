output "rds_endpoint" {
  description = "The connection endpoint for the RDS database"
  value       = aws_db_instance.main_db.endpoint
}