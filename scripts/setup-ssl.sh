#!/bin/bash
# =============================================================================
# SSL Certificate Setup Script for Habit Tracker
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

# Check required parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <domain_name> <email>"
    echo "Example: $0 example.com admin@example.com"
    exit 1
fi

DOMAIN_NAME="$1"
EMAIL="$2"

log "Setting up SSL certificate for domain: $DOMAIN_NAME"

# Validate domain format
if ! echo "$DOMAIN_NAME" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$'; then
    error "Invalid domain name format: $DOMAIN_NAME"
fi

# Validate email format
if ! echo "$EMAIL" | grep -qE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'; then
    error "Invalid email format: $EMAIL"
fi

# Check if Nginx is installed and running
if ! systemctl is-active --quiet nginx; then
    error "Nginx is not running. Please start Nginx first."
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    log "Installing certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

# Backup current Nginx configuration
NGINX_CONFIG="/etc/nginx/sites-available/habit-tracker"
BACKUP_CONFIG="/etc/nginx/sites-available/habit-tracker.backup.$(date +%Y%m%d-%H%M%S)"

if [ -f "$NGINX_CONFIG" ]; then
    log "Backing up current Nginx configuration..."
    cp "$NGINX_CONFIG" "$BACKUP_CONFIG"
else
    error "Nginx configuration file not found: $NGINX_CONFIG"
fi

# Update Nginx configuration with domain name
log "Updating Nginx configuration with domain name..."
sed -i "s/server_name _;/server_name $DOMAIN_NAME;/g" "$NGINX_CONFIG"

# Test Nginx configuration
log "Testing Nginx configuration..."
if ! nginx -t; then
    error "Nginx configuration test failed. Restoring backup..."
    cp "$BACKUP_CONFIG" "$NGINX_CONFIG"
    nginx -t
    exit 1
fi

# Reload Nginx
log "Reloading Nginx..."
systemctl reload nginx

# Check if domain resolves to this server
log "Checking DNS resolution for $DOMAIN_NAME..."
DOMAIN_IP=$(dig +short "$DOMAIN_NAME" | tail -n1)
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    warn "Domain $DOMAIN_NAME resolves to $DOMAIN_IP but server IP is $SERVER_IP"
    warn "SSL certificate may fail if DNS is not properly configured"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Obtain SSL certificate
log "Obtaining SSL certificate from Let's Encrypt..."
if certbot --nginx -d "$DOMAIN_NAME" --email "$EMAIL" --agree-tos --non-interactive --redirect; then
    log "SSL certificate obtained successfully!"
else
    error "Failed to obtain SSL certificate"
fi

# Test SSL configuration
log "Testing SSL configuration..."
if curl -I "https://$DOMAIN_NAME" | grep -q "HTTP/"; then
    log "SSL certificate is working correctly!"
else
    warn "SSL certificate test failed"
fi

# Set up automatic renewal
log "Setting up automatic certificate renewal..."
if ! crontab -l | grep -q certbot; then
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    log "Automatic renewal cron job added"
else
    log "Automatic renewal is already configured"
fi

# Test automatic renewal
log "Testing automatic renewal..."
certbot renew --dry-run

# Display certificate information
log "SSL certificate setup completed successfully!"
echo ""
echo "=== Certificate Information ==="
certbot certificates
echo ""
echo "=== Security Headers Test ==="
curl -I "https://$DOMAIN_NAME" | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|X-XSS-Protection)"
echo ""
echo "=== Application URLs ==="
echo "HTTP (redirects to HTTPS): http://$DOMAIN_NAME"
echo "HTTPS: https://$DOMAIN_NAME"
echo ""
log "SSL setup script completed successfully!"

# Clean up
rm -f "$BACKUP_CONFIG"
