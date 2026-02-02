#!/bin/bash
# ============================================================================
# Landing Portal - Deployment Verification Script
# ============================================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================================================"
echo "Phase 13: Landing Portal - Deployment Verification"
echo "============================================================================"
echo ""

# Check container status
echo -n "Checking container status... "
if docker ps --format '{{.Names}}' | grep -q "^landing-portal$"; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    exit 1
fi

# Check network connectivity
echo -n "Checking network connectivity... "
if docker exec landing-portal ping -c 1 system-api-bridge >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected to ai_stack_net${NC}"
else
    echo -e "${YELLOW}⚠ Cannot reach Phase 12 Gateway${NC}"
fi

# Check Nginx configuration
echo -n "Checking Nginx configuration... "
if docker exec landing-portal nginx -t >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Valid${NC}"
else
    echo -e "${RED}✗ Invalid${NC}"
    exit 1
fi

# Check HTML files
echo -n "Checking HTML files... "
if docker exec landing-portal test -f /usr/share/nginx/html/index.html; then
    echo -e "${GREEN}✓ Present${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    exit 1
fi

# Test HTTP endpoint
echo -n "Testing HTTP endpoint... "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:${LANDING_PORT:-80} | grep -q "200"; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
    exit 1
fi

# Display access information
echo ""
echo "============================================================================"
echo -e "${GREEN}All checks passed!${NC}"
echo "============================================================================"
echo ""
echo "Access your Landing Portal at:"
echo "  🌐 http://localhost:${LANDING_PORT:-80}"
echo ""
echo "Container logs:"
echo "  docker logs -f landing-portal"
echo ""
echo "============================================================================"
