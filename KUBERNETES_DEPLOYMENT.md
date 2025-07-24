# Kubernetes Deployment Guide

## Overview

This directory contains secure Kubernetes deployment manifests for the Material Dashboard 2 React application with comprehensive security best practices, monitoring, and automated CI/CD integration.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                      │
├─────────────────────────────────────────────────────────────┤
│  Namespace: javascript-namespace                           │
│  ┌─────────────────┐  ┌─────────────────┐                │
│  │   Ingress       │  │  Network Policy │                │
│  │   (TLS/HTTPS)   │  │  (Firewall)     │                │
│  └─────────────────┘  └─────────────────┘                │
│            │                     │                        │
│  ┌─────────────────┐  ┌─────────────────┐                │
│  │    Service      │  │   ConfigMap     │                │
│  │   (ClusterIP)   │  │   (Config)      │                │
│  └─────────────────┘  └─────────────────┘                │
│            │                     │                        │
│  ┌─────────────────────────────────────────┐              │
│  │         Deployment (3 replicas)        │              │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐           │
│  │  │   Pod 1   │ │   Pod 2   │ │   Pod 3   │           │
│  │  │Container  │ │Container  │ │Container  │           │
│  │  │(Non-root) │ │(Non-root) │ │(Non-root) │           │
│  │  └───────────┘ └───────────┘ └───────────┘           │
│  └─────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## 📁 File Structure

```
k8s/
├── namespace.yaml           # Namespace with resource quotas and limits
├── configmap.yaml          # Application configuration and nginx config
├── secrets-rbac.yaml       # Secrets and RBAC configuration
├── deployment.yaml         # Main application deployment
├── service.yaml            # Service definitions (ClusterIP, headless, internal)
├── network-policy.yaml     # Network security policies
├── ingress.yaml            # Ingress with TLS and security headers
```

## 🔒 Security Features

### Pod Security
- ✅ **Non-root user execution** (UID: 1001)
- ✅ **Read-only root filesystem**
- ✅ **Dropped capabilities** (ALL) with minimal additions
- ✅ **Security contexts** at pod and container level
- ✅ **AppArmor and Seccomp** profiles
- ✅ **No privilege escalation**

### Network Security
- ✅ **Network policies** (default deny + allow rules)
- ✅ **ClusterIP services** (internal communication)
- ✅ **Ingress with TLS** termination
- ✅ **Security headers** (XSS, CSRF, clickjacking protection)
- ✅ **Rate limiting** and WAF protection

### Resource Management
- ✅ **Resource quotas** and limits
- ✅ **Pod disruption budgets**
- ✅ **Horizontal pod autoscaling**
- ✅ **Anti-affinity** rules
- ✅ **Node selectors** and tolerations

### Access Control
- ✅ **RBAC** with minimal permissions
- ✅ **Service accounts** with no token automount
- ✅ **Pod security policies**
- ✅ **Namespace isolation**

## 🚀 Deployment Instructions

### Prerequisites

1. **Kubernetes Cluster** (v1.25+)
2. **kubectl** configured with cluster access
3. **kustomize** (v5.0+)
4. **GitHub Actions** with appropriate secrets

### GitHub Actions Deployment

The deployment is fully automated via GitHub Actions. Simply push to the `main` branch:

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

### Manual Deployment

If you need to deploy manually:

```bash
# 1. Install kubectl and kustomize
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# 2. Configure cluster access
# For AWS EKS:
aws eks update-kubeconfig --region us-west-2 --name your-cluster-name

# For Google GKE:
gcloud container clusters get-credentials your-cluster --zone us-central1-a

# For Azure AKS:
az aks get-credentials --resource-group your-rg --name your-cluster

# 3. Deploy the application
cd k8s
kubectl apply -f namespace.yaml
kustomize build . | kubectl apply -f -

# 4. Verify deployment
kubectl rollout status deployment/javascript-app-deployment -n javascript-namespace
kubectl get pods -n javascript-namespace
```

## 🔧 Configuration

### Environment Variables (ConfigMap)

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Node.js environment | `production` |
| `PORT` | Application port | `8080` |
| `LOG_LEVEL` | Logging level | `info` |
| `SECURE_HEADERS` | Enable security headers | `true` |

### Secrets

Update the base64-encoded secrets in `secrets-rbac.yaml`:

```bash
# Generate base64 encoded secrets
echo -n "your-secret-value" | base64
```

### Resource Limits

Default resource allocation per pod:

```yaml
resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## 📊 Monitoring and Health Checks

### Health Endpoints

- **Liveness**: `GET /health` - Container health
- **Readiness**: `GET /ready` - Service readiness
- **Startup**: `GET /health` - Initial startup check

### Prometheus Monitoring

Automatic metrics collection via ServiceMonitor:

- **CPU/Memory usage**
- **HTTP request metrics**
- **Pod restart counts**
- **Custom application metrics**

### Alerting Rules

Configured alerts for:

- **Application downtime**
- **High CPU/memory usage**
- **Pod crash looping**
- **High error rates**

## 🌐 Networking

### Service Types

1. **javascript-app-service** (ClusterIP): Main application service
2. **javascript-app-headless** (ClusterIP None): Service discovery
3. **javascript-app-internal** (ClusterIP): Internal monitoring

### Ingress Configuration

- **TLS termination** with Let's Encrypt
- **Security headers** injection
- **Rate limiting** (100 req/min)
- **WAF protection** with ModSecurity

### Network Policies

- **Default deny all** traffic
- **Allow ingress** from ingress controller
- **Allow egress** for DNS, HTTPS, and API calls
- **Allow monitoring** access

## 🔄 Scaling and Updates

### Horizontal Pod Autoscaler

Automatic scaling based on:
- **CPU utilization** (target: 70%)
- **Memory utilization** (target: 80%)
- **Min replicas**: 3
- **Max replicas**: 10

### Rolling Updates

```bash
# Update image
kubectl set image deployment/javascript-app-deployment \
  javascript-app=javascript-app:new-tag \
  -n javascript-namespace

# Monitor rollout
kubectl rollout status deployment/javascript-app-deployment -n javascript-namespace

# Rollback if needed
kubectl rollout undo deployment/javascript-app-deployment -n javascript-namespace
```

## 🛡️ Security Validation

### Pre-deployment Checks

The CI/CD pipeline includes:

- **kubesec** - Security risk analysis
- **kube-score** - Best practices validation
- **Polaris** - Configuration auditing
- **YAML validation** - Syntax checking

### Runtime Security

```bash
# Check security context
kubectl get pods -n javascript-namespace -o jsonpath='{.items[*].spec.securityContext}'

# Validate network policies
kubectl get networkpolicies -n javascript-namespace

# Check resource limits
kubectl describe pods -n javascript-namespace -l app=javascript-app
```

## 🚨 Troubleshooting

### Common Issues

1. **Pod CrashLoopBackOff**
   ```bash
   kubectl logs -n javascript-namespace -l app=javascript-app --tail=100
   kubectl describe pod -n javascript-namespace -l app=javascript-app
   ```

2. **Service not accessible**
   ```bash
   kubectl get svc -n javascript-namespace
   kubectl get endpoints -n javascript-namespace
   ```

3. **Ingress issues**
   ```bash
   kubectl describe ingress -n javascript-namespace
   kubectl get events -n javascript-namespace
   ```

### Debugging Commands

```bash
# Get all resources
kubectl get all -n javascript-namespace

# Check events
kubectl get events -n javascript-namespace --sort-by='.lastTimestamp'

# Port forward for testing
kubectl port-forward -n javascript-namespace svc/javascript-app-service 8080:80

# Execute into pod
kubectl exec -it -n javascript-namespace deployment/javascript-app-deployment -- /bin/sh
```

## 📋 Maintenance

### Weekly Tasks

- [ ] Review resource usage
- [ ] Check security alerts
- [ ] Update base images
- [ ] Review logs for errors

### Monthly Tasks

- [ ] Security audit
- [ ] Performance optimization
- [ ] Documentation updates
- [ ] Disaster recovery testing

## 🔗 References

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

## 📞 Support

For deployment issues:
- Check GitHub Actions logs
- Review pod logs and events
- Validate configuration with security tools
- Follow troubleshooting guide above
