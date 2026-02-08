# Get current user identity for role assignments
data "azurerm_client_config" "current" {}

# Grant Security Admin role for JIT access requests
resource "azurerm_role_assignment" "security_admin" {
  scope                = data.azurerm_resource_group.labs.id
  role_definition_name = "Security Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_security_center_contact" "lab01_contact" {
  name                = "high_severity_alerts"
  email               = var.alert_email
  alert_notifications = true
  alerts_to_admins    = true
}
