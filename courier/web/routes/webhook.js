const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const router = express.Router();

// INTENTIONAL VULNERABILITY: Hardcoded webhook secret
// This secret is also leaked in the frontend JavaScript
const WEBHOOK_SECRET = 'courier_webhook_secret_2024';

// Webhook endpoint - triggers CI job
router.post('/trigger', (req, res) => {
  const { secret, event, repository } = req.body;

  // Verify secret (but it's hardcoded and leaked)
  if (secret !== WEBHOOK_SECRET) {
    return res.status(401).json({ error: 'Invalid webhook secret' });
  }

  console.log(`[+] Webhook triggered: ${event} for ${repository?.name || 'unknown'}`);

  // Trigger CI build
  const ciScript = path.join(__dirname, '../../ci/runner.sh');
  
  // Create environment file for CI runner
  const envFile = '/tmp/build.env';
  const envContent = `BUILD_CMD=/home/runner/ci/build.sh
REPO_URL=file:///home/runner/git/internal-app.git
EVENT_TYPE=${event || 'push'}
`;

  fs.writeFileSync(envFile, envContent);

  // INTENTIONAL: Leak public key in logs (for JWT algorithm confusion)
  const publicKeyPath = path.join(__dirname, '../../git/internal-app.git/keys/public.pem');
  let publicKey = null;
  try {
    publicKey = fs.readFileSync(publicKeyPath, 'utf8');
  } catch (err) {
    console.error('[!] Public key not found');
  }

  // Execute CI runner (this will leak verbose logs)
  exec(`bash ${ciScript}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`[!] CI Error: ${error.message}`);
    }

    // INTENTIONAL: Verbose logging that leaks information
    // This includes the repo URL and public key needed for JWT attack
    const logs = {
      stdout: stdout.toString(),
      stderr: stderr.toString(),
      repo: repository?.name || 'internal-app',
      repoUrl: 'file:///home/runner/git/internal-app.git',
      // INTENTIONAL VULNERABILITY: Public key leaked in logs
      // This allows JWT algorithm confusion attack
      publicKey: publicKey,
      keyLocation: publicKeyPath,
      timestamp: new Date().toISOString(),
      buildInfo: {
        environment: 'production',
        runner: 'bash',
        dockerImage: 'courier-ci:latest'
      }
    };

    // Return verbose logs (this is the information disclosure)
    res.json({
      status: 'success',
      message: 'CI job triggered',
      logs: logs
    });
  });
});

module.exports = router;

