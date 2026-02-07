output "resource_group_name" {
    description = "Resource group name"
    value = data.azurerm_resource_group.labs.name
}

output "vm_names" {
    description = "VM names"
    value = azurerm_linux_virtual_machine.lab01_vm[*].name
}

output "vm_public_ips" {
    description = "VM public IPs"
    value = azurerm_public_ip.lab01_public_ip[*].name
}

output "vm_private_ips" {
  description = "VM private IPs"
  value = azurerm_network_interface.lab01_nic[*].private_ip_address_allocation
}

output "ssh_commands" {
  description = "SSH commands to connect to VMs"
  value = [
    for i, ip in azurerm_public_ip.lab01[*].ip_address :
    "ssh ${var.admin_username}@${ip}"
  ]
} 