const express = require('express');
const config = require('./config');

// Initialize Express app
const app = express();
app.use(express.json());

// Health check endpoint (liveness probe)
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString() 
  });
});

// Readiness check endpoint
app.get('/ready', (req, res) => {
  res.status(200).json({ 
    status: 'ready', 
    timestamp: new Date().toISOString() 
  });
});

// Secrets health check - validates external secrets are loaded
app.get('/api/health/secrets', (req, res) => {
  const secretsStatus = {
    databaseUrl: !!config.databaseUrl,
    apiKey: !!config.apiKey,
    status: 'healthy'
  };
  
  if (!config.databaseUrl || !config.apiKey) {
    secretsStatus.status = 'degraded';
    secretsStatus.message = 'Some secrets are missing - running in demo mode';
    console.warn('External secrets not fully loaded', secretsStatus);
  }
  
  res.status(200).json(secretsStatus);
});

// Simple API info endpoint
app.get('/', (req, res) => {
  res.json({
    name: config.appName,
    version: config.version,
    environment: config.env,
    endpoints: {
      health: '/health',
      ready: '/ready',
      secretsHealth: '/api/health/secrets',
      status: '/api/status'
    }
  });
});

// Simple status endpoint
app.get('/api/status', (req, res) => {
  res.json({
    message: 'Sample app is running',
    timestamp: new Date().toISOString(),
    environment: config.env,
    hasSecrets: !!(config.databaseUrl && config.apiKey)
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

// Graceful shutdown
const server = app.listen(config.port, () => {
  console.log(`Server started on port ${config.port} in ${config.env} mode`);
  console.log(`External secrets loaded: ${!!(config.databaseUrl && config.apiKey)}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received, closing server gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

module.exports = app;