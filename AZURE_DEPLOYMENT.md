# Azure AKS Deployment Workflow

## Overview

This GitHub Actions workflow provides automated build and deployment to Azure Kubernetes Service (AKS) with comprehensive security scanning using Trivy. The workflow is designed to be simple yet secure, deploying to an existing namespace with minimal configuration.

## 🏗️ Workflow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                 │
├─────────────────────────────────────────────────────────────┤
│  Job 1: Build and Security Scan                           │
│  ┌─────────────────┐  ┌─────────────────┐                │
│  │   Docker Build  │  │  Trivy Scanning │                │
│  │   Multi-stage   │  │  Manual + Action│                │
│  └─────────────────┘  └─────────────────┘                │
│            │                     │                        │
│  ┌─────────────────────────────────────────┐              │
│  │         Push to Azure ACR               │              │
│  └─────────────────────────────────────────┘              │
├─────────────────────────────────────────────────────────────┤
│  Job 2: Deploy to AKS                                     │
│  ┌─────────────────┐  ┌─────────────────┐                │
│  │   Azure Login   │  │  Simple Deploy  │                │
│  │   Get AKS Creds │  │  ConfigMap +    │                │
│  └─────────────────┘  │  Deployment +   │                │
│                       │  Service        │                │
│                       └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Workflow Features

### **Build Job:**
- ✅ **Docker multi-stage build** with security context
- ✅ **Build ID generation** (YYYYMMDD-COMMIT_SHA)
- ✅ **Azure Container Registry** integration
- ✅ **Trivy security scanning** (manual + action)
- ✅ **SARIF report upload** to GitHub Security tab
- ✅ **Exit on critical/high vulnerabilities**

### **Deploy Job:**
- ✅ **Azure CLI installation** and login
- ✅ **AKS credentials** configuration
- ✅ **Simple Kubernetes manifests** (in-line generation)
- ✅ **Namespace verification** and creation
- ✅ **Health checks** and verification
- ✅ **Security validation** post-deployment

## 🔒 Security Specifications

### **Trivy Scanning Configuration:**
```yaml
Manual Installation: ✅ (apt-get based)
Action Version: aquasecurity/trivy-action@0.28.0
Formats: table + SARIF
Exit Code: 1 (for critical/high vulnerabilities)
Ignore Unfixed: true
Severity: CRITICAL,HIGH
```

### **Container Security:**
```yaml
Non-root User: UID 1001
Read-only Filesystem: true
Dropped Capabilities: ALL
Security Context: enforced
Resource Limits: CPU 500m, Memory 512Mi
```

## ⚙️ Required GitHub Secrets

Add these secrets to your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Service Principal Client ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_CLIENT_SECRET` | Service Principal Secret | `your-client-secret` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `11111111-2222-3333-4444-555555555555` |
| `REGISTRY_LOGIN_SERVER` | ACR Login Server | `myregistry.azurecr.io` |
| `REGISTRY_USERNAME` | ACR Username | `myregistry` |
| `REGISTRY_PASSWORD` | ACR Password | `acr-password` |
| `AKS_CLUSTER_NAME` | AKS Cluster Name | `my-aks-cluster` |
| `AKS_RESOURCE_GROUP` | AKS Resource Group | `my-resource-group` |

## 🎯 Deployment Targets

### **Triggers:**
- **Push** to `main` or `develop` branches
- **Pull Request** to `main` branch (build only)

### **Deployment Criteria:**
- Only deploys on push to `main` or `develop`
- Skips deployment for pull requests
- Requires successful security scan

### **Target Configuration:**
```yaml
Platform: Azure Kubernetes Service (AKS)
Namespace: javascript-namespace
Replicas: 3
Image Tag: YYYYMMDD-COMMIT_SHA
Service Type: ClusterIP
```

## 📋 Deployment Manifests

The workflow generates simple, secure Kubernetes manifests:

### **ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: javascript-app-config
  namespace: javascript-namespace
data:
  NODE_ENV: "production"
  PORT: "8080"
```

### **Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: javascript-app-deployment
  namespace: javascript-namespace
spec:
  replicas: 3
  # Security contexts and resource limits included
```

### **Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: javascript-app-service
  namespace: javascript-namespace
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
```

## 🔍 Security Validation

### **Build-time Security:**
1. **Trivy vulnerability scanning** (table format)
2. **SARIF report generation** for GitHub Security
3. **Critical/High vulnerability blocking**
4. **Unfixed vulnerability filtering**

### **Runtime Security:**
1. **Non-root user execution** validation
2. **Resource limits** verification
3. **Security context** checking
4. **Health endpoint** testing

## 🚀 Usage Instructions

### **1. Setup Prerequisites:**
```bash
# Ensure you have the required Azure resources
az aks show --resource-group YOUR_RG --name YOUR_CLUSTER
az acr show --name YOUR_REGISTRY --resource-group YOUR_RG
```

### **2. Configure GitHub Secrets:**
Navigate to your repository → Settings → Secrets and variables → Actions

Add all the required secrets listed above.

### **3. Deploy:**
```bash
# Simply push to main or develop branch
git add .
git commit -m "Deploy to AKS"
git push origin main
```

### **4. Monitor Deployment:**
- Check GitHub Actions tab for workflow progress
- Review security scan results in GitHub Security tab
- Verify deployment in Azure portal or kubectl

## 🔧 Customization

### **Change Replicas:**
Edit line 185 in the workflow:
```yaml
replicas: 3  # Change to desired number
```

### **Modify Resource Limits:**
Edit lines 227-232:
```yaml
resources:
  requests:
    cpu: 250m      # Adjust as needed
    memory: 256Mi  # Adjust as needed
  limits:
    cpu: 500m      # Adjust as needed
    memory: 512Mi  # Adjust as needed
```

### **Add Environment Variables:**
Edit the ConfigMap section (lines 175-185) to add more configuration.

## 🛠️ Troubleshooting

### **Common Issues:**

1. **Azure Login Fails:**
   ```
   Solution: Verify service principal credentials in secrets
   ```

2. **ACR Access Denied:**
   ```
   Solution: Check ACR credentials and permissions
   ```

3. **AKS Connection Issues:**
   ```
   Solution: Verify cluster name and resource group
   ```

4. **Trivy Scan Failures:**
   ```
   Solution: Check if vulnerabilities exceed threshold
   ```

### **Debugging Commands:**

After workflow completion, use these kubectl commands:

```bash
# Check pods
kubectl get pods -n javascript-namespace

# Check logs
kubectl logs -l app=javascript-app -n javascript-namespace

# Check deployment
kubectl describe deployment javascript-app-deployment -n javascript-namespace

# Port forward for testing
kubectl port-forward -n javascript-namespace svc/javascript-app-service 8080:80
```

## 📊 Monitoring

### **GitHub Actions Monitoring:**
- Build duration and success rate
- Security scan results
- Deployment status

### **Application Monitoring:**
- Health checks at `/health` endpoint
- Pod readiness and liveness probes
- Resource utilization

### **Security Monitoring:**
- SARIF reports in GitHub Security tab
- Vulnerability trend analysis
- Container image security posture

## 🔄 Workflow Outputs

### **Build Job Outputs:**
- Docker image with build ID tag
- Trivy security scan results
- SARIF security report

### **Deploy Job Outputs:**
- Deployed application in AKS
- Health check verification
- Security validation results

## 📚 References

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)
- [GitHub Actions for Azure](https://github.com/Azure/actions)
