output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_admin_username" {
  description = "Admin username for the virtual machine"
  value       = azurerm_linux_virtual_machine.main.admin_username
}

output "ssh_private_key" {
  description = "Private SSH key for accessing the virtual machine"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "Public SSH key for the virtual machine"
  value       = tls_private_key.ssh.public_key_openssh
}

# Application URL

output "application_url_http" {
  description = "HTTP URL for the application"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

# SSH Connection Information

output "ssh_connection_command" {
  description = "SSH command to connect to the virtual machine"
  value       = "ssh -i private_key.pem ${azurerm_linux_virtual_machine.main.admin_username}@${azurerm_public_ip.main.ip_address}"
}
