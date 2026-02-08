# main.tf
resource "azurerm_resource_group" "az500_labs" {
  name     = "rg-az500-labs"
  location = "northeurope"

  tags = {
    Environment = "AZ500-Lab"
    ManagedBy   = "Terraform"
    Purpose     = "Certification-Study"
  }
}

resource "azurerm_consumption_budget_subscription" "monthly_budget" {
  name            = "az500-budget-50usd"
  subscription_id = "/subscriptions/${var.subscription_id}"

  amount     = 50
  time_grain = "Monthly"

  time_period {
    start_date = "2026-02-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 90.0
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }
}
