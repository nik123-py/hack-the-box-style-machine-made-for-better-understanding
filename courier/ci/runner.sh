#!/bin/bash

# CI Runner Script
# INTENTIONAL VULNERABILITY: Unsafe environment variable interpolation
# This script sources an environment file and executes BUILD_CMD without sanitization

ENV_FILE="/tmp/build.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "[!] No environment file found"
  exit 1
fi

echo "[+] CI Runner started"
echo "[+] Loading environment from $ENV_FILE"

# Load environment variables
# VULNERABILITY: Using 'source' loads user-controlled variables
set -a
source "$ENV_FILE"
set +a

echo "[+] Environment loaded"
echo "[+] Repository: $REPO_URL"
echo "[+] Event type: $EVENT_TYPE"
echo "[+] Build command: $BUILD_CMD"

# INTENTIONAL: Verbose output that helps attacker
echo "[+] CI Configuration:"
echo "    - Runner: bash"
echo "    - Working directory: $(pwd)"
echo "    - User: $(whoami)"
echo "    - Repository location: $REPO_URL"

# INTENTIONAL VULNERABILITY: Command injection
# BUILD_CMD is user-controlled and executed without sanitization
# An attacker can inject commands like: /bin/bash -i or nc -e /bin/bash
echo "[+] Executing build command..."
echo "[+] Starting build process..."

# Execute the build command unsafely
# This allows command injection when BUILD_CMD contains shell metacharacters
bash -c "$BUILD_CMD"

echo "[+] Build process completed"

