variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "alert_email" {
  description = "Email for alerts and notifications"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources in."
  type        = string
  default     = "norwayeast"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}

variable "admin_username" {
  description = "Admin username for VMs"
  type = string
  default = "azureuser"
}

variable "shutdown_time" {
  description = "Auto-shutdown time (24h format)"
  type = string
  default = "2200"
}

variable "timezone" {
    description = "Timezone for the auto-shutdown"
    type = string
    default = "W. Europe Standard Time"
}