output "bastion_public_ip" {
  description = "Public IP address of the bastion host. Empty string when enable_bastion is false."
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : ""
}
