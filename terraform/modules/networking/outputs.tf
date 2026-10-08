output "vnet_id" {
  description = "ID of the provisioned Virtual Network."
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "ID of the AKS node subnet."
  value       = azurerm_subnet.aks.id
}

output "postgres_subnet_id" {
  description = "ID of the PostgreSQL Flexible Server subnet."
  value       = azurerm_subnet.postgres.id
}

output "bastion_subnet_id" {
  description = "ID of the bastion host subnet."
  value       = azurerm_subnet.bastion.id
}

output "resource_group_name" {
  description = "Name of the Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

output "aks_subnet_cidr" {
  description = "CIDR block of the AKS subnet, used for PostgreSQL firewall rules."
  value       = var.aks_subnet_cidr
}
