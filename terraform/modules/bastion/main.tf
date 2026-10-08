# All bastion resources are conditionally created via count = var.enable_bastion ? 1 : 0

resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "pip-bastion-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "nic-bastion-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion[0].id
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "vm-bastion-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.bastion[0].id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Disable password authentication — key-only (Requirement 2.4)
  disable_password_authentication = true


  # Automated cloud-init bootstrap
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    # Non-interactive updates and prerequisites
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg postgresql-client dnsutils netcat-openbsd

    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

    # Install kubectl
    az aks install-cli

    # Set up aliases for azureuser
    cat << 'ALIASES' >> /home/azureuser/.bashrc
    alias k="kubectl"
    alias kgp="kubectl get pods"
    alias kgs="kubectl get svc"
    alias kga="kubectl get all -A"
    ALIASES
    chown azureuser:azureuser /home/azureuser/.bashrc
  EOF
  )
}


