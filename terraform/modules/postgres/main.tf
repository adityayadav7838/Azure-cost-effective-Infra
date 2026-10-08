# Private DNS zone required for PostgreSQL Flexible Server VNet integration
# (Requirement 4.2 — private network access only)
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

# Link the private DNS zone to the VNet so AKS pods can resolve the FQDN
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-dns-link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# PostgreSQL Flexible Server with VNet integration (Requirement 4.1, 4.2)
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.environment}-${var.location}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "15"
  delegated_subnet_id    = var.postgres_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  # Development-appropriate SKU (Requirement 4.1, 9.2)
  sku_name   = var.sku_name
  storage_mb = 32768

  # Disable public network access — private VNet only (Requirement 4.2)
  public_network_access_enabled = false

  # Ignore zone assignment drift from Azure's auto-placement
  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Application database (Requirement 4.3)
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}