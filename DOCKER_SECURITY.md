# Security documentation for Docker deployment

## Docker Security Implementation

This document outlines the security measures implemented in the Dockerfile and deployment configuration for the Material Dashboard 2 React application.

### Security Features Implemented

#### 1. Base Image Security
- **Specific Version Tags**: Using `node:18.20.4-alpine3.20` and `nginx:1.27.0-alpine3.19` instead of `latest`
- **Alpine Linux**: Minimal attack surface with regular security updates
- **Multi-stage Build**: Separates build and runtime environments

#### 2. Non-Root User Execution
- **Build Stage**: User ID 1001 with group `nodejs`
- **Runtime Stage**: User ID 1001 with group `nginx`
- **File Permissions**: Proper ownership of application files

#### 3. Vulnerability Management
- **Package Updates**: `apk update && apk upgrade` in both stages
- **Security Audits**: `npm audit fix` during build
- **Dependency Scanning**: Trivy and Docker Scout in CI/CD

#### 4. Security Headers (Nginx Configuration)
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Content-Security-Policy`: Restrictive CSP rules

#### 5. Container Security
- **Read-only Root Filesystem**: Prevents runtime modifications
- **Dropped Capabilities**: Only essential capabilities retained
- **No New Privileges**: Prevents privilege escalation
- **Resource Limits**: CPU and memory constraints

#### 6. Health Checks
- **Application Health**: HTTP endpoint monitoring
- **Container Health**: Docker health check configuration
- **Automated Recovery**: Restart policies for failed containers

#### 7. Network Security
- **Non-privileged Port**: Port 8080 instead of 80/443
- **Network Isolation**: Bridge network with restricted ICC
- **TLS Configuration**: Ready for HTTPS deployment

### CI/CD Security Pipeline

#### GitHub Actions Workflow Features:
1. **Security Scanning**:
   - npm audit for dependency vulnerabilities
   - ESLint security rules
   - Trivy vulnerability scanner
   - Docker Scout security analysis

2. **Multi-platform Builds**:
   - AMD64 and ARM64 architecture support
   - Build cache optimization

3. **Container Registry**:
   - GitHub Container Registry (ghcr.io)
   - Signed container images
   - Vulnerability reporting

4. **Security Baseline**:
   - Docker Bench Security tests
   - CIS Docker Benchmark compliance

### Deployment Security

#### Docker Compose Security Configuration:
- **Security Options**: AppArmor profiles, no-new-privileges
- **Resource Limits**: CPU and memory constraints
- **Temporary Filesystems**: Secure tmpfs mounts
- **Health Monitoring**: Automated health checks

### Security Best Practices Implemented

1. **Principle of Least Privilege**: Minimal user permissions
2. **Defense in Depth**: Multiple security layers
3. **Secure by Default**: Security-first configuration
4. **Monitoring and Alerting**: Health checks and logging
5. **Regular Updates**: Automated security patching

### Usage Instructions

#### Local Development:
```bash
# Build the secure image
docker build -t material-dashboard-react:secure .

# Run with security configuration
docker-compose -f docker-compose.security.yml up
```

#### Production Deployment:
```bash
# Deploy using GitHub Actions
git push origin main

# Manual deployment with security
docker run --rm -d \
  --name material-dashboard \
  --user 1001:1001 \
  --read-only \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --cap-add CHOWN \
  --cap-add SETGID \
  --cap-add SETUID \
  -p 8080:8080 \
  material-dashboard-react:secure
```

### Security Monitoring

- **Container Scanning**: Automated vulnerability detection
- **Runtime Security**: AppArmor/SELinux enforcement
- **Access Logging**: Nginx access and error logs
- **Health Monitoring**: Application and container health

### Compliance

This configuration addresses:
- **CIS Docker Benchmark**: Container security standards
- **NIST Guidelines**: Application security frameworks
- **OWASP Top 10**: Web application security risks
- **CVE Management**: Continuous vulnerability assessment

### Maintenance

- **Regular Updates**: Weekly base image updates
- **Security Patches**: Automated dependency updates
- **Monitoring**: Continuous security scanning
- **Documentation**: Updated security practices
