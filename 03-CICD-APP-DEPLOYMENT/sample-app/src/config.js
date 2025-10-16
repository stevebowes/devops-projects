// Configuration with environment variables and external secrets
module.exports = {
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development',
  logLevel: process.env.LOG_LEVEL || 'info',
  appName: 'sample-app',
  version: process.env.APP_VERSION || '1.0.0',
  
  // External secrets from AWS Secrets Manager (via External Secrets Operator)
  databaseUrl: process.env.DATABASE_URL || null,
  apiKey: process.env.API_KEY || null
};