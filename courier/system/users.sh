#!/bin/bash

# User setup script
# Creates the runner user and adds to docker group

set -e

# Create runner user if it doesn't exist
if ! id "runner" &>/dev/null; then
    echo "[+] Creating runner user..."
    useradd -m -s /bin/bash runner
    
    # Set a password (not used for SSH, but good practice)
    echo "runner:runner123" | chpasswd
fi

# Add runner to docker group (INTENTIONAL: for privilege escalation)
echo "[+] Adding runner to docker group..."
usermod -aG docker runner

# Set up home directory permissions
chown -R runner:runner /home/runner

echo "[+] User setup complete"
echo "[+] Runner user created and added to docker group"

