# ============================================================================
# Stage 1: Builder - Install dependencies
# ============================================================================
FROM public.ecr.aws/docker/library/node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including dev dependencies for build)
RUN npm ci

# Copy application source
COPY src/ ./src/

# ============================================================================
# Stage 2: Dependencies - Production dependencies only
# ============================================================================
FROM public.ecr.aws/docker/library/node:20-alpine AS dependencies

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production && \
    npm cache clean --force

# ============================================================================
# Stage 3: Runtime - Distroless for security
# ============================================================================
FROM gcr.io/distroless/nodejs20-debian12:nonroot

# Set working directory
WORKDIR /app

# Copy production dependencies from dependencies stage
COPY --from=dependencies --chown=nonroot:nonroot /app/node_modules ./node_modules

# Copy package.json for version info
COPY --from=builder --chown=nonroot:nonroot /app/package*.json ./

# Copy application source
COPY --from=builder --chown=nonroot:nonroot /app/src ./src

# Use non-root user (already set by distroless :nonroot tag)
# USER 65532:65532 is implicit

# Expose application port
EXPOSE 3000

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    LOG_LEVEL=info

# Health check using standard /health endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["/nodejs/bin/node", "-e", "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"]

# Start application
CMD ["src/server.js"]