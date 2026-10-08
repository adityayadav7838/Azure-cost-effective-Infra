# Requirement 5.5 — output the Traefik Load Balancer public IP
output "traefik_public_ip" {
  description = "Public IP address of the Traefik LoadBalancer."
  value       = azurerm_public_ip.traefik.ip_address
}

# Requirement 6.3 — output the fully qualified DNS hostname
output "application_hostname" {
  description = "Fully qualified DNS hostname for the application (<dns_label>.<region>.cloudapp.azure.com)."
  value       = azurerm_public_ip.traefik.fqdn
}
