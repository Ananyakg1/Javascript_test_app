# PowerShell script to push code to GitHub
# Run this script from PowerShell

Write-Host "============================================" -ForegroundColor Green
Write-Host "Git Repository Setup and Push Script" -ForegroundColor Green  
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Change to project directory
$projectPath = "c:\Users\KGAnanya\Downloads\javascript-test-application\javascript-app-test"
Set-Location -Path $projectPath

Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Check if git is installed
try {
    $gitVersion = git --version
    Write-Host "Git is installed ✓ ($gitVersion)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Initialize git repository if needed
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    git init
} else {
    Write-Host "Git repository already initialized ✓" -ForegroundColor Green
}

# Remove existing remote and add new one
Write-Host "Setting up remote repository..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin https://github.com/Ananyakg1/Javascript_test_app.git

Write-Host "Remote repository set ✓" -ForegroundColor Green
Write-Host ""

# Check git configuration
$gitUserName = git config user.name 2>$null
$gitUserEmail = git config user.email 2>$null

if (-not $gitUserName -or -not $gitUserEmail) {
    Write-Host "Git user not configured. Setting up..." -ForegroundColor Yellow
    
    if (-not $gitUserName) {
        $userName = Read-Host "Enter your Git username"
        git config --global user.name "$userName"
    }
    
    if (-not $gitUserEmail) {
        $userEmail = Read-Host "Enter your Git email"
        git config --global user.email "$userEmail"
    }
    
    Write-Host "Git user configured ✓" -ForegroundColor Green
    Write-Host ""
}

# Show current status
Write-Host "Current repository status:" -ForegroundColor Yellow
git status
Write-Host ""

# Add all files
Write-Host "Adding all files to staging..." -ForegroundColor Yellow
git add .

Write-Host "Files staged ✓" -ForegroundColor Green
Write-Host ""

# Show staged files
Write-Host "Files to be committed:" -ForegroundColor Yellow
git status --porcelain
Write-Host ""

# Commit changes
Write-Host "Committing changes..." -ForegroundColor Yellow

$commitMessage = @"
Add secure Docker setup with Kubernetes deployment and Azure AKS CI/CD

- Secure multi-stage Dockerfile with non-root user
- Comprehensive Kubernetes manifests with security best practices
- Azure AKS GitHub Actions workflow with Trivy security scanning
- Complete documentation and setup scripts
- Security-hardened configurations and policies
"@

try {
    git commit -m $commitMessage
    Write-Host "Changes committed ✓" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Commit may have failed" -ForegroundColor Yellow
    Write-Host "This could be because there are no changes to commit" -ForegroundColor Yellow
}

Write-Host ""

# Set main branch
Write-Host "Setting up main branch..." -ForegroundColor Yellow
git branch -M main

# Push to GitHub
Write-Host "Pushing to GitHub repository..." -ForegroundColor Yellow
Write-Host "Note: You may be prompted for GitHub credentials" -ForegroundColor Cyan
Write-Host ""

try {
    git push -u origin main
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "SUCCESS: Code pushed to GitHub! 🎉" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository: https://github.com/Ananyakg1/Javascript_test_app.git" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Go to your GitHub repository" -ForegroundColor White
    Write-Host "2. Set up the required Azure secrets in Settings → Secrets and variables → Actions" -ForegroundColor White
    Write-Host "3. Push to main branch to trigger the deployment workflow" -ForegroundColor White
    Write-Host ""
    Write-Host "Required secrets to add:" -ForegroundColor Yellow
    Write-Host "- AZURE_CLIENT_ID" -ForegroundColor White
    Write-Host "- AZURE_CLIENT_SECRET" -ForegroundColor White
    Write-Host "- AZURE_SUBSCRIPTION_ID" -ForegroundColor White
    Write-Host "- AZURE_TENANT_ID" -ForegroundColor White
    Write-Host "- REGISTRY_LOGIN_SERVER" -ForegroundColor White
    Write-Host "- REGISTRY_USERNAME" -ForegroundColor White
    Write-Host "- REGISTRY_PASSWORD" -ForegroundColor White
    Write-Host "- AKS_CLUSTER_NAME" -ForegroundColor White
    Write-Host "- AKS_RESOURCE_GROUP" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Push failed" -ForegroundColor Red
    Write-Host "This could be because:" -ForegroundColor Yellow
    Write-Host "1. Authentication failed - you need to provide GitHub credentials" -ForegroundColor White
    Write-Host "2. Repository doesn't exist or you don't have access" -ForegroundColor White
    Write-Host "3. Network connection issues" -ForegroundColor White
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host "1. Make sure you're logged into GitHub" -ForegroundColor White
    Write-Host "2. Use a Personal Access Token instead of password" -ForegroundColor White
    Write-Host "3. Check if the repository exists: https://github.com/Ananyakg1/Javascript_test_app.git" -ForegroundColor White
    Write-Host ""
    Write-Host "To create a Personal Access Token:" -ForegroundColor Cyan
    Write-Host "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens" -ForegroundColor White
    Write-Host "2. Generate new token with 'repo' permissions" -ForegroundColor White
    Write-Host "3. Use the token as your password when prompted" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to exit"
