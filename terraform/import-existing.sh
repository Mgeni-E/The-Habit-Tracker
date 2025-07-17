#!/bin/bash

# =============================================================================
# Terraform Import Existing Resources Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
ENVIRONMENT=${1:-prod}
PROJECT_NAME="habit-tracker"
SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || echo "")

if [ -z "$SUBSCRIPTION_ID" ]; then
    log_error "Could not get Azure subscription ID. Please ensure you're logged in to Azure CLI."
    exit 1
fi

log_info "Starting import of existing resources for environment: $ENVIRONMENT"
log_info "Subscription ID: $SUBSCRIPTION_ID"

# Resource names
RG_NAME="${PROJECT_NAME}-${ENVIRONMENT}-rg"
VNET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-vnet"
WEB_SUBNET_NAME="web-subnet"
PIP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-pip"
NSG_NAME="${PROJECT_NAME}-${ENVIRONMENT}-web-nsg"
NIC_NAME="${PROJECT_NAME}-${ENVIRONMENT}-nic"
VM_NAME="${PROJECT_NAME}-${ENVIRONMENT}-vm"

# Function to check if resource exists in Azure
resource_exists() {
    local resource_type=$1
    local resource_name=$2
    local resource_group=$3
    
    case $resource_type in
        "rg")
            az group show --name "$resource_name" >/dev/null 2>&1
            ;;
        "vnet")
            az network vnet show --name "$resource_name" --resource-group "$resource_group" >/dev/null 2>&1
            ;;
        "subnet")
            local vnet_name=$4
            az network vnet subnet show --name "$resource_name" --vnet-name "$vnet_name" --resource-group "$resource_group" >/dev/null 2>&1
            ;;
        "pip")
            az network public-ip show --name "$resource_name" --resource-group "$resource_group" >/dev/null 2>&1
            ;;
        "nsg")
            az network nsg show --name "$resource_name" --resource-group "$resource_group" >/dev/null 2>&1
            ;;
        "nic")
            az network nic show --name "$resource_name" --resource-group "$resource_group" >/dev/null 2>&1
            ;;
        "vm")
            az vm show --name "$resource_name" --resource-group "$resource_group" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if resource exists in Terraform state
in_terraform_state() {
    local resource_address=$1
    terraform state show "$resource_address" >/dev/null 2>&1
}

# Function to import resource if it exists in Azure but not in Terraform state
import_if_needed() {
    local resource_type=$1
    local resource_name=$2
    local terraform_address=$3
    local azure_resource_id=$4
    local resource_group=${5:-""}
    local vnet_name=${6:-""}

    # Check if already in Terraform state
    if in_terraform_state "$terraform_address"; then
        log_info "✅ $terraform_address already in Terraform state"
        return 0
    fi

    # Check if exists in Azure
    if resource_exists "$resource_type" "$resource_name" "$resource_group" "$vnet_name"; then
        log_warning "🔄 Found existing $resource_name in Azure, importing to Terraform state..."
        if terraform import "$terraform_address" "$azure_resource_id"; then
            log_success "✅ Successfully imported $terraform_address"
        else
            log_error "❌ Failed to import $terraform_address"
            return 1
        fi
    else
        log_info "ℹ️  $resource_name does not exist in Azure, will be created"
    fi
}

# Start importing
log_info "🔍 Checking and importing existing resources..."

# 1. Resource Group
import_if_needed "rg" "$RG_NAME" "azurerm_resource_group.main" \
    "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"

# 2. Virtual Network (only if resource group exists)
if resource_exists "rg" "$RG_NAME"; then
    import_if_needed "vnet" "$VNET_NAME" "azurerm_virtual_network.main" \
        "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME" \
        "$RG_NAME"

    # 3. Web Subnet (only if virtual network exists)
    if resource_exists "vnet" "$VNET_NAME" "$RG_NAME"; then
        import_if_needed "subnet" "$WEB_SUBNET_NAME" "azurerm_subnet.web" \
            "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$WEB_SUBNET_NAME" \
            "$RG_NAME" "$VNET_NAME"
    fi

    # 4. Public IP
    import_if_needed "pip" "$PIP_NAME" "azurerm_public_ip.main" \
        "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/publicIPAddresses/$PIP_NAME" \
        "$RG_NAME"

    # 5. Network Security Group
    import_if_needed "nsg" "$NSG_NAME" "azurerm_network_security_group.web" \
        "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/networkSecurityGroups/$NSG_NAME" \
        "$RG_NAME"

    # 6. Network Interface
    import_if_needed "nic" "$NIC_NAME" "azurerm_network_interface.main" \
        "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/networkInterfaces/$NIC_NAME" \
        "$RG_NAME"

    # 7. Virtual Machine
    import_if_needed "vm" "$VM_NAME" "azurerm_linux_virtual_machine.main" \
        "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Compute/virtualMachines/$VM_NAME" \
        "$RG_NAME"
fi

log_success "🎉 Import process completed!"
log_info "📋 Current Terraform state:"
terraform state list

log_info "✅ Ready to run terraform plan/apply"
