// INTENTIONAL VULNERABILITY: Webhook secret leaked in frontend JavaScript
// This allows attackers to trigger webhooks without authentication
const WEBHOOK_SECRET = 'courier_webhook_secret_2024';

// Webhook trigger function (for demo purposes)
async function triggerWebhook(event, repository) {
  try {
    const response = await fetch('/webhook/trigger', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        secret: WEBHOOK_SECRET,
        event: event || 'push',
        repository: repository || { name: 'internal-app' }
      })
    });

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Webhook error:', error);
    return { error: error.message };
  }
}

// Display webhook results
function displayWebhookResults(data) {
  const resultsDiv = document.getElementById('webhook-results');
  if (resultsDiv) {
    resultsDiv.innerHTML = `
      <h3>Webhook Response:</h3>
      <pre>${JSON.stringify(data, null, 2)}</pre>
    `;
  }
}

// Auto-trigger on page load (for demo)
document.addEventListener('DOMContentLoaded', () => {
  console.log('[+] Courier CI/CD Platform loaded');
  console.log('[+] Webhook secret:', WEBHOOK_SECRET);
  
  // Optional: Auto-trigger webhook for demonstration
  // triggerWebhook('push', { name: 'internal-app' }).then(displayWebhookResults);
});

