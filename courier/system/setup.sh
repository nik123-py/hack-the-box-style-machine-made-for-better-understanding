#!/bin/bash

# Main system setup script for HTB machine
# This script sets up the entire environment

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COURIER_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "[+] Starting Courier CI/CD Platform setup..."
echo "[+] Courier directory: $COURIER_DIR"

# Update system
echo "[+] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl git build-essential

# Install Node.js
echo "[+] Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Docker
echo "[+] Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Add runner user to docker group (for privilege escalation)
echo "[+] Setting up users..."
bash "$SCRIPT_DIR/users.sh"

# Ensure courier directory is in /home/runner (standard HTB location)
if [ "$COURIER_DIR" != "/home/runner/courier" ]; then
    echo "[+] Moving courier directory to /home/runner/courier..."
    mkdir -p /home/runner
    if [ -d "/home/runner/courier" ]; then
        rm -rf /home/runner/courier
    fi
    cp -r "$COURIER_DIR" /home/runner/courier
    COURIER_DIR="/home/runner/courier"
fi

# Setup web application
echo "[+] Setting up web application..."
cd "$COURIER_DIR/web"
npm install

# Setup CI scripts
echo "[+] Setting up CI scripts..."
chmod +x "$COURIER_DIR/ci"/*.sh

# Build Docker image for CI runner
echo "[+] Building CI Docker image..."
cd "$COURIER_DIR/ci"
docker build -t courier-ci:latest .
cd "$COURIER_DIR"

# Setup Git repository with keys
echo "[+] Setting up Git repository..."
cd "$COURIER_DIR/git"
if [ ! -d "internal-app.git" ]; then
    mkdir -p internal-app.git/keys
    cd internal-app.git
    
    # Generate RSA key pair for JWT signing
    # Private key for server, public key for verification
    openssl genrsa -out keys/private.pem 2048
    openssl rsa -in keys/private.pem -pubout -out keys/public.pem
    chmod 600 keys/private.pem
    chmod 644 keys/public.pem
    
    # Initialize git repo
    git init --bare
fi

# Create systemd service for web app
echo "[+] Creating systemd service..."
cat > /etc/systemd/system/courier-web.service << EOF
[Unit]
Description=Courier CI/CD Web Platform
After=network.target

[Service]
Type=simple
User=runner
WorkingDirectory=$COURIER_DIR/web
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable courier-web
systemctl start courier-web

# Setup flags (copy from template)
echo "[+] Setting up flags..."
cp "$COURIER_DIR/flags/user.txt" /home/runner/user.txt
cp "$COURIER_DIR/flags/root.txt" /root/root.txt
chown runner:runner /home/runner/user.txt
chmod 644 /home/runner/user.txt
chmod 600 /root/root.txt

echo "[+] Setup complete!"
echo "[+] Web application running on http://localhost:3000"
echo "[+] User: runner (in docker group)"
echo "[+] Flags: /home/runner/user.txt and /root/root.txt"

