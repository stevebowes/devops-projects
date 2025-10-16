# ============================================================================
# Simple Node.js Application Container
# ============================================================================
FROM public.ecr.aws/docker/library/node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy application source
COPY src/ ./src/

# Create non-root user
RUN addgroup -g 1000 -S nodejs && \
    adduser -S nodejs -u 1000

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose application port
EXPOSE 3000

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    LOG_LEVEL=info

# Health check using standard /health endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "src/server.js"]