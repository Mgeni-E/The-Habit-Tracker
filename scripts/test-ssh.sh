#!/bin/bash

# =============================================================================
# SSH Connection Test Script
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

# Check if VM IP is provided
if [ -z "$1" ]; then
    log_error "Usage: $0 <VM_IP>"
    log_info "Example: $0 40.120.25.211"
    exit 1
fi

VM_IP="$1"
USERNAME="azureuser"

log_info "Testing SSH connection to $VM_IP..."

# Test basic connectivity
log_info "1. Testing basic connectivity..."
if timeout 5 nc -zv "$VM_IP" 22 2>/dev/null; then
    log_success "✅ Port 22 is reachable"
else
    log_error "❌ Port 22 is not reachable"
    log_info "Possible issues:"
    log_info "  - VM is not running"
    log_info "  - Network Security Group blocking SSH"
    log_info "  - VM still booting"
    exit 1
fi

# Test SSH key authentication
log_info "2. Testing SSH key authentication..."

# Check if we have Terraform outputs
if [ -d "terraform" ] && [ -f "terraform/terraform.tfstate" ]; then
    log_info "Getting SSH key from Terraform..."
    cd terraform
    SSH_KEY=$(terraform output -raw ssh_private_key 2>/dev/null || echo "")
    cd ..
    
    if [ -n "$SSH_KEY" ]; then
        # Setup temporary SSH key
        mkdir -p ~/.ssh/temp
        echo "$SSH_KEY" > ~/.ssh/temp/id_rsa
        chmod 600 ~/.ssh/temp/id_rsa
        
        # Test SSH connection
        if timeout 10 ssh -i ~/.ssh/temp/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USERNAME@$VM_IP" "echo 'SSH connection successful'" 2>/dev/null; then
            log_success "✅ SSH key authentication successful"
            
            # Test VM readiness
            log_info "3. Testing VM readiness..."
            if ssh -i ~/.ssh/temp/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USERNAME@$VM_IP" "test -f /tmp/vm-ready" 2>/dev/null; then
                log_success "✅ VM initialization completed"
                READY_INFO=$(ssh -i ~/.ssh/temp/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USERNAME@$VM_IP" "cat /tmp/vm-ready" 2>/dev/null)
                log_info "VM ready info: $READY_INFO"
            else
                log_warning "⚠️ VM may still be initializing"
            fi
            
            # Test Docker
            log_info "4. Testing Docker installation..."
            if ssh -i ~/.ssh/temp/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USERNAME@$VM_IP" "sudo docker --version" 2>/dev/null; then
                log_success "✅ Docker is installed and accessible"
            else
                log_warning "⚠️ Docker may not be installed or accessible"
            fi
            
        else
            log_error "❌ SSH key authentication failed"
            log_info "Possible issues:"
            log_info "  - SSH key mismatch"
            log_info "  - VM user configuration issue"
            log_info "  - VM still initializing"
        fi
        
        # Cleanup
        rm -rf ~/.ssh/temp
    else
        log_error "❌ Could not get SSH key from Terraform"
    fi
else
    log_warning "⚠️ No Terraform state found. Cannot test SSH key authentication."
    log_info "Run this script from the project root directory after running terraform apply"
fi

log_info "SSH connection test completed!"
log_info ""
log_info "If SSH is failing in CI/CD:"
log_info "1. Check that Terraform apply completed successfully"
log_info "2. Verify VM is running in Azure portal"
log_info "3. Check Network Security Group allows SSH (port 22)"
log_info "4. Wait for VM initialization to complete (cloud-init)"
log_info "5. Check GitHub Actions logs for detailed error messages"
