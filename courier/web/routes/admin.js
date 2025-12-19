const express = require('express');
const { authenticate, requireAdmin } = require('../middleware/auth');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const router = express.Router();

// All admin routes require authentication
router.use(authenticate);
router.use(requireAdmin);

// Admin build trigger endpoint
// INTENTIONAL VULNERABILITY: Command injection via environment variable
router.post('/build', (req, res) => {
  const { buildCommand } = req.body;

  if (!buildCommand) {
    return res.status(400).json({ error: 'buildCommand is required' });
  }

  console.log(`[+] Admin build triggered: ${buildCommand}`);

  // Create environment file with user-controlled command
  const envFile = '/tmp/build.env';
  const envContent = `BUILD_CMD=${buildCommand}
REPO_URL=file:///home/runner/git/internal-app.git
EVENT_TYPE=manual
`;

  fs.writeFileSync(envFile, envContent);

  // Execute CI runner
  // The runner.sh script will source this env file and execute BUILD_CMD unsafely
  // INTENTIONAL: This runs as the runner user (from systemd service)
  // Command injection here gives shell as runner user (member of docker group)
  const ciScript = path.join(__dirname, '../../ci/runner.sh');
  
  exec(`bash ${ciScript}`, { timeout: 30000 }, (error, stdout, stderr) => {
    const response = {
      status: error ? 'error' : 'success',
      stdout: stdout.toString(),
      stderr: stderr.toString(),
      message: error ? 'Build failed' : 'Build completed'
    };

    res.json(response);
  });
});

// Get build status
router.get('/status', (req, res) => {
  res.json({
    status: 'operational',
    version: '1.0.0'
  });
});

module.exports = router;

