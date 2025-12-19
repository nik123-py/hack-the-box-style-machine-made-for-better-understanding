# Courier CI/CD Platform - Internal Documentation

## Overview
This is an HTB machine demonstrating a realistic CI/CD automation abuse scenario.

## Attack Chain
1. Webhook secret leaked in frontend JavaScript
2. Webhook triggers CI job with verbose logging
3. Logs reveal internal Git repo and RSA public key
4. JWT algorithm confusion (RS256 → HS256) to forge admin token
5. Admin build endpoint allows command injection via environment variable
6. Gain shell as runner user
7. Docker group membership allows container escape to root

## Vulnerabilities
- CWE-798: Hardcoded webhook secret in frontend
- CWE-532: Information disclosure via verbose CI logs
- CVE-2016-10555: JWT algorithm confusion
- CWE-78: Command injection in CI runner
- CWE-269: Privilege escalation via Docker group

## Setup Instructions
1. Run `system/setup.sh` as root
2. Service will auto-start on port 3000
3. Flags are in `/home/runner/user.txt` and `/root/root.txt`

## Testing
- Webhook: POST /webhook/trigger with secret from main.js
- Admin: POST /admin/build with forged JWT token
- Command injection: Use BUILD_CMD with shell metacharacters
- Docker escape: docker run -v /:/mnt ubuntu chroot /mnt bash

## Security Notes
- Only one RCE vector (admin build endpoint)
- Only one privesc vector (docker group)
- No SUID binaries
- No writable system files
- No kernel exploits
- Deterministic and stable

