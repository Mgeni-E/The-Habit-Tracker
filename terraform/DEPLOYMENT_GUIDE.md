# Terraform Deployment Guide

This guide explains how to deploy the Habit Tracker infrastructure using Terraform with automatic duplicate resource handling.

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and logged in:
   ```bash
   az login
   ```

2. **Terraform** installed (version ~1.0):
   ```bash
   terraform --version
   ```

3. **Required GitHub Secrets** (for CI/CD):
   - `AZURE_CREDENTIALS` - Azure service principal credentials
   - `TF_VAR_flask_secret_key` - Flask secret key
   - `TF_VAR_container_image_name` - Container image name
   - `TF_VAR_github_username` - GitHub username

### Local Deployment

1. **Navigate to terraform directory**:
   ```bash
   cd terraform
   ```

2. **Use the deployment script** (recommended):
   ```bash
   ./deploy.sh prod
   ```

   Or manually:
   ```bash
   terraform init
   terraform plan -var-file="environments/prod.tfvars"
   terraform apply -var-file="environments/prod.tfvars"
   ```

## 🔧 Handling Duplicate Resources

### Automatic Import (New Feature!)

The deployment now automatically handles existing resources:

- **CI/CD Pipeline**: Automatically detects and imports existing resources
- **Local Deployment**: Use `./deploy.sh` for automatic import handling
- **Manual Import**: Use `./cleanup.sh` for manual resource management

### Common Scenarios

#### Scenario 1: First Time Deployment
- Everything works automatically
- No manual intervention needed

#### Scenario 2: Re-running After Partial Failure
- Script automatically detects existing resources
- Imports them into Terraform state
- Continues with deployment

#### Scenario 3: Manual Cleanup Needed
```bash
./cleanup.sh
# Choose option 1: Clean Terraform state only
# Or option 2: Destroy all resources
```

## 📋 Available Scripts

### `./deploy.sh [environment]`
- **Purpose**: Deploy infrastructure with automatic duplicate handling
- **Usage**: `./deploy.sh prod` or `./deploy.sh dev`
- **Features**:
  - Automatic resource import
  - Plan validation
  - User confirmation
  - Error handling

### `./cleanup.sh`
- **Purpose**: Clean up resources and state
- **Options**:
  1. Clean Terraform state only
  2. Destroy all resources
  3. Remove specific resources
  4. Clean temporary files

## 🔍 Troubleshooting

### Common Issues

#### "Resource already exists" Error
**Solution**: Use the deployment script which handles this automatically:
```bash
./deploy.sh prod
```

#### Plan/Apply Fails in CI/CD
**Cause**: Usually due to existing resources not in state
**Solution**: The CI/CD pipeline now handles this automatically

#### Manual Import Needed
If automatic import fails, you can import manually:
```bash
# Example for resource group
terraform import azurerm_resource_group.main /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/habit-tracker-prod-rg
```

### Debugging Steps

1. **Check Azure CLI login**:
   ```bash
   az account show
   ```

2. **Verify Terraform state**:
   ```bash
   terraform state list
   ```

3. **Check for existing resources**:
   ```bash
   az group list --query "[?name=='habit-tracker-prod-rg']"
   ```

## 🏗️ Infrastructure Overview

### Resources Created

- **Resource Group**: `habit-tracker-prod-rg`
- **Virtual Network**: `habit-tracker-prod-vnet`
- **Subnets**: Web and Database subnets
- **Virtual Machine**: Ubuntu 22.04 LTS
- **PostgreSQL**: Flexible Server with private networking
- **Security**: Network Security Groups, Private DNS
- **Storage**: Premium SSD for VM

### Security Features

- Database accessible only from within VNet
- SSH key-based authentication
- Network security groups
- Private DNS zones
- SSL/TLS encryption

## 📊 Monitoring

### Outputs Available

After deployment, you can get important information:

```bash
# Get public IP
terraform output public_ip_address

# Get SSH connection command
terraform output ssh_connection_command

# Get database connection string (sensitive)
terraform output database_connection_string
```

## 🔄 CI/CD Integration

### GitHub Actions Workflow

The CI/CD pipeline includes:

1. **Test**: Run unit tests and linting
2. **Build**: Build and push Docker image
3. **Plan**: Create Terraform plan with auto-import
4. **Apply**: Deploy infrastructure with auto-import
5. **Deploy**: Deploy application to VM

### Environment Variables

Set these in GitHub repository secrets:
- `AZURE_CREDENTIALS`
- `TF_VAR_flask_secret_key`
- `TF_VAR_container_image_name`
- `TF_VAR_github_username`
- `TF_VAR_domain_name` (optional)
- `TF_VAR_ssl_email` (optional)

## 📝 Best Practices

1. **Always use the deployment script** for local deployments
2. **Test in dev environment** before deploying to prod
3. **Review plans carefully** before applying
4. **Keep state files secure** (stored in Azure by default)
5. **Use environment-specific tfvars** files
6. **Monitor costs** in Azure portal

## 🆘 Support

If you encounter issues:

1. Check this guide first
2. Review the error messages carefully
3. Use the cleanup script if needed
4. Check Azure portal for resource status
5. Verify GitHub secrets are set correctly

For more detailed information, see the main project README.md.
