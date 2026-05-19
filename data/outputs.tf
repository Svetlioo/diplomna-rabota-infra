output "server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "admin_username" {
  description = "Administrator username (sensitive)."
  value       = var.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "Administrator password (sensitive)."
  value       = random_password.admin.result
  sensitive   = true
}

output "databases" {
  description = "Map of environment to database name."
  value       = { for k, v in var.environments : k => v.database }
}
