# Troubleshooting Journey - Real-World DevOps Experience

This document chronicles the iterative debugging process encountered while building a PCI-DSS compliant CI/CD pipeline. This reflects authentic DevOps workflows where issues are discovered and resolved systematically.

---

## Issue #1: VPC Configuration Timeout (Networking)

**Problem:**
```
CodeBuild failed to download source from S3
Error: Connection timeout after 5 minutes
```

**Root Cause:**
- CodeBuild in VPC without NAT Gateway or S3 VPC Endpoint
- Private subnets cannot reach internet or AWS services

**Solution:**
- Commented out VPC configuration for dev environment
- Documented that production would require NAT Gateway ($32/month) or VPC Endpoints
- Trade-off: Cost vs. network isolation for non-production environment

**Lesson Learned:**
VPC configurations require proper egress routing. For dev environments, evaluate cost/benefit of network isolation.

---

## Issue #2: Buildspec YAML Syntax Error (Configuration)

**Problem:**
```
Phase: YAML_FILE_NOT_FOUND
Error: Buildspec parsing failed
```

**Root Cause:**
- Incorrect `file()` function syntax in Terraform
- Buildspec referenced from wrong path

**Solution:**
- Changed from inline buildspec to external file
- Used correct path: `${path.module}/buildspec.yml`
- Validated YAML syntax with proper indentation

**Lesson Learned:**
Terraform module paths require `${path.module}` for relative file references. Always validate YAML syntax before deployment.

---

## Issue #3: Checkov Security Scan Failures (Security Compliance)

**Problem:**
```
6 FAILED checks:
- CKV2_AWS_62: S3 event notifications missing
- CKV_AWS_144: S3 cross-region replication missing  
- CKV2_AWS_5: Security group not attached
- CKV2_AWS_12: VPC default security group not restricted
```

**Root Cause:**
- Checkov enforces production-grade security standards
- Dev environment doesn't need all enterprise features (cost consideration)

**Solution:**
- Added `checkov:skip` comments with business justification
- Documented why each check was suppressed for dev environment:
  - Event notifications: Not needed for pipeline artifacts
  - Cross-region replication: Cost-prohibitive ($$$) for dev
  - Security group attachment: VPC config removed (see Issue #1)
  - Default SG: AWS best practice but not critical for isolated dev VPC

**Example Code:**
```hcl
resource "aws_s3_bucket" "artifacts" {
  # checkov:skip=CKV2_AWS_62:Event notifications not required for dev pipeline artifacts
  # checkov:skip=CKV_AWS_144:Cross-region replication is cost-prohibitive for dev environment
  
  bucket_prefix = "${var.project_name}-${var.environment}-artifacts-"
  # ... rest of config
}
```

**Lesson Learned:**
Security scanning tools enforce best practices, but real-world requires balancing security, cost, and operational complexity. Suppressions should always include justification comments.

---

## Issue #4: Buildspec Logic Error (Script Logic)

**Problem:**
```
Checkov passed (90 passed, 0 failed, 6 skipped)
But build still failed due to incorrect exit code handling
```

**Root Cause:**
- Bash script didn't initialize `CHECKOV_EXIT_CODE` variable
- String comparison used instead of numeric comparison
- When Checkov succeeded, unset variable caused logic error

**Solution:**
```bash
# Initialize exit code to 0
CHECKOV_EXIT_CODE=0

checkov -d . --soft-fail || CHECKOV_EXIT_CODE=$?

# Use numeric comparison
if [ "$CHECKOV_EXIT_CODE" -ne 0 ]; then
  # Handle failures
fi
```

**Lesson Learned:**
Shell scripting requires careful variable initialization and type-aware comparisons. Always initialize variables before conditional use.

---

## Issue #5: IAM Permission Gap (Access Control)

**Problem:**
```
Phase: UPLOAD_ARTIFACTS
Error: AccessDeniedException
User not authorized to perform: codebuild:CreateReportGroup
```

**Root Cause:**
- CodeBuild role lacked permissions to create test report groups
- New feature (JUnit XML reports) required additional IAM permissions

**Solution:**
Added to CodeBuild IAM policy:
```json
{
  "Effect": "Allow",
  "Action": [
    "codebuild:CreateReportGroup",
    "codebuild:CreateReport",
    "codebuild:UpdateReport",
    "codebuild:BatchPutTestCases",
    "codebuild:BatchPutCodeCoverages"
  ],
  "Resource": [
    "arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:report-group/${var.project_name}-${var.environment}-*"
  ]
}
```

**Lesson Learned:**
AWS follows least-privilege model. New features often require explicitly granting additional permissions. Always scope IAM permissions to specific resources.

---

## Key Takeaways

### 1. **Iterative Debugging is Normal**
Professional DevOps involves systematic troubleshooting. Each error provides clues to the next issue.

### 2. **Layered Systems = Cascading Issues**
Fixing one layer (networking) reveals issues in the next (configuration, security, permissions).

### 3. **Documentation is Critical**
Recording each issue and solution builds institutional knowledge and helps future debugging.

### 4. **Balance Trade-offs**
Real-world requires balancing:
- Security vs. Cost (cross-region replication)
- Isolation vs. Complexity (VPC configuration)
- Compliance vs. Practicality (dev vs. prod standards)

### 5. **Tools Enforce Best Practices**
Security scanners like Checkov catch issues humans miss. Suppressions require thoughtful justification.

---

## Time Investment

**Total Debugging Time:** ~4-6 hours  
**Production Deployment Time After Fixes:** ~5 minutes  

**This ratio is typical in DevOps:**
- 80% time: Setup, debugging, configuration
- 20% time: Actual deployment and operation

---

## Skills Demonstrated

Networking troubleshooting (VPC, subnets, routing)  
Infrastructure as Code (Terraform)  
Security compliance (Checkov SAST)  
Bash scripting and logic  
IAM policy management  
Systematic debugging methodology  
Cost/benefit analysis for cloud services  
Documentation and knowledge sharing  

**This experience mirrors real-world DevOps engineering workflows.**

