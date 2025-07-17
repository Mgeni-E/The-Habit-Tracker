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

# Step 4: Plan with duplicate detection
log_info "Creating Terraform plan..."
if terraform plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE" 2>&1 | tee plan_output.log; then
    log_success "Plan created successfully"
else
    log_error "Plan failed. Checking for duplicate resources..."
    
    # Check for duplicate resource errors
    if grep -q "already exists" plan_output.log; then
        log_warning "Found existing resources. You have several options:"
        echo "1. Import existing resources: terraform import <resource_type>.<name> <azure_resource_id>"
        echo "2. Delete existing resources from Azure portal"
        echo "3. Use a different environment name"
        echo ""
        echo "Existing resources found:"
        grep "already exists" plan_output.log | sed 's/.*ID "\(.*\)" already exists.*/\1/'
    fi
    
    # Clean up
    rm -f plan_output.log
    exit 1
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
