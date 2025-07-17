#!/bin/bash

# =============================================================================
# Terraform Cleanup Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-prod}
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"

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

log_warning "This script will help you clean up Terraform resources and state"
echo ""
echo "Available options:"
echo "1. Clean Terraform state only (remove from state but keep Azure resources)"
echo "2. Destroy all Terraform-managed resources"
echo "3. Remove specific resources from state"
echo "4. Clean temporary files only"
echo ""

read -p "Choose an option (1-4): " option

case $option in
    1)
        log_warning "This will remove all resources from Terraform state but keep them in Azure"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            log_info "Listing current state..."
            terraform state list
            
            read -p "Remove all these from state? (yes/no): " confirm2
            if [ "$confirm2" = "yes" ]; then
                # Get all resources and remove them from state
                terraform state list | xargs -I {} terraform state rm {}
                log_success "All resources removed from state"
            fi
        fi
        ;;
    2)
        log_warning "This will DESTROY all resources managed by Terraform in Azure"
        read -p "Are you absolutely sure? Type 'destroy' to confirm: " confirm
        if [ "$confirm" = "destroy" ]; then
            terraform plan -destroy -var-file="$TFVARS_FILE" -out=destroy.tfplan
            read -p "Review the destroy plan above. Continue? (yes/no): " confirm2
            if [ "$confirm2" = "yes" ]; then
                terraform apply destroy.tfplan
                log_success "Resources destroyed"
            fi
            rm -f destroy.tfplan
        fi
        ;;
    3)
        log_info "Current resources in state:"
        terraform state list
        echo ""
        read -p "Enter the resource name to remove (e.g., azurerm_resource_group.main): " resource
        if [ ! -z "$resource" ]; then
            terraform state rm "$resource"
            log_success "Resource $resource removed from state"
        fi
        ;;
    4)
        log_info "Cleaning temporary files..."
        rm -f *.tfplan
        rm -f *.log
        rm -f .terraform.lock.hcl
        rm -rf .terraform/
        log_success "Temporary files cleaned"
        ;;
    *)
        log_error "Invalid option"
        exit 1
        ;;
esac

log_success "Cleanup completed!"
