#!/bin/bash

# Azure Setup Script for AKS Deployment
# This script helps set up the required Azure resources and GitHub secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first:"
    echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

print_info "Azure AKS Deployment Setup Script"
echo "=================================="

# Check if user is logged in
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Please login first:"
    az login
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

print_success "Using subscription: $SUBSCRIPTION_ID"
print_success "Tenant ID: $TENANT_ID"

# Prompt for resource names
echo ""
print_info "Please provide the following information:"

read -p "Resource Group Name (e.g., my-app-rg): " RESOURCE_GROUP
read -p "AKS Cluster Name (e.g., my-aks-cluster): " AKS_CLUSTER_NAME
read -p "Azure Container Registry Name (e.g., myappregistry): " ACR_NAME
read -p "Service Principal Name (e.g., github-actions-sp): " SP_NAME
read -p "Location (e.g., eastus): " LOCATION

echo ""
print_info "Creating Azure resources..."

# Create resource group if it doesn't exist
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
    print_info "Creating resource group: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
    print_success "Resource group created"
else
    print_success "Resource group already exists"
fi

# Create ACR if it doesn't exist
if ! az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    print_info "Creating Azure Container Registry: $ACR_NAME"
    az acr create \
        --resource-group $RESOURCE_GROUP \
        --name $ACR_NAME \
        --sku Basic \
        --admin-enabled true
    print_success "Azure Container Registry created"
else
    print_success "Azure Container Registry already exists"
fi

# Create AKS cluster if it doesn't exist
if ! az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME &> /dev/null; then
    print_info "Creating AKS cluster: $AKS_CLUSTER_NAME (this may take 10-15 minutes)"
    az aks create \
        --resource-group $RESOURCE_GROUP \
        --name $AKS_CLUSTER_NAME \
        --node-count 3 \
        --node-vm-size Standard_B2s \
        --enable-addons monitoring \
        --generate-ssh-keys \
        --attach-acr $ACR_NAME
    print_success "AKS cluster created"
else
    print_success "AKS cluster already exists"
    
    # Attach ACR to AKS if not already attached
    print_info "Attaching ACR to AKS cluster"
    az aks update \
        --resource-group $RESOURCE_GROUP \
        --name $AKS_CLUSTER_NAME \
        --attach-acr $ACR_NAME
fi

# Create service principal
print_info "Creating service principal: $SP_NAME"

# Get AKS resource ID
AKS_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query id -o tsv)

# Create service principal with AKS access
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name $SP_NAME \
    --role Contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --json-auth)

# Extract service principal details
CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.clientSecret')

print_success "Service principal created"

# Get ACR credentials
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

# Create namespace in AKS
print_info "Setting up AKS cluster and creating namespace"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

# Check if kubectl is available
if command -v kubectl &> /dev/null; then
    # Create namespace
    kubectl create namespace javascript-namespace --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'javascript-namespace' created/updated"
else
    print_warning "kubectl not found. Please install kubectl and run: kubectl create namespace javascript-namespace"
fi

echo ""
print_success "Azure resources setup complete!"

echo ""
print_info "GitHub Secrets Configuration"
echo "=============================="
echo ""
print_warning "Add the following secrets to your GitHub repository:"
echo "Repository → Settings → Secrets and variables → Actions → New repository secret"
echo ""

echo "AZURE_CLIENT_ID:"
echo "$CLIENT_ID"
echo ""

echo "AZURE_CLIENT_SECRET:"
echo "$CLIENT_SECRET"
echo ""

echo "AZURE_SUBSCRIPTION_ID:"
echo "$SUBSCRIPTION_ID"
echo ""

echo "AZURE_TENANT_ID:"
echo "$TENANT_ID"
echo ""

echo "REGISTRY_LOGIN_SERVER:"
echo "$ACR_LOGIN_SERVER"
echo ""

echo "REGISTRY_USERNAME:"
echo "$ACR_USERNAME"
echo ""

echo "REGISTRY_PASSWORD:"
echo "$ACR_PASSWORD"
echo ""

echo "AKS_CLUSTER_NAME:"
echo "$AKS_CLUSTER_NAME"
echo ""

echo "AKS_RESOURCE_GROUP:"
echo "$RESOURCE_GROUP"
echo ""

print_success "Setup completed successfully!"

echo ""
print_info "Next Steps:"
echo "1. Add the secrets above to your GitHub repository"
echo "2. Push your code to the main or develop branch"
echo "3. Watch the GitHub Actions workflow deploy your application"
echo ""

print_info "Verification Commands:"
echo "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME"
echo "az acr repository list --name $ACR_NAME"
echo "kubectl get pods -n javascript-namespace"

echo ""
print_warning "Important Notes:"
echo "- Keep your service principal credentials secure"
echo "- The service principal has Contributor access to the resource group"
echo "- ACR admin is enabled for simplicity (consider using service principal for production)"
echo "- AKS cluster is configured with 3 nodes (Standard_B2s)"
