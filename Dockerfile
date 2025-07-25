# Multi-stage Dockerfile for Material Dashboard 2 React Application
# Security-focused build with non-root user and vulnerability mitigations

# Build stage
FROM node:18.20.4-alpine3.20 AS builder

# Install security updates and essential packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Create non-root user for build process
RUN addgroup -g 1001 -S nodejs && \
    adduser -S reactapp -u 1001 -G nodejs

# Set working directory
WORKDIR /app

# Copy package files first (better Docker layer caching)
COPY package*.json ./

# Install ALL dependencies (including dev dependencies for build)
# Use npm ci if package-lock.json exists, otherwise use npm install
RUN if [ -f package-lock.json ]; then \
        npm ci --no-audit --no-fund; \
    else \
        npm install --no-audit --no-fund; \
    fi && \
    npm cache clean --force

# Copy source code
COPY --chown=1001:1001 . .

# Set build environment variables
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV GENERATE_SOURCEMAP=false
ENV CI=true
ENV SKIP_PREFLIGHT_CHECK=true

# Build the application (stay as root for build process)
RUN echo "Starting build process..." && \
    npm --version && \
    node --version && \
    ls -la node_modules/.bin/react-scripts || echo "react-scripts not found in .bin" && \
    npm run build

# Remove source code and dev dependencies after build
RUN rm -rf src/ public/ node_modules/

# Production stage
FROM nginx:1.27.0-alpine3.19 AS production

# Install security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    ca-certificates \
    curl \
    && rm -rf /var/cache/apk/*

# Create non-root user (nginx group already exists, so we'll use it)
RUN adduser -S reactapp -u 1001 -G nginx

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built application from builder stage
COPY --from=builder --chown=1001:1001 /app/build /usr/share/nginx/html

# Create custom nginx configuration for security
RUN mkdir -p /etc/nginx/conf.d
COPY --chown=1001:1001 nginx.conf /etc/nginx/conf.d/default.conf

# Set proper permissions (get nginx group ID and use it)
RUN NGINX_GID=$(getent group nginx | cut -d: -f3) && \
    chown -R 1001:$NGINX_GID /usr/share/nginx/html && \
    chown -R 1001:$NGINX_GID /var/cache/nginx && \
    chown -R 1001:$NGINX_GID /var/log/nginx && \
    chown -R 1001:$NGINX_GID /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R 1001:$NGINX_GID /var/run/nginx.pid

# Create directories for nginx to run as non-root
RUN mkdir -p /tmp/nginx && \
    chown -R 1001:1001 /tmp/nginx

# Switch to non-root user
USER 1001

# Expose port 8080 (non-privileged port)
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Security labels
LABEL \
    org.opencontainers.image.title="Material Dashboard 2 React" \
    org.opencontainers.image.description="Secure Material Dashboard React Application" \
    org.opencontainers.image.vendor="Your Organization" \
    org.opencontainers.image.version="2.1.0" \
    org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    security.non-root="true" \
    security.updated="true"

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
