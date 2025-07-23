# GitHub Advanced Security Integration Guide

## Issue: "Resource not accessible by integration"

The error you're seeing occurs when trying to upload SARIF (Static Analysis Results Interchange Format) files to GitHub's Code Scanning feature, which is part of GitHub Advanced Security.

## Understanding the Problem

### GitHub Advanced Security Availability

GitHub Advanced Security features are available on:
- ✅ **GitHub Enterprise Cloud** (paid plans)
- ✅ **GitHub Enterprise Server** (paid plans)  
- ✅ **Public repositories** (free)
- ❌ **Private repositories on free plans** (limited access)

### Required Permissions

For SARIF upload to work, you need:
1. **Repository permissions**: `security-events: write`
2. **GitHub Advanced Security enabled** on the repository
3. **Code scanning enabled** in repository settings

## Solutions Implemented

### 1. Enhanced Security Scanning Pipeline

We've updated the main pipeline (`build-and-deploy.yml`) with:

```yaml
# Multiple scan formats for maximum compatibility
- name: Run Trivy vulnerability scanner (Table format)
  # Human-readable console output

- name: Run Trivy vulnerability scanner (JSON format)  
  # Machine-readable results for processing

- name: Run Trivy vulnerability scanner (SARIF format)
  continue-on-error: true  # Won't fail if GitHub Advanced Security unavailable
  # GitHub Security integration (when available)
```

### 2. Comprehensive Security Reporting

The pipeline now provides:
- 📊 **Detailed vulnerability statistics** in console output
- 📈 **GitHub Step Summary** with vulnerability counts
- 📋 **Artifact uploads** with scan results (JSON, SARIF)
- ⚠️ **Warning annotations** for critical/high vulnerabilities

### 3. Dedicated Security Scan Workflow

Created `security-scan.yml` with advanced features:
- 🕐 **Scheduled daily scans** (2 AM UTC)
- 🎛️ **Manual dispatch** with configurable parameters
- 📊 **Multiple report formats** (Table, JSON, SARIF, HTML)
- 🎯 **Security thresholds** with pass/fail criteria
- 🚨 **Critical vulnerability alerts**

## Alternative Security Monitoring

### 1. Artifact-based Review

Download security scan artifacts from GitHub Actions:
```bash
# Access scan results from Actions artifacts
1. Go to GitHub Actions → Workflow run
2. Download "security-scan-results" artifact
3. Extract and review JSON/HTML reports
```

### 2. JSON Report Processing

The pipeline processes JSON results to provide:
```bash
🔴 Critical: 0
🟠 High: 2  
🟡 Medium: 5
🟢 Low: 10
📈 Total: 17
```

### 3. Security Thresholds

Automated pass/fail based on vulnerability counts:
```yaml
MAX_CRITICAL=0    # Fail if any critical vulnerabilities
MAX_HIGH=5        # Warn if more than 5 high vulnerabilities
```

## Enabling GitHub Advanced Security

### For Organization Owners

1. **Navigate to** Organization Settings → Code security and analysis
2. **Enable** "GitHub Advanced Security"
3. **Configure** for specific repositories or all repositories

### For Repository Administrators

1. **Go to** Repository Settings → Code security and analysis
2. **Enable** "Code scanning" 
3. **Configure** SARIF uploads

### For Free Private Repositories

Consider these alternatives:
- 🔄 **Move to public repository** (if appropriate)
- 📊 **Use artifact-based security reporting**
- 🔍 **Manual security review** using downloaded reports
- ⬆️ **Upgrade to GitHub Team/Enterprise**

## Working with Current Setup

### Immediate Benefits (No GitHub Advanced Security needed)

✅ **Comprehensive vulnerability scanning** with Trivy  
✅ **Multiple report formats** for different use cases  
✅ **Automated security thresholds** with pass/fail  
✅ **Detailed console output** with vulnerability lists  
✅ **Artifact storage** for historical analysis  
✅ **GitHub Step Summary** with security overview  

### Security Workflow Features

```yaml
# Manual security scan with custom parameters
workflow_dispatch:
  inputs:
    image_tag: 'latest'           # Which image version to scan
    severity_filter: 'CRITICAL,HIGH'  # Which severities to include
```

### Example Usage

```bash
# Trigger manual security scan
1. Go to Actions → Security Scan → Run workflow
2. Select image tag (latest, main-abc123, etc.)
3. Choose severity filter (CRITICAL, CRITICAL,HIGH, etc.)
4. Run workflow and review results
```

## Security Best Practices

### 1. Regular Scanning
- ✅ **Daily automated scans** (via cron schedule)
- ✅ **Pre-deployment scans** (via build pipeline)
- ✅ **Manual scans** for specific images

### 2. Vulnerability Management
- 🔴 **Critical**: Address immediately
- 🟠 **High**: Address within 7 days  
- 🟡 **Medium**: Address within 30 days
- 🟢 **Low**: Address during regular updates

### 3. Response Process
1. **Identify** vulnerabilities via scan results
2. **Prioritize** based on severity and exploitability
3. **Update** affected packages/base images
4. **Rebuild** and redeploy container
5. **Verify** fixes with follow-up scan

## Monitoring and Alerts

### Current Implementation

```yaml
# Console warnings for vulnerabilities
echo "::warning::Found $CRITICAL critical and $HIGH high severity vulnerabilities"

# Step summary with security status
if [ "$CRITICAL" -gt "0" ] || [ "$HIGH" -gt "0" ]; then
  echo "⚠️ Action Required"
else
  echo "✅ Security Status: Clean"
fi
```

### Future Enhancements

You can extend the pipeline with:
- 📧 **Email notifications** for critical vulnerabilities
- 💬 **Slack/Teams integration** for security alerts
- 📊 **Security dashboards** using collected metrics
- 🔄 **Automated dependency updates** (Dependabot integration)

## Troubleshooting

### Common Issues

1. **"Resource not accessible by integration"**
   - ✅ **Solution**: Use `continue-on-error: true` for SARIF upload
   - ✅ **Alternative**: Rely on JSON/artifact-based reporting

2. **No security scan results**
   - 🔍 **Check**: Image name and tag are correct
   - 🔍 **Check**: Container registry access permissions

3. **False positives in scan results**
   - 📋 **Review**: Vulnerability details and fixed versions
   - 🔄 **Update**: Base images and dependencies
   - ⚙️ **Configure**: Trivy ignore files for accepted risks

### Debug Commands

```bash
# Test container image locally
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image your-image:tag

# Check image layers
docker history your-image:tag

# Verify security scan artifact contents
unzip security-scan-results.zip
cat trivy-results.json | jq '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL")'
```

## Conclusion

While GitHub Advanced Security integration provides the best user experience, our enhanced security scanning pipeline provides comprehensive vulnerability management without requiring paid features. The combination of multiple report formats, automated thresholds, and detailed reporting ensures robust security monitoring for your container images.

The security scanning works regardless of GitHub plan level, providing enterprise-grade security insights through alternative reporting mechanisms.
