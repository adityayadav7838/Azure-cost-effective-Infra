# Static Standard SKU public IP for Traefik LoadBalancer
resource "azurerm_public_ip" "traefik" {
  name                = "pip-traefik-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  domain_name_label = var.dns_label
}

# Grant AKS identity permission to bind Public IPs in this Resource Group
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks_principal_id
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Traefik ingress controller deployed via official Helm chart
resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  namespace        = "traefik"
  create_namespace = true

  # 1. FIX: Increase timeout from 300s to 900s (15m) so Azure has time to finish provisioning
  timeout         = 900
  cleanup_on_fail = true
  wait            = true

  values = [
    yamlencode({
      service = {
        type = "LoadBalancer"
        annotations = {
          # Tell AKS to look in your main RG where the PIP was created
          "service.beta.kubernetes.io/azure-load-balancer-resource-group" = var.resource_group_name
          # Bind directly to the static IP resource name (recommended by Azure)
          "service.beta.kubernetes.io/azure-pip-name"                     = azurerm_public_ip.traefik.name
        }
        # FIX: Removed deprecated loadBalancerIP to prevent provider race condition
      }
      ports = {
        web = {
          port        = 80
          exposedPort = 80
        }
        websecure = {
          port        = 443
          exposedPort = 443
        }
      }
    })
  ]

  depends_on = [azurerm_public_ip.traefik,azurerm_role_assignment.aks_network_contributor]
}