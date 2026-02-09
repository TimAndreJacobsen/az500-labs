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

resource "azurerm_key_vault" "lab01_kv" {
    name                        = "kv-lab01-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
    location                    = var.location
    resource_group_name         = data.azurerm_resource_group.labs.name
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    sku_name                    = "standard"
    enabled_for_disk_encryption = true
    rbac_authorization_enabled  = true
    purge_protection_enabled    = true
    soft_delete_retention_days  = 7
    tags                        = local.common_tags
}

# RBAC: Grant current user Key Vault Crypto Officer (manage keys)
resource "azurerm_role_assignment" "kv_crypto_officer" {
    scope                = azurerm_key_vault.lab01_kv.id
    role_definition_name = "Key Vault Crypto Officer"
    principal_id         = data.azurerm_client_config.current.object_id
}

# Add disk encryption key
resource "azurerm_key_vault_key" "lab01_disk_key" {
    name         = "disk-encryption-key"
    key_vault_id = azurerm_key_vault.lab01_kv.id
    key_type     = "RSA"
    key_size     = 2048
    key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

# DES - use the key
resource "azurerm_disk_encryption_set" "lab01_des" {
    name                = "des-lab01-vms"
    location            = var.location
    resource_group_name = data.azurerm_resource_group.labs.name
    key_vault_key_id    = azurerm_key_vault_key.lab01_disk_key.id
    tags                = local.common_tags

    identity {
        type = "SystemAssigned"
    }
}

# RBAC: Grant Disk Encryption Set access to Key Vault keys
resource "azurerm_role_assignment" "des_kv_crypto_user" {
    scope                = azurerm_key_vault.lab01_kv.id
    role_definition_name = "Key Vault Crypto Service Encryption User"
    principal_id         = azurerm_disk_encryption_set.lab01_des.identity[0].principal_id
}

resource "azurerm_virtual_network" "lab01_vnet" {
    name                = "vnet-lab01-defender"
    address_space       = ["10.1.0.0/16"]
    location            = var.location
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
    location            = var.location
    resource_group_name = data.azurerm_resource_group.labs.name
    tags                = local.common_tags

    # ─── Inbound Rules ────────────────────────────────────────────────
    # SSH is managed by JIT (no permanent allow rule)
    # Deny all other inbound by default (implicit, but explicit is better)

    security_rule = [
    {
        name                                       = "DenyAllInbound"
        priority                                   = 4096
        direction                                  = "Inbound"
        access                                     = "Deny"
        protocol                                   = "*"
        destination_port_range                     = "*"
        destination_port_ranges                    = []
        source_port_range                          = "*"
        source_port_ranges                         = []
        source_address_prefix                      = "*"
        source_address_prefixes                    = []
        destination_address_prefix                 = "*"
        destination_address_prefixes               = []
        source_application_security_group_ids      = []
        destination_application_security_group_ids = []
        description                                = "Deny all inbound traffic - SSH managed by JIT"
    },
    # ─── Outbound Rules ───────────────────────────────────────────────
    {
        name                                       = "AllowHTTPSOutbound"
        priority                                   = 100
        direction                                  = "Outbound"
        access                                     = "Allow"
        protocol                                   = "Tcp"
        destination_port_range                     = "443"
        destination_port_ranges                    = []
        source_port_range                          = "*"
        source_port_ranges                         = []
        source_address_prefix                      = "VirtualNetwork"
        source_address_prefixes                    = []
        destination_address_prefix                 = "Internet"
        destination_address_prefixes               = []
        source_application_security_group_ids      = []
        destination_application_security_group_ids = []
        description                                = "Allow HTTPS outbound for updates and Azure services"
    },
    {
        name                                       = "AllowHTTPOutbound"
        priority                                   = 110
        direction                                  = "Outbound"
        access                                     = "Allow"
        protocol                                   = "Tcp"
        destination_port_range                     = "80"
        destination_port_ranges                    = []
        source_port_range                          = "*"
        source_port_ranges                         = []
        source_address_prefix                      = "VirtualNetwork"
        source_address_prefixes                    = []
        destination_address_prefix                 = "Internet"
        destination_address_prefixes               = []
        source_application_security_group_ids      = []
        destination_application_security_group_ids = []
        description                                = "Allow HTTP outbound for package repos"
    },
    {
        name                                       = "AllowDNSOutbound"
        priority                                   = 120
        direction                                  = "Outbound"
        access                                     = "Allow"
        protocol                                   = "*"
        destination_port_range                     = "53"
        destination_port_ranges                    = []
        source_port_range                          = "*"
        source_port_ranges                         = []
        source_address_prefix                      = "VirtualNetwork"
        source_address_prefixes                    = []
        destination_address_prefix                 = "Internet"
        destination_address_prefixes               = []
        source_application_security_group_ids      = []
        destination_application_security_group_ids = []
        description                                = "Allow DNS resolution"
    },
    {
        name                                       = "DenyAllOutbound"
        priority                                   = 4096
        direction                                  = "Outbound"
        access                                     = "Deny"
        protocol                                   = "*"
        destination_port_range                     = "*"
        destination_port_ranges                    = []
        source_port_range                          = "*"
        source_port_ranges                         = []
        source_address_prefix                      = "*"
        source_address_prefixes                    = []
        destination_address_prefix                 = "*"
        destination_address_prefixes               = []
        source_application_security_group_ids      = []
        destination_application_security_group_ids = []
        description                                = "Deny all other outbound traffic"
    }]
}

resource "azurerm_subnet_network_security_group_association" "lab01_nsg_association" {
    subnet_id                 = azurerm_subnet.lab01_subnet.id
    network_security_group_id = azurerm_network_security_group.lab01_nsg.id
}

resource "azurerm_public_ip" "lab01_public_ip" {
    count               = var.vm_count
    name                = "pip-lab01-vm-${count.index + 1}"
    location            = var.location
    resource_group_name = data.azurerm_resource_group.labs.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = local.common_tags
}

resource "azurerm_network_interface" "lab01_nic" {
    count               = var.vm_count
    name                = "nic-lab01-vm-${count.index + 1}"
    location            = var.location
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
    location            = var.location
    resource_group_name = data.azurerm_resource_group.labs.name
    size                = "Standard_B2ats_v2"
    admin_username      = var.admin_username
    tags                = local.common_tags

    network_interface_ids = [
        azurerm_network_interface.lab01_nic[count.index].id,
    ]

    admin_ssh_key {
      username = var.admin_username
      public_key = file(pathexpand("~/.ssh/az500_lab.pub"))
    }

    os_disk {
      name                   = "osdisk-lab01-vm${count.index + 1}"
      caching                = "ReadWrite"
      storage_account_type   = "Standard_LRS"
      disk_encryption_set_id = azurerm_disk_encryption_set.lab01_des.id
    }

    source_image_reference {
      publisher = "Canonical"
      offer     = "ubuntu-22_04-lts"
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

    location              = var.location
    tags                  = local.common_tags

    notification_settings {
      enabled = true
      time_in_minutes = 30
      email = var.alert_email
    }
    
}
