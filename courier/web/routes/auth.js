const express = require('express');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const router = express.Router();

// Load RSA private key for signing
const privateKeyPath = path.join(__dirname, '../../git/internal-app.git/keys/private.pem');
let privateKey = null;

try {
  privateKey = fs.readFileSync(privateKeyPath, 'utf8');
} catch (err) {
  console.error('[!] Error: Private key not found');
}

// Login endpoint (for reference - not directly exploitable)
router.post('/login', (req, res) => {
  const { username, password } = req.body;

  // Simple hardcoded credentials for demo
  // In real scenario, attacker would need to exploit JWT to bypass this
  if (username === 'admin' && password === 'admin123') {
    const token = jwt.sign(
      { 
        username: 'admin',
        role: 'admin',
        iat: Math.floor(Date.now() / 1000)
      },
      privateKey,
      { algorithm: 'RS256' }
    );

    return res.json({ token });
  }

  res.status(401).json({ error: 'Invalid credentials' });
});

module.exports = router;

