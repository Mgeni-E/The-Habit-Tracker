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

# Network Outputs

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "web_subnet_id" {
  description = "ID of the web subnet"
  value       = azurerm_subnet.web.id
}

# Application URLs

output "application_url_http" {
  description = "HTTP URL for the application"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "application_url_https" {
  description = "HTTPS URL for the application"
  value       = "https://${azurerm_public_ip.main.ip_address}"
}

output "application_url_domain" {
  description = "Domain URL for the application (if domain is configured)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "Not configured"
}

# SSH Connection Information

output "ssh_connection_command" {
  description = "SSH command to connect to the virtual machine"
  value       = "ssh -i private_key.pem ${azurerm_linux_virtual_machine.main.admin_username}@${azurerm_public_ip.main.ip_address}"
}
