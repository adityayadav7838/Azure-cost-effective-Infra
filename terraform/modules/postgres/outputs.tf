# Requirement 4.4 — output FQDN and database name
output "postgres_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "Name of the application database created on the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "postgres_admin_username" {
  description = "Administrator login username for the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}
