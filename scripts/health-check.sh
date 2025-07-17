#!/bin/bash
# =============================================================================
# Health Check Script for Habit Tracker Application
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Configuration
APP_DIR="/opt/habit-tracker"
CONTAINER_NAME="habit-tracker-app"
HEALTH_CHECK_URL="http://localhost:5000/"
TIMEOUT=30

# Health check results
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Function to run a check
run_check() {
    local check_name="$1"
    local check_command="$2"
    local is_critical="${3:-true}"
    
    info "Running check: $check_name"
    
    if eval "$check_command" > /dev/null 2>&1; then
        log "✓ $check_name: PASSED"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            error "✗ $check_name: FAILED"
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
        else
            warn "⚠ $check_name: WARNING"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

# Function to get container status
get_container_status() {
    if sudo docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$CONTAINER_NAME"; then
        sudo docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$CONTAINER_NAME" | awk '{print $2}'
    else
        echo "Not running"
    fi
}

# Function to get container health
get_container_health() {
    local health=$(sudo docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
    echo "$health"
}

echo "========================================"
echo "  Habit Tracker Health Check Report"
echo "========================================"
echo "Timestamp: $(date)"
echo "Server: $(hostname)"
echo "========================================"

# System checks
echo ""
info "=== SYSTEM CHECKS ==="

run_check "System uptime" "uptime"
run_check "Disk space (root)" "[ \$(df / | tail -1 | awk '{print \$5}' | sed 's/%//') -lt 90 ]"
run_check "Memory usage" "[ \$(free | grep Mem | awk '{printf \"%.0f\", \$3/\$2 * 100.0}') -lt 90 ]"
run_check "Docker service" "systemctl is-active --quiet docker"
run_check "Nginx service" "systemctl is-active --quiet nginx"

# Docker checks
echo ""
info "=== DOCKER CHECKS ==="

run_check "Docker daemon" "sudo docker info"
run_check "Container exists" "sudo docker ps -a --format '{{.Names}}' | grep -q '^${CONTAINER_NAME}$'"

if sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    CONTAINER_STATUS=$(get_container_status)
    CONTAINER_HEALTH=$(get_container_health)
    
    info "Container Status: $CONTAINER_STATUS"
    info "Container Health: $CONTAINER_HEALTH"
    
    run_check "Container running" "sudo docker ps --format '{{.Names}}' | grep -q '^${CONTAINER_NAME}$'"
    
    if [ "$CONTAINER_HEALTH" != "unknown" ]; then
        run_check "Container healthy" "[ '$CONTAINER_HEALTH' = 'healthy' ]"
    fi
    
    # Check container logs for errors
    if sudo docker logs --tail=50 "$CONTAINER_NAME" 2>&1 | grep -qi "error\|exception\|traceback"; then
        warn "Recent errors found in container logs"
        WARNINGS=$((WARNINGS + 1))
    else
        log "✓ No recent errors in container logs"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    fi
fi

# Network checks
echo ""
info "=== NETWORK CHECKS ==="

run_check "Port 5000 listening" "netstat -tuln | grep -q ':5000 '"
run_check "Port 80 listening" "netstat -tuln | grep -q ':80 '"
run_check "Port 443 listening" "netstat -tuln | grep -q ':443 '" false

# Application checks
echo ""
info "=== APPLICATION CHECKS ==="

run_check "Application responding" "curl -f --max-time $TIMEOUT '$HEALTH_CHECK_URL'"
run_check "Application returns 200" "[ \$(curl -s -o /dev/null -w '%{http_code}' --max-time $TIMEOUT '$HEALTH_CHECK_URL') -eq 200 ]"

# Check if application is accessible via Nginx
if curl -f --max-time $TIMEOUT "http://localhost/" > /dev/null 2>&1; then
    log "✓ Application accessible via Nginx"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    error "✗ Application not accessible via Nginx"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Database connectivity check (if container is running)
if sudo docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo ""
    info "=== DATABASE CHECKS ==="
    
    # Check database connection from within the container
    if sudo docker exec "$CONTAINER_NAME" python -c "
import os
import psycopg2
try:
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST'),
        port=os.environ.get('DB_PORT', 5432),
        database=os.environ.get('DB_NAME'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASSWORD')
    )
    conn.close()
    print('Database connection successful')
except Exception as e:
    print(f'Database connection failed: {e}')
    exit(1)
" > /dev/null 2>&1; then
        log "✓ Database connectivity: PASSED"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        error "✗ Database connectivity: FAILED"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
fi

# SSL/TLS checks (if HTTPS is configured)
echo ""
info "=== SSL/TLS CHECKS ==="

if netstat -tuln | grep -q ':443 '; then
    run_check "SSL certificate valid" "echo | openssl s_client -connect localhost:443 -servername localhost 2>/dev/null | openssl x509 -noout -dates" false
    run_check "HTTPS redirect working" "[ \$(curl -s -o /dev/null -w '%{http_code}' http://localhost/) -eq 301 ]" false
else
    warn "HTTPS not configured"
    WARNINGS=$((WARNINGS + 1))
fi

# Security checks
echo ""
info "=== SECURITY CHECKS ==="

run_check "UFW firewall active" "ufw status | grep -q 'Status: active'" false
run_check "Fail2ban service" "systemctl is-active --quiet fail2ban" false
run_check "Automatic updates enabled" "systemctl is-enabled --quiet unattended-upgrades" false

# Performance checks
echo ""
info "=== PERFORMANCE CHECKS ==="

# Check response time
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' --max-time $TIMEOUT "$HEALTH_CHECK_URL" || echo "timeout")
if [ "$RESPONSE_TIME" != "timeout" ] && [ "$(echo "$RESPONSE_TIME < 5.0" | bc -l 2>/dev/null || echo 0)" -eq 1 ]; then
    log "✓ Response time: ${RESPONSE_TIME}s (good)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [ "$RESPONSE_TIME" != "timeout" ]; then
    warn "⚠ Response time: ${RESPONSE_TIME}s (slow)"
    WARNINGS=$((WARNINGS + 1))
else
    error "✗ Response time: timeout"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Summary
echo ""
echo "========================================"
echo "           HEALTH CHECK SUMMARY"
echo "========================================"
echo "Checks Passed: $CHECKS_PASSED"
echo "Checks Failed: $CHECKS_FAILED"
echo "Warnings: $WARNINGS"
echo "========================================"

if [ $CHECKS_FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        log "🎉 All health checks passed! System is healthy."
        exit 0
    else
        warn "⚠️  Health checks passed with $WARNINGS warnings."
        exit 0
    fi
else
    error "❌ $CHECKS_FAILED critical health checks failed!"
    exit 1
fi
