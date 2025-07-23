@echo off
echo ============================================
echo Git Repository Setup and Push Script
echo ============================================
echo.

REM Change to the project directory
cd /d "c:\Users\KGAnanya\Downloads\javascript-test-application\javascript-app-test"

echo Current directory: %CD%
echo.

REM Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not in PATH
    echo Please install Git from: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo Git is installed ✓
echo.

REM Initialize git repository if not already done
if not exist ".git" (
    echo Initializing Git repository...
    git init
) else (
    echo Git repository already initialized ✓
)

REM Add remote origin
echo Setting up remote repository...
git remote remove origin 2>nul
git remote add origin https://github.com/Ananyakg1/Javascript_test_app.git

echo Remote repository set ✓
echo.

REM Check repository status
echo Current repository status:
git status
echo.

REM Add all files
echo Adding all files to staging...
git add .

echo Files staged ✓
echo.

REM Show what will be committed
echo Files to be committed:
git status --porcelain
echo.

REM Commit changes
echo Committing changes...
git commit -m "Add secure Docker setup with Kubernetes deployment and Azure AKS CI/CD

- Secure multi-stage Dockerfile with non-root user
- Comprehensive Kubernetes manifests with security best practices  
- Azure AKS GitHub Actions workflow with Trivy security scanning
- Complete documentation and setup scripts
- Security-hardened configurations and policies"

if errorlevel 1 (
    echo WARNING: Commit may have failed. This could be because:
    echo 1. No changes to commit
    echo 2. Git user not configured
    echo.
    echo To configure git user, run:
    echo git config --global user.name "Your Name"
    echo git config --global user.email "your.email@example.com"
    echo.
)

echo.

REM Set main branch and push
echo Setting up main branch and pushing to GitHub...
git branch -M main

echo Pushing to GitHub repository...
echo Note: You may be prompted for GitHub credentials
echo.

git push -u origin main

if errorlevel 1 (
    echo.
    echo ERROR: Push failed. This could be because:
    echo 1. Authentication failed - you need to provide GitHub credentials
    echo 2. Repository doesn't exist or you don't have access
    echo 3. Network connection issues
    echo.
    echo Solutions:
    echo 1. Make sure you're logged into GitHub
    echo 2. Use a Personal Access Token instead of password
    echo 3. Check if the repository exists: https://github.com/Ananyakg1/Javascript_test_app.git
    echo.
) else (
    echo.
    echo ============================================
    echo SUCCESS: Code pushed to GitHub! 🎉
    echo ============================================
    echo.
    echo Repository: https://github.com/Ananyakg1/Javascript_test_app.git
    echo.
    echo Next steps:
    echo 1. Go to your GitHub repository
    echo 2. Set up the required Azure secrets in Settings → Secrets and variables → Actions
    echo 3. Push to main branch to trigger the deployment workflow
    echo.
)

echo.
echo Press any key to exit...
pause >nul
