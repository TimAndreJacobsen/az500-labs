resource "azurerm_automation_account" "lab01_updates" {
  name                = "aa-lab01-updates"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.labs.name
  sku_name            = "Basic"
  tags                = local.common_tags
}

resource "azurerm_log_analytics_workspace" "lab01_logs" {
  name                = "law-lab01-updates"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.labs.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_log_analytics_solution" "updates" {
  solution_name         = "Updates"
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.labs.name
  workspace_resource_id = azurerm_log_analytics_workspace.lab01_logs.id
  workspace_name        = azurerm_log_analytics_workspace.lab01_logs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Updates"
  }
}

resource "azurerm_virtual_machine_extension" "log_analytics_agent" {
  count                      = var.vm_count
  name                       = "OMSAgentForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.lab01_vm[count.index].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.14"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    workspaceId = azurerm_log_analytics_workspace.lab01_logs.workspace_id
  })

  protected_settings = jsonencode({
    workspaceKey = azurerm_log_analytics_workspace.lab01_logs.primary_shared_key
  })

  tags = local.common_tags
}