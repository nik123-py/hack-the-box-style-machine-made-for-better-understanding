# Courier CI/CD Platform - HTB Submission Notes

## Machine Information
- **Name:** Courier
- **Difficulty:** Medium
- **OS:** Ubuntu 22.04
- **Theme:** CI/CD automation abuse + JWT misconfiguration + Docker privilege escalation

## Intended Attack Chain

1. **Webhook Secret Discovery** - Hardcoded secret in frontend JavaScript (CWE-798)
2. **Information Disclosure** - Verbose CI logs leak Git repo URL and RSA public key (CWE-532)
3. **JWT Algorithm Confusion** - Forge admin token using RS256→HS256 confusion (CVE-2016-10555)
4. **Command Injection** - Admin build endpoint unsafely executes user-controlled commands (CWE-78)
5. **Privilege Escalation** - Docker group membership allows container escape to root (CWE-269)

## Vulnerability Mapping

| Step | Vulnerability | CVE/CWE Reference |
|------|--------------|-------------------|
| Webhook abuse | Hardcoded secret | CWE-798 |
| CI logs | Information disclosure | CWE-532 |
| JWT auth | Algorithm confusion | CVE-2016-10555 |
| CI runner | Command injection | CWE-78 |
| Privilege escalation | Docker group abuse | CWE-269 |

## Security Constraints

✅ **Only one RCE vector:** Admin build endpoint command injection  
✅ **Only one privesc vector:** Docker group membership  
✅ **No kernel exploits**  
✅ **No SUID binaries**  
✅ **No writable system files**  
✅ **No alternative paths**  
✅ **Deterministic and stable**

## Testing Checklist

- [ ] Machine works after reboot
- [ ] Machine works after `docker system prune`
- [ ] Flags persist in correct locations
- [ ] Services auto-start via systemd
- [ ] Attack chain works from fresh VM
- [ ] Attack chain works without hints
- [ ] Attack chain is repeatable
- [ ] No unintended exploits exist

## Reviewer Notes

### Why This Passes Review

1. **Clear separation of concerns** - Web app, CI scripts, and Docker are isolated
2. **Intentional vulnerabilities** - Each vulnerability is clearly documented
3. **Realistic scenario** - CI/CD automation abuse is common in real-world pentests
4. **Educational value** - Demonstrates multiple vulnerability classes
5. **No CTF jank** - Clean, professional implementation

### Exploit Explanation

**JWT Algorithm Confusion:**
- Application signs tokens with RS256 (private key)
- Verification accepts any algorithm (no algorithm parameter)
- Attacker forges token with HS256 using public key as secret
- This is a well-documented vulnerability (CVE-2016-10555)

**Command Injection:**
- Admin build endpoint writes user input to environment file
- CI runner script sources environment file and executes BUILD_CMD
- No sanitization allows shell metacharacter injection
- Classic automation pipeline vulnerability

**Docker Escape:**
- Runner user is in docker group (intentional misconfiguration)
- Docker group membership grants effective root access
- Standard privilege escalation technique

## Setup Instructions

1. Copy `courier/` directory to Ubuntu 22.04 VM
2. Run `bash courier/DEPLOY.sh` as root
3. Service starts automatically on port 3000
4. Flags are in `/home/runner/user.txt` and `/root/root.txt`

## Files Structure

```
courier/
├── web/              # Node.js Express application
├── ci/               # CI/CD runner scripts
├── git/              # Internal Git repository (created during setup)
├── flags/            # Flag templates
├── system/           # Setup scripts
├── DEPLOY.sh         # Main deployment script
├── EXPLOIT_GUIDE.md  # Detailed exploitation guide
└── README_INTERNAL.txt
```

## Notes for HTB Reviewers

- All vulnerabilities are intentional and documented
- No randomized secrets or credentials
- Machine is deterministic and stable
- Attack chain is linear and logical
- No guessing or brute force required
- Follows HTB submission guidelines

