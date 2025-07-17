#!/bin/bash
# =============================================================================
# Deployment Script for Habit Tracker Application
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
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
fi

# Configuration
APP_DIR="/opt/habit-tracker"
BACKUP_DIR="/opt/habit-tracker/backups"
LOG_DIR="/var/log/habit-tracker"
CONTAINER_NAME="habit-tracker-app"

# Create necessary directories
log "Creating application directories..."
sudo mkdir -p $APP_DIR $BACKUP_DIR $LOG_DIR
sudo chown $USER:$USER $APP_DIR $BACKUP_DIR
sudo chown $USER:$USER $LOG_DIR

# Load environment variables
if [ -f "/tmp/.env.prod" ]; then
    log "Loading environment variables..."
    source /tmp/.env.prod
else
    error "Environment file /tmp/.env.prod not found"
fi

# Validate required environment variables
required_vars=("CONTAINER_IMAGE" "SECRET_KEY" "DB_HOST" "DB_NAME" "DB_USER" "DB_PASSWORD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        error "Required environment variable $var is not set"
    fi
done

# Backup current deployment if exists
if sudo docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    log "Creating backup of current deployment..."
    BACKUP_FILE="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    # Export current container configuration
    sudo docker inspect $CONTAINER_NAME > "$BACKUP_DIR/container-config-$(date +%Y%m%d-%H%M%S).json"
    
    # Create application data backup if needed
    if sudo docker exec $CONTAINER_NAME test -d /app/instance 2>/dev/null; then
        sudo docker cp $CONTAINER_NAME:/app/instance "$BACKUP_DIR/instance-$(date +%Y%m%d-%H%M%S)"
    fi
    
    log "Backup created successfully"
fi

# Pull the latest image
log "Pulling latest container image: $CONTAINER_IMAGE"
if ! sudo docker pull $CONTAINER_IMAGE; then
    error "Failed to pull container image"
fi

# Stop and remove existing container
if sudo docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    log "Stopping existing container..."
    sudo docker stop $CONTAINER_NAME || warn "Failed to stop container gracefully"
fi

if sudo docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
    log "Removing existing container..."
    sudo docker rm $CONTAINER_NAME || warn "Failed to remove container"
fi

# Create docker-compose.yml for production
log "Creating production Docker Compose configuration..."
cat > $APP_DIR/docker-compose.yml << EOF
version: '3.8'

services:
  habit-tracker:
    image: $CONTAINER_IMAGE
    container_name: $CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      FLASK_ENV: production
      SECRET_KEY: "$SECRET_KEY"
      DB_HOST: "$DB_HOST"
      DB_PORT: "${DB_PORT:-5432}"
      DB_NAME: "$DB_NAME"
      DB_USER: "$DB_USER"
      DB_PASSWORD: "$DB_PASSWORD"
    volumes:
      - app_data:/app/instance
      - $LOG_DIR:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  app_data:
    driver: local
EOF

# Start the application using Docker Compose
log "Starting application with Docker Compose..."
cd $APP_DIR
if ! sudo docker-compose up -d; then
    error "Failed to start application"
fi

# Wait for application to be healthy
log "Waiting for application to become healthy..."
TIMEOUT=120
COUNTER=0

while [ $COUNTER -lt $TIMEOUT ]; do
    if sudo docker-compose ps | grep -q "Up (healthy)"; then
        log "Application is healthy!"
        break
    elif sudo docker-compose ps | grep -q "Up (unhealthy)"; then
        warn "Application is unhealthy, checking logs..."
        sudo docker-compose logs --tail=20
        sleep 5
    elif sudo docker-compose ps | grep -q "Up"; then
        log "Application is starting... (${COUNTER}s)"
        sleep 5
    else
        error "Application failed to start"
    fi
    
    COUNTER=$((COUNTER + 5))
done

if [ $COUNTER -ge $TIMEOUT ]; then
    error "Application failed to become healthy within $TIMEOUT seconds"
fi

# Test application endpoints
log "Testing application endpoints..."
if curl -f http://localhost:5000/ > /dev/null 2>&1; then
    log "Application is responding correctly"
else
    warn "Application health check failed, checking logs..."
    sudo docker-compose logs --tail=50
    error "Application is not responding"
fi

# Clean up old Docker images (keep last 3)
log "Cleaning up old Docker images..."
sudo docker image prune -f
OLD_IMAGES=$(sudo docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | grep "ghcr.io.*habit-tracker" | tail -n +4 | awk '{print $1}')
if [ ! -z "$OLD_IMAGES" ]; then
    echo "$OLD_IMAGES" | xargs -r sudo docker rmi || warn "Failed to remove some old images"
fi

# Update Nginx configuration if needed
log "Checking Nginx configuration..."
if ! sudo nginx -t; then
    warn "Nginx configuration test failed"
else
    log "Reloading Nginx configuration..."
    sudo systemctl reload nginx
fi

# Set up log rotation for application logs
log "Setting up log rotation..."
sudo tee /etc/logrotate.d/habit-tracker > /dev/null << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        sudo docker-compose -f $APP_DIR/docker-compose.yml restart habit-tracker
    endscript
}
EOF

# Clean up temporary files
log "Cleaning up temporary files..."
rm -f /tmp/.env.prod

# Display deployment summary
log "Deployment completed successfully!"
echo ""
echo "=== Deployment Summary ==="
echo "Container Image: $CONTAINER_IMAGE"
echo "Application Directory: $APP_DIR"
echo "Log Directory: $LOG_DIR"
echo "Backup Directory: $BACKUP_DIR"
echo ""
echo "=== Service Status ==="
sudo docker-compose -f $APP_DIR/docker-compose.yml ps
echo ""
echo "=== Application URLs ==="
echo "Local: http://localhost:5000"
if [ ! -z "$DOMAIN_NAME" ]; then
    echo "Domain: https://$DOMAIN_NAME"
fi
echo ""
log "Deployment script completed successfully!"
