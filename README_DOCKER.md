# Secure Docker Deployment Guide

## Overview

This repository contains a secure Docker setup for the Material Dashboard 2 React application with comprehensive security measures and automated CI/CD pipeline using GitHub Actions.

## 🔒 Security Features

### Container Security
- ✅ **Non-root user execution** (UID: 1001)
- ✅ **Multi-stage builds** (build/runtime separation)
- ✅ **Minimal attack surface** (Alpine Linux)
- ✅ **Read-only root filesystem**
- ✅ **Dropped capabilities** (principle of least privilege)
- ✅ **Security headers** (XSS, CSRF, clickjacking protection)
- ✅ **Health checks** and monitoring
- ✅ **Resource limitations**

### Vulnerability Management
- ✅ **Dependency scanning** (npm audit, Trivy, Docker Scout)
- ✅ **Base image updates** (specific version tags)
- ✅ **Security patches** (automated in CI/CD)
- ✅ **CVE monitoring** (continuous scanning)

## 🚀 Quick Start

### Prerequisites
- GitHub repository with Actions enabled
- Container registry access (GitHub Container Registry)

### GitHub Actions Setup

1. **Push to GitHub**: The workflow automatically triggers on push to `main` or `develop` branches

2. **Secrets Configuration**: No additional secrets needed (uses `GITHUB_TOKEN`)

3. **Workflow Features**:
   - Security scanning (npm audit, ESLint)
   - Multi-platform builds (AMD64, ARM64)
   - Vulnerability scanning (Trivy, Docker Scout)
   - Container registry push
   - Security baseline checks

## 📋 Workflow Stages

### 1. Security Scan
```yaml
- npm audit --audit-level=critical
- ESLint security rules
- Dependency vulnerability check
```

### 2. Build and Push
```yaml
- Multi-platform Docker build
- Trivy vulnerability scanning
- Docker Scout security analysis
- Push to GitHub Container Registry
```

### 3. Security Baseline
```yaml
- Docker Bench Security tests
- CIS Docker Benchmark compliance
```

### 4. Deploy
```yaml
- Automated deployment (when configured)
- Environment-specific deployments
```

## 🐳 Local Development

### Build Secure Image
```bash
docker build -t material-dashboard-react:secure .
```

### Run with Security Configuration
```bash
docker-compose -f docker-compose.security.yml up
```

### Manual Secure Run
```bash
docker run --rm -d \
  --name material-dashboard \
  --user 1001:1001 \
  --read-only \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --cap-add CHOWN \
  --cap-add SETGID \
  --cap-add SETUID \
  --tmpfs /tmp:rw,noexec,nosuid,size=100m \
  -p 8080:8080 \
  material-dashboard-react:secure
```

## 🔍 Security Verification

### Container Security Check
```bash
# Check running container security
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker/docker-bench-security
```

### Vulnerability Scanning
```bash
# Scan image for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image material-dashboard-react:secure
```

### Security Audit
```bash
# NPM security audit
npm audit --audit-level=critical

# Fix vulnerabilities
npm audit fix
```

## 📊 Monitoring and Logging

### Health Check Endpoint
```
GET http://localhost:8080/health
Response: "healthy"
```

### Security Headers Verification
```bash
curl -I http://localhost:8080/
# Verify security headers are present
```

### Container Logs
```bash
docker logs material-dashboard-secure
```

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage secure container build |
| `.dockerignore` | Exclude sensitive files from build |
| `nginx.conf` | Secure nginx configuration |
| `docker-compose.security.yml` | Production security settings |
| `.github/workflows/docker-build-deploy.yml` | CI/CD pipeline |
| `.npmrc` | NPM security configuration |
| `DOCKER_SECURITY.md` | Detailed security documentation |

## 🚨 Security Checklist

- [ ] Regular base image updates
- [ ] Dependency vulnerability scanning
- [ ] Security headers verification
- [ ] Non-root user execution
- [ ] Resource limits configured
- [ ] Health checks enabled
- [ ] Logs monitoring setup
- [ ] Network security configured
- [ ] Secrets management implemented
- [ ] Backup and recovery tested

## 🛠 Maintenance

### Weekly Tasks
- [ ] Update base images
- [ ] Review security scan results
- [ ] Update dependencies
- [ ] Check for new CVEs

### Monthly Tasks
- [ ] Security configuration review
- [ ] Performance optimization
- [ ] Documentation updates
- [ ] Disaster recovery testing

## 📚 References

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Container Security Guide](https://csrc.nist.gov/publications/detail/sp/800-190/final)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

## 🆘 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Fix: Ensure proper file ownership
   sudo chown -R 1001:1001 /path/to/files
   ```

2. **Health Check Failing**
   ```bash
   # Debug: Check container logs
   docker logs container-name
   ```

3. **Build Failures**
   ```bash
   # Clean build
   docker system prune -a
   docker build --no-cache .
   ```

## 📞 Support

For security issues or questions:
- Create an issue in this repository
- Follow responsible disclosure for security vulnerabilities
- Check documentation in `DOCKER_SECURITY.md`
