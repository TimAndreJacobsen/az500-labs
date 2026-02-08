resource "azurerm_maintenance_configuration" "lab01_patches" {
  name                     = "mc-lab01-weekly-patches"
  location                 = var.location
  resource_group_name      = data.azurerm_resource_group.labs.name
  scope                    = "InGuestPatch"
  tags                     = local.common_tags

  in_guest_user_patch_mode = "User"

  window {
    start_date_time = "2026-02-15 02:00"
    expiration_date_time = "2027-02-15 02:00"
    time_zone       = "W. Europe Standard Time"
    duration        = "02:00"
    recur_every     = "1Week Sunday"
  }

  install_patches {
    reboot = "IfRequired"

    linux {
      classifications_to_include = ["Critical", "Security", "Other"]
    }
  }
}

resource "azurerm_maintenance_assignment_virtual_machine" "lab01_patch_assignment" {
  count                        = var.vm_count
  location                     = var.location
  maintenance_configuration_id = azurerm_maintenance_configuration.lab01_patches.id
  virtual_machine_id           = azurerm_linux_virtual_machine.lab01_vm[count.index].id
}

resource "azurerm_virtual_machine_extension" "patch_assessment" {
  count                      = var.vm_count
  name                       = "AzurePatchAssessment"
  virtual_machine_id         = azurerm_linux_virtual_machine.lab01_vm[count.index].id
  publisher                  = "Microsoft.CPlat.Core"
  type                       = "LinuxPatchExtension"
  type_handler_version       = "1.5"
  auto_upgrade_minor_version = true
  tags                       = local.common_tags
}