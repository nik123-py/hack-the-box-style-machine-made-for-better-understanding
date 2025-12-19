#!/bin/bash

# Build Docker image for CI runner
# This must be run as root or with sudo

set -e

echo "[+] Building CI runner Docker image..."

cd /home/runner/courier/ci

# Build the Docker image
docker build -t courier-ci:latest .

echo "[+] Docker image built successfully"
echo "[+] Image: courier-ci:latest"

