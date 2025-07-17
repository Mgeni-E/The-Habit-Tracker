#!/bin/bash

# =============================================================================
# Terraform Deployment Script with Duplicate Prevention
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-prod}
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"
PLAN_FILE="tfplan-${ENVIRONMENT}"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    log_error "Please run this script from the terraform directory"
    exit 1
fi

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    log_error "Environment file $TFVARS_FILE not found"
    exit 1
fi

log_info "Starting Terraform deployment for environment: $ENVIRONMENT"

# Step 1: Initialize Terraform
log_info "Initializing Terraform..."
terraform init

# Step 2: Validate configuration
log_info "Validating Terraform configuration..."
terraform validate

# Step 3: Format check
log_info "Checking Terraform formatting..."
terraform fmt -check || {
    log_warning "Terraform files are not properly formatted. Running terraform fmt..."
    terraform fmt
}

# Step 4: Plan with automatic import handling
log_info "Creating Terraform plan..."
if terraform plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE" 2>&1 | tee plan_output.log; then
    log_success "Plan created successfully"
else
    log_warning "Plan failed. Checking for existing resources to import..."

    # Function to import existing resources
    import_existing_resources() {
        local subscription_id=$(az account show --query id -o tsv 2>/dev/null || echo "")

        if [ -z "$subscription_id" ]; then
            log_error "Could not get Azure subscription ID. Please ensure you're logged in to Azure CLI."
            return 1
        fi

        local imported=false

        # Check for resource group import needed
        if grep -q "habit-tracker-${ENVIRONMENT}-rg.*already exists" plan_output.log; then
            log_info "Importing existing resource group..."
            if terraform import azurerm_resource_group.main "/subscriptions/${subscription_id}/resourceGroups/habit-tracker-${ENVIRONMENT}-rg"; then
                imported=true
            fi
        fi

        # Check for virtual network import needed
        if grep -q "habit-tracker-${ENVIRONMENT}-vnet.*already exists" plan_output.log; then
            log_info "Importing existing virtual network..."
            if terraform import azurerm_virtual_network.main "/subscriptions/${subscription_id}/resourceGroups/habit-tracker-${ENVIRONMENT}-rg/providers/Microsoft.Network/virtualNetworks/habit-tracker-${ENVIRONMENT}-vnet"; then
                imported=true
            fi
        fi

        # Check for public IP import needed
        if grep -q "habit-tracker-${ENVIRONMENT}-pip.*already exists" plan_output.log; then
            log_info "Importing existing public IP..."
            if terraform import azurerm_public_ip.main "/subscriptions/${subscription_id}/resourceGroups/habit-tracker-${ENVIRONMENT}-rg/providers/Microsoft.Network/publicIPAddresses/habit-tracker-${ENVIRONMENT}-pip"; then
                imported=true
            fi
        fi

        # Check for NSG import needed
        if grep -q "habit-tracker-${ENVIRONMENT}-web-nsg.*already exists" plan_output.log; then
            log_info "Importing existing network security group..."
            if terraform import azurerm_network_security_group.web "/subscriptions/${subscription_id}/resourceGroups/habit-tracker-${ENVIRONMENT}-rg/providers/Microsoft.Network/networkSecurityGroups/habit-tracker-${ENVIRONMENT}-web-nsg"; then
                imported=true
            fi
        fi

        # Check for private DNS zone import needed
        if grep -q "habit-tracker-${ENVIRONMENT}-postgres.private.postgres.database.azure.com.*already exists" plan_output.log; then
            log_info "Importing existing private DNS zone..."
            if terraform import azurerm_private_dns_zone.postgres "/subscriptions/${subscription_id}/resourceGroups/habit-tracker-${ENVIRONMENT}-rg/providers/Microsoft.Network/privateDnsZones/habit-tracker-${ENVIRONMENT}-postgres.private.postgres.database.azure.com"; then
                imported=true
            fi
        fi

        return $imported
    }

    # Check for duplicate resource errors
    if grep -q "already exists" plan_output.log; then
        log_warning "Found existing resources. Attempting to import them automatically..."

        if import_existing_resources; then
            log_info "Resources imported successfully. Retrying plan..."
            if terraform plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE" 2>&1 | tee plan_output_retry.log; then
                log_success "Plan created successfully after import"
                mv plan_output_retry.log plan_output.log
            else
                log_error "Plan still failed after import. Manual intervention required."
                echo "Remaining issues:"
                cat plan_output_retry.log
                rm -f plan_output.log plan_output_retry.log
                exit 1
            fi
        else
            log_error "Could not import resources automatically. Manual intervention required."
            echo ""
            echo "Existing resources found:"
            grep "already exists" plan_output.log | sed 's/.*ID "\(.*\)" already exists.*/\1/'
            echo ""
            echo "You can:"
            echo "1. Delete these resources from Azure portal"
            echo "2. Import them manually using: terraform import <resource_type>.<name> <azure_resource_id>"
            echo "3. Use a different environment name"
            rm -f plan_output.log
            exit 1
        fi
    else
        log_error "Plan failed for unknown reasons:"
        cat plan_output.log
        rm -f plan_output.log
        exit 1
    fi
fi

# Step 5: Show plan summary
log_info "Plan Summary:"
terraform show -no-color "$PLAN_FILE" | grep -E "Plan:|Changes to Outputs:" || true

# Step 6: Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Deployment cancelled by user"
    rm -f "$PLAN_FILE" plan_output.log
    exit 0
fi

# Step 7: Apply the plan
log_info "Applying Terraform plan..."
if terraform apply "$PLAN_FILE"; then
    log_success "Deployment completed successfully!"
    
    # Show important outputs
    log_info "Important outputs:"
    terraform output public_ip_address 2>/dev/null || true
    terraform output application_url_http 2>/dev/null || true
    terraform output ssh_connection_command 2>/dev/null || true
    
else
    log_error "Deployment failed!"
    exit 1
fi

# Clean up
rm -f "$PLAN_FILE" plan_output.log

log_success "Deployment script completed!"
