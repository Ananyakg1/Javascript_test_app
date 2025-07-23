#!/bin/bash

# Kubernetes Security Validation Script
# This script validates the security configuration of the Kubernetes deployment

set -e

NAMESPACE="javascript-namespace"
APP_LABEL="app=javascript-app"

echo "🔍 Kubernetes Security Validation for JavaScript App"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if namespace exists
print_info "Checking namespace..."
if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_status 0 "Namespace $NAMESPACE exists"
else
    print_status 1 "Namespace $NAMESPACE does not exist"
    exit 1
fi

# Check if pods are running
print_info "Checking pod status..."
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL --field-selector=status.phase=Running --no-headers | wc -l)
if [ $RUNNING_PODS -gt 0 ]; then
    print_status 0 "$RUNNING_PODS pods are running"
else
    print_status 1 "No running pods found"
    kubectl get pods -n $NAMESPACE -l $APP_LABEL
fi

echo ""
echo "🔒 Security Context Validation"
echo "=============================="

# Check if pods are running as non-root
print_info "Checking non-root user execution..."
NON_ROOT_PODS=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[*].spec.securityContext.runAsNonRoot}' | grep -c true || echo 0)
TOTAL_PODS=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL --no-headers | wc -l)

if [ $NON_ROOT_PODS -eq $TOTAL_PODS ] && [ $TOTAL_PODS -gt 0 ]; then
    print_status 0 "All pods are running as non-root user"
else
    print_status 1 "Some pods are running as root user"
fi

# Check read-only root filesystem
print_info "Checking read-only root filesystem..."
READONLY_PODS=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[*].spec.containers[*].securityContext.readOnlyRootFilesystem}' | grep -c true || echo 0)

if [ $READONLY_PODS -eq $TOTAL_PODS ] && [ $TOTAL_PODS -gt 0 ]; then
    print_status 0 "All pods have read-only root filesystem"
else
    print_status 1 "Some pods don't have read-only root filesystem"
fi

# Check privilege escalation
print_info "Checking privilege escalation..."
NO_PRIV_ESC=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[*].spec.containers[*].securityContext.allowPrivilegeEscalation}' | grep -c false || echo 0)

if [ $NO_PRIV_ESC -eq $TOTAL_PODS ] && [ $TOTAL_PODS -gt 0 ]; then
    print_status 0 "Privilege escalation is disabled"
else
    print_status 1 "Privilege escalation might be enabled"
fi

echo ""
echo "🌐 Network Security Validation"
echo "============================="

# Check network policies
print_info "Checking network policies..."
NETPOL_COUNT=$(kubectl get networkpolicies -n $NAMESPACE --no-headers | wc -l)

if [ $NETPOL_COUNT -gt 0 ]; then
    print_status 0 "Network policies are configured ($NETPOL_COUNT policies)"
    kubectl get networkpolicies -n $NAMESPACE --no-headers | awk '{print "  - " $1}'
else
    print_status 1 "No network policies found"
fi

# Check services
print_info "Checking service configuration..."
CLUSTER_IP_SERVICES=$(kubectl get svc -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[?(@.spec.type=="ClusterIP")].metadata.name}')

if [ ! -z "$CLUSTER_IP_SERVICES" ]; then
    print_status 0 "ClusterIP services are configured"
    echo "  Services: $CLUSTER_IP_SERVICES"
else
    print_warning "No ClusterIP services found (may be using NodePort/LoadBalancer)"
fi

echo ""
echo "📊 Resource Management Validation"
echo "================================"

# Check resource limits
print_info "Checking resource limits..."
PODS_WITH_LIMITS=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[*].spec.containers[*].resources.limits}' | grep -c cpu || echo 0)

if [ $PODS_WITH_LIMITS -gt 0 ]; then
    print_status 0 "Resource limits are configured"
else
    print_status 1 "No resource limits found"
fi

# Check pod disruption budget
print_info "Checking pod disruption budget..."
PDB_COUNT=$(kubectl get pdb -n $NAMESPACE --no-headers | wc -l)

if [ $PDB_COUNT -gt 0 ]; then
    print_status 0 "Pod disruption budget is configured"
else
    print_warning "No pod disruption budget found"
fi

# Check horizontal pod autoscaler
print_info "Checking horizontal pod autoscaler..."
HPA_COUNT=$(kubectl get hpa -n $NAMESPACE --no-headers | wc -l)

if [ $HPA_COUNT -gt 0 ]; then
    print_status 0 "Horizontal pod autoscaler is configured"
else
    print_warning "No horizontal pod autoscaler found"
fi

echo ""
echo "🏥 Health Check Validation"
echo "========================="

# Check liveness probes
print_info "Checking liveness probes..."
LIVENESS_PROBES=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[*].spec.containers[*].livenessProbe}' | grep -c httpGet || echo 0)

if [ $LIVENESS_PROBES -gt 0 ]; then
    print_status 0 "Liveness probes are configured"
else
    print_status 1 "No liveness probes found"
fi

# Check readiness probes
print_info "Checking readiness probes..."
READINESS_PROBES=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[*].spec.containers[*].readinessProbe}' | grep -c httpGet || echo 0)

if [ $READINESS_PROBES -gt 0 ]; then
    print_status 0 "Readiness probes are configured"
else
    print_status 1 "No readiness probes found"
fi

echo ""
echo "🔐 RBAC Validation"
echo "=================="

# Check service accounts
print_info "Checking service accounts..."
SA_COUNT=$(kubectl get sa -n $NAMESPACE --no-headers | grep -v default | wc -l)

if [ $SA_COUNT -gt 0 ]; then
    print_status 0 "Custom service accounts are configured"
else
    print_warning "Using default service account"
fi

# Check role bindings
print_info "Checking role bindings..."
RB_COUNT=$(kubectl get rolebindings -n $NAMESPACE --no-headers | wc -l)

if [ $RB_COUNT -gt 0 ]; then
    print_status 0 "Role bindings are configured"
else
    print_warning "No role bindings found"
fi

echo ""
echo "🔍 Security Scan Summary"
echo "======================="

# Test health endpoint
print_info "Testing health endpoint..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[0].metadata.name}')

if [ ! -z "$POD_NAME" ]; then
    if kubectl exec -n $NAMESPACE $POD_NAME -- curl -f http://localhost:8080/health &> /dev/null; then
        print_status 0 "Health endpoint is accessible"
    else
        print_status 1 "Health endpoint is not accessible"
    fi
else
    print_warning "No pods available for health check"
fi

# Check for secrets
print_info "Checking secrets configuration..."
SECRET_COUNT=$(kubectl get secrets -n $NAMESPACE --no-headers | grep -v default-token | wc -l)

if [ $SECRET_COUNT -gt 0 ]; then
    print_status 0 "Secrets are configured"
else
    print_warning "No custom secrets found"
fi

# Summary
echo ""
echo "📋 Validation Complete"
echo "====================="
echo "Namespace: $NAMESPACE"
echo "Pods running: $RUNNING_PODS"
echo "Network policies: $NETPOL_COUNT"
echo "Pod disruption budgets: $PDB_COUNT"
echo "Horizontal pod autoscalers: $HPA_COUNT"
echo "Custom service accounts: $SA_COUNT"
echo "Role bindings: $RB_COUNT"
echo "Custom secrets: $SECRET_COUNT"

echo ""
print_info "For detailed security analysis, run:"
echo "  kubectl get pods -n $NAMESPACE -o yaml | kubesec scan -"
echo "  polaris audit --audit-path=k8s/"
echo "  kube-score score k8s/*.yaml"

echo ""
echo "🔒 Security validation completed!"
