const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

// Load RSA public key for verification
const publicKeyPath = path.join(__dirname, '../../git/internal-app.git/keys/public.pem');
let publicKey = null;

try {
  publicKey = fs.readFileSync(publicKeyPath, 'utf8');
} catch (err) {
  console.error('[!] Warning: Public key not found, JWT verification may fail');
}

// INTENTIONAL VULNERABILITY: Algorithm confusion
// The verify function does not explicitly enforce RS256 algorithm
// This allows attackers to forge tokens using HS256 with the public key as secret
const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '') || 
                req.cookies?.token || 
                req.body?.token;

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    // VULNERABILITY: No algorithm parameter specified
    // jsonwebtoken will accept tokens signed with ANY algorithm
    // including HS256 when the public key is used as the secret
    const decoded = jwt.verify(token, publicKey);
    
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Admin-only middleware
const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

module.exports = { authenticate, requireAdmin };

