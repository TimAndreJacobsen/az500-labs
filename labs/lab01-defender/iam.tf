# Get current user identity for role assignments
data "azurerm_client_config" "current" {}

# Grant Security Admin role for JIT access requests
resource "azurerm_role_assignment" "security_admin" {
  scope                = data.azurerm_resource_group.labs.id
  role_definition_name = "Security Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
