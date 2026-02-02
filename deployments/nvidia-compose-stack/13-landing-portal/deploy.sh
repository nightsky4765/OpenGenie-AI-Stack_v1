#!/bin/bash
# ============================================================================
# TigerAI Open-AI-Stack - Phase 13: Landing Portal Deployment
# ============================================================================
# Purpose: Deploy professional landing page with Nginx
# Tier: P1 Mission Critical
# Author: TigerAI Engineering
# ============================================================================

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ============================================================================
# Pre-flight Checks
# ============================================================================

log_info "Starting Phase 13: Landing Portal deployment..."

# Load environment variables from available sources
if [ -f .env ]; then
    source .env
elif [ -f ../tiger-tuning.env ]; then
    log_warning ".env not found, using tiger-tuning.env defaults."
    source <(sed 's/\r$//' ../tiger-tuning.env)
elif [ -f ../.env ]; then
    log_warning ".env not found, using parent .env defaults."
    source <(sed 's/\r$//' ../.env)
fi

# Check if ai_stack_net network exists
if ! docker network inspect ai_stack_net >/dev/null 2>&1; then
    log_warning "Network 'ai_stack_net' not found. Creating..."
    docker network create ai_stack_net
    log_success "Network created"
fi

# ============================================================================
# Deploy Landing Portal
# ============================================================================

log_info "Deploying Landing Portal..."

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^landing-portal$"; then
    log_warning "Stopping existing landing-portal container..."
    docker stop landing-portal >/dev/null 2>&1 || true
    docker rm landing-portal >/dev/null 2>&1 || true
fi

# Start the service
docker compose up -d

# Wait for container to be healthy
log_info "Waiting for container to start..."
sleep 3

# Verify deployment
if docker ps --format '{{.Names}}' | grep -q "^landing-portal$"; then
    log_success "Landing Portal deployed successfully!"
    
    # Display access information
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}Phase 13: Landing Portal - Deployment Complete${NC}"
    echo "============================================================================"
    echo ""
    echo "Access URLs:"
    echo "  🌐 Landing Page:  http://localhost:${LANDING_PORT:-80}"
    echo "  🔒 HTTPS (if configured): https://localhost:${LANDING_PORT_SSL:-443}"
    echo ""
    echo "Container Status:"
    docker ps --filter "name=landing-portal" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "Logs:"
    echo "  docker logs -f landing-portal"
    echo ""
    echo "============================================================================"
else
    log_error "Deployment failed! Container not running."
    echo ""
    echo "Check logs with:"
    echo "  docker compose logs"
    exit 1
fi

log_success "Phase 13 deployment complete! 🚀"
