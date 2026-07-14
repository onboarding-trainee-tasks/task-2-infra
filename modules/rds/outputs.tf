output "db_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "The RDS instance name"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "The RDS instance username"
  value       = local.db_secrets.db_username
}

output "db_password" {
  description = "The RDS instance password"
  value       = local.db_secrets.db_password
}

output "db_instance_identifier" {
  value = aws_db_instance.this.identifier
}