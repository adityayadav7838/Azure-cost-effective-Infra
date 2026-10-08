resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.environment}"

  # Single-node system pool (Requirement 3.1, 3.2)
  default_node_pool {
    name           = "system"
    node_count     = 1
    vm_size        = var.node_vm_size
    vnet_subnet_id = var.subnet_id
  }

  # SystemAssigned Managed Identity (Requirement 3.3)
  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled = true

  # Azure CNI for proper VNet integration; Standard LB required for public ingress (Requirement 3.4)
  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
  }
}
