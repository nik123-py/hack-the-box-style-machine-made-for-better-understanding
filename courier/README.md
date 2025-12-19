# Courier - HTB Machine

A Medium-difficulty Linux machine demonstrating CI/CD automation abuse, JWT misconfiguration, and Docker privilege escalation.

## Quick Start

1. Copy the `courier/` directory to an Ubuntu 22.04 VM
2. Run as root: `bash courier/DEPLOY.sh`
3. The web application will start on port 3000
4. Flags are located at `/home/runner/user.txt` and `/root/root.txt`

## Attack Chain

1. **Webhook Secret Discovery** - Find hardcoded secret in frontend JavaScript
2. **Information Disclosure** - Trigger webhook to leak Git repo URL and RSA public key
3. **JWT Algorithm Confusion** - Forge admin token using CVE-2016-10555
4. **Command Injection** - Exploit admin build endpoint for RCE
5. **Docker Escape** - Use docker group membership to escalate to root

## Documentation

- `EXPLOIT_GUIDE.md` - Detailed exploitation walkthrough
- `HTB_SUBMISSION.md` - Submission notes for HTB reviewers
- `QUICK_REFERENCE.md` - Quick attack chain reference
- `README_INTERNAL.txt` - Internal development notes

## Structure

```
courier/
├── web/              # Node.js Express application
│   ├── app.js        # Main application
│   ├── middleware/   # JWT authentication
│   ├── routes/       # API endpoints
│   ├── public/       # Frontend (leaks webhook secret)
│   └── views/        # EJS templates
├── ci/               # CI/CD runner scripts
│   ├── runner.sh     # Vulnerable runner (command injection)
│   ├── build.sh      # Standard build script
│   └── Dockerfile    # CI container
├── git/              # Internal Git repository (created during setup)
├── flags/            # Flag templates
├── system/           # Setup scripts
└── DEPLOY.sh         # Main deployment script
```

## Security Notes

- Only one RCE vector (admin build endpoint)
- Only one privesc vector (docker group)
- No kernel exploits, SUID binaries, or writable system files
- Deterministic and stable
- Follows HTB submission guidelines

## Testing

### Quick Test
```bash
# Run automated test script
bash test_attack.sh TARGET_IP
```

### Manual Testing
After deployment, test the attack chain:

1. Visit `http://TARGET_IP:3000`
2. Inspect page source to find webhook secret
3. Follow the exploitation guide in `TESTING.md`

### Testing Tools
- `test_attack.sh` - Automated basic tests
- `forge_jwt.py` - JWT token forger (algorithm confusion)
- `test_command_injection.py` - Command injection tester

See `TESTING.md` for detailed step-by-step instructions.

## Requirements

- Ubuntu 22.04
- Root access for initial setup
- Internet connection (for package installation)

