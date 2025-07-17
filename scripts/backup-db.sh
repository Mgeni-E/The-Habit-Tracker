#!/bin/bash

# =============================================================================
# Docker PostgreSQL Backup Script
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
BACKUP_DIR="/opt/habit-tracker/backups"
CONTAINER_NAME="habit-tracker-postgres"
DB_NAME="habit_tracker"
DB_USER="habitadmin"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"
RETENTION_DAYS=7

# Create backup directory
sudo mkdir -p "$BACKUP_DIR"

log_info "Starting PostgreSQL backup..."

# Check if container is running
if ! sudo docker ps | grep -q "$CONTAINER_NAME"; then
    log_error "PostgreSQL container '$CONTAINER_NAME' is not running"
    exit 1
fi

# Create database backup
log_info "Creating database backup..."
if sudo docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"; then
    log_success "Database backup created: $BACKUP_FILE"
else
    log_error "Failed to create database backup"
    exit 1
fi

# Compress backup
log_info "Compressing backup..."
if gzip "$BACKUP_FILE"; then
    BACKUP_FILE="${BACKUP_FILE}.gz"
    log_success "Backup compressed: $BACKUP_FILE"
else
    log_warning "Failed to compress backup"
fi

# Set proper permissions
sudo chown $(whoami):$(whoami) "$BACKUP_FILE"
sudo chmod 600 "$BACKUP_FILE"

# Clean up old backups
log_info "Cleaning up old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "postgres_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

# Show backup info
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log_success "Backup completed successfully!"
log_info "Backup file: $BACKUP_FILE"
log_info "Backup size: $BACKUP_SIZE"

# List recent backups
log_info "Recent backups:"
ls -lah "$BACKUP_DIR"/postgres_backup_*.sql.gz 2>/dev/null | tail -5 || log_warning "No previous backups found"

log_info "Backup process completed!"
