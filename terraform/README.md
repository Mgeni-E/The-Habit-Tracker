# Terraform Infrastructure for Habit Tracker

This directory contains Terraform configurations to provision Azure infrastructure for the Habit Tracker application.

## Architecture

The infrastructure includes:

- **Azure Virtual Machine**: Ubuntu 22.04 LTS with Docker, Nginx, and SSL certificates
- **Azure Database for PostgreSQL**: Flexible Server with private networking
- **Virtual Network**: Isolated network with separate subnets for web and database tiers
- **Network Security Groups**: Firewall rules allowing only HTTP, HTTPS, and SSH traffic
- **Public IP**: Static IP address for the web server
- **SSL Certificates**: Automatic Let's Encrypt certificate provisioning

## Prerequisites

1. **Azure CLI**: Install and configure Azure CLI
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform**: Install Terraform >= 1.0
   ```bash
   # On macOS
   brew install terraform
   
   # On Ubuntu/Debian
   wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

## Quick Start

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   # For production
   terraform plan -var-file="environments/prod.tfvars"
   
   # For development
   terraform plan -var-file="environments/dev.tfvars"
   ```

3. **Apply the configuration**:
   ```bash
   # For production
   terraform apply -var-file="environments/prod.tfvars"
   
   # For development
   terraform apply -var-file="environments/dev.tfvars"
   ```

4. **Get outputs**:
   ```bash
   terraform output
   ```

## Configuration

### Environment Variables

Set these environment variables or pass them via `-var` flags:

```bash
export TF_VAR_flask_secret_key="your-production-secret-key"
export TF_VAR_domain_name="your-domain.com"
export TF_VAR_ssl_email="admin@your-domain.com"
export TF_VAR_github_token="your-github-token"
export TF_VAR_github_username="your-github-username"
export TF_VAR_container_image_name="your-org/habit-tracker"
```

### Custom Domain (Optional)

If you have a custom domain:

1. Set the `domain_name` variable
2. Point your domain's A record to the output `public_ip_address`
3. SSL certificates will be automatically provisioned via Let's Encrypt

## File Structure

```
terraform/
├── main.tf                 # Main infrastructure resources
├── database.tf            # PostgreSQL database configuration
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── environments/          # Environment-specific configurations
│   ├── dev.tfvars         # Development environment
│   └── prod.tfvars        # Production environment
├── scripts/               # Deployment scripts
│   └── cloud-init.yml     # VM initialization script
└── README.md              # This file
```

## Security Features

- **Network Isolation**: Database in private subnet, web server in public subnet
- **Firewall Rules**: Only SSH (22), HTTP (80), and HTTPS (443) ports open
- **SSL/TLS**: Automatic HTTPS with Let's Encrypt certificates
- **Fail2ban**: Intrusion prevention system
- **UFW Firewall**: Host-based firewall configuration
- **Automatic Updates**: Unattended security updates enabled

## Monitoring and Logging

- **Application Logs**: Centralized logging with log rotation
- **Nginx Logs**: Access and error logs with rotation
- **System Monitoring**: Basic monitoring with htop and system logs

## Backup and Recovery

- **Database Backups**: 7-day retention with point-in-time recovery
- **High Availability**: Zone-redundant database configuration

## Cost Optimization

- **Development**: Uses smaller VM sizes and basic database tiers
- **Production**: Balanced performance and cost with burstable instances
- **Auto-shutdown**: Consider implementing auto-shutdown for development environments

## Troubleshooting

### Common Issues

1. **SSH Access**: Use the private key from terraform output
   ```bash
   terraform output -raw ssh_private_key > private_key.pem
   chmod 600 private_key.pem
   ssh -i private_key.pem azureuser@$(terraform output -raw public_ip_address)
   ```

2. **Database Connection**: Ensure the application is using the correct connection string
   ```bash
   terraform output database_connection_string
   ```

3. **SSL Certificate Issues**: Check certbot logs on the VM
   ```bash
   sudo journalctl -u certbot
   ```

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy -var-file="environments/prod.tfvars"
```

**Warning**: This will permanently delete all resources and data.

## Support

For issues and questions:
1. Check the Terraform logs for detailed error messages
2. Verify Azure permissions and quotas
3. Ensure all required variables are set correctly
