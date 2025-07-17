#!/bin/bash

# =============================================================================
# Test Terraform Outputs Script
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

log_info "Testing Terraform configuration and outputs..."

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    log_error "Please run this script from the terraform directory"
    exit 1
fi

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    log_info "Terraform not initialized. Running terraform init..."
    terraform init
fi

# Check if state file exists
if [ ! -f "terraform.tfstate" ]; then
    log_warning "No terraform.tfstate file found. You may need to run terraform apply first."
    log_info "Available commands:"
    echo "  terraform plan -var-file=\"environments/prod.tfvars\""
    echo "  terraform apply -var-file=\"environments/prod.tfvars\""
    exit 0
fi

# List current state
log_info "Current Terraform state:"
terraform state list

# Test outputs
log_info "Testing Terraform outputs..."

# Test public IP output
if PUBLIC_IP=$(terraform output -raw public_ip_address 2>/dev/null); then
    log_success "✅ public_ip_address: $PUBLIC_IP"
else
    log_error "❌ Failed to get public_ip_address output"
fi

# Test SSH private key output
if SSH_KEY=$(terraform output -raw ssh_private_key 2>/dev/null); then
    KEY_LENGTH=$(echo "$SSH_KEY" | wc -c)
    log_success "✅ ssh_private_key: Retrieved ($KEY_LENGTH characters)"
else
    log_error "❌ Failed to get ssh_private_key output"
fi

# Test database outputs
if DB_HOST=$(terraform output -raw database_server_fqdn 2>/dev/null); then
    log_success "✅ database_server_fqdn: $DB_HOST"
else
    log_error "❌ Failed to get database_server_fqdn output"
fi

if DB_PASSWORD=$(terraform output -raw database_admin_password 2>/dev/null); then
    log_success "✅ database_admin_password: Retrieved (hidden for security)"
else
    log_error "❌ Failed to get database_admin_password output"
fi

# Show all outputs
log_info "All available outputs:"
terraform output

log_success "Output testing completed!"
