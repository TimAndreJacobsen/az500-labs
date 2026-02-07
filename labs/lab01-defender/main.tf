locals {
    resource_group_name = "rg-az500-labs"
    common_tags = {
        Environment  = "AZ500-labs"
        ManagedBy    = "Terraform"
        Lab          = "Lab01-Defender"
        AutoShutdown = "True"
        Owner        = "Tim.Jacobsen"
    }
}

# Use the common resource group, managed by the budget module
data "azurerm_resource_group" "labs" {
    name = local.resource_group_name
}

resource "azurerm_virtual_network" "lab01_vnet" {
    name                = "vnet-lab01-defender"
    address_space       = ["10.1.0.0/16"]
    location            = data.azurerm_resource_group.labs.location
    resource_group_name = data.azurerm_resource_group.labs.name
    tags                = local.common_tags
}

resource "azurerm_subnet" "lab01_subnet" {
    name                 = "snet-vms"
    resource_group_name  = data.azurerm_resource_group.labs.name
    virtual_network_name = azurerm_virtual_network.lab01_vnet.name
    address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_security_group" "lab01_nsg" {
    name                = "nsg-lab01-vms"
    location            = data.azurerm_resource_group.labs.location
    resource_group_name = data.azurerm_resource_group.labs.name
    tags                = local.common_tags

    # public SSH access
    security_rule = {
        name                        = "AllowSSH"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        destination_port_range      = "22"
        source_port_range           = "*"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }

    # Allow Outbound
    security_rule {
        name                        = "AllowInternetOutbound"
        priority                    = 100
        direction                   = "Outbound"
        access                      = "Allow"
        protocol                    = "*"
        source_port_range           = "*"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
}

resource "azurerm_subnet_network_security_group_association" "lab01_nsg_association" {
    subnet_id                 = azurerm_subnet.lab01_subnet.id
    network_security_group_id = azurerm_network_security_group.lab01_nsg.id
}

resource "azurerm_public_ip" "lab01_public_ip" {
    count               = var.vm_count
    name                = "pip-lab01-vm-${count.index + 1}"
    location            = data.azurerm_resource_group.labs.location
    resource_group_name = data.azurerm_resource_group.labs.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = local.common_tags
}

resource "azurerm_network_interface" "lab01_nic" {
    count               = var.vm_count
    name                = "nic-lab01-vm-${count.index + 1}"
    location            = data.azurerm_resource_group.labs.location
    resource_group_name = data.azurerm_resource_group.labs.name
    tags                = local.common_tags

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.lab01_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.lab01_public_ip[count.index].id
    }
}

resource "azurerm_linux_virtual_machine" "lab01_vm" {
    count               = var.vm_count
    name                = "vm-lab01-${count.index + 1}"
    location            = data.azurerm_resource_group.labs.location
    resource_group_name = data.azurerm_resource_group.labs.name
    size                = "Standard_B1s"  #cheapest
    admin_username      = var.admin_username
    tags                = local.common_tags

    network_interface_ids = [
        azurerm_network_interface.lab01_nic[count.index].id,
    ]

    admin_ssh_key {
      username = var.admin_username
      public_key = file("~/.ssh/id_rsa.pub") # Check if this is safe and best practice before running or doing anything
    }

    os_disk {
      name              = "osdisk-lab01-vm${count.index + 1}"
      caching           = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    source_image_reference {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }

    boot_diagnostics { # disable boot diag for cost saving, consider whether to enable or not
      storage_account_uri = null
    }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "lab01_shutdown" {
    count                 = var.vm_count
    virtual_machine_id    = azurerm_linux_virtual_machine.lab01_vm[count.index].id 
    enabled               = true
    daily_recurrence_time = var.shutdown_time
    timezone              = var.timezone

    location              = data.azurerm_resource_group.labs.location
    tags                  = local.common_tags

    notification_settings {
      enabled = true
      time_in_minutes = 30
      email = var.alert_email
    }
    
}