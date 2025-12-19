#!/bin/bash

# Complete deployment script for HTB machine
# Run this as root on a fresh Ubuntu 22.04 system

set -e

echo "=========================================="
echo "Courier CI/CD Platform - HTB Machine"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "[!] Please run as root"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Make all scripts executable
echo "[+] Making scripts executable..."
chmod +x system/*.sh
chmod +x ci/*.sh

# Run setup
echo "[+] Running system setup..."
bash system/setup.sh

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Web application: http://localhost:3000"
echo "User flag: /home/runner/user.txt"
echo "Root flag: /root/root.txt"
echo ""
echo "To test the machine:"
echo "1. Visit http://localhost:3000"
echo "2. Inspect JavaScript to find webhook secret"
echo "3. Follow the attack chain in EXPLOIT_GUIDE.md"
echo ""

