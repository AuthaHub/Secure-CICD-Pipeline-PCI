# Architecture Design Decisions

**Project:** Secure CI/CD Pipeline with PCI-DSS Compliance  
**Author:** AuthaHub  
**Last Updated:** March 3, 2026  
**Purpose:** Document key architectural decisions, trade-offs, and technical rationale

---

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [Infrastructure as Code Approach](#infrastructure-as-code-approach)
3. [Security Architecture](#security-architecture)
4. [Networking Design](#networking-design)
5. [CI/CD Pipeline Design](#cicd-pipeline-design)
6. [Cost Optimization Decisions](#cost-optimization-decisions)
7. [Compliance Considerations](#compliance-considerations)
8. [Future Enhancements](#future-enhancements)

---

## Technology Stack

### Infrastructure as Code: Terraform

**Decision:** Use Terraform over AWS CloudFormation

**Rationale:**
- **Multi-cloud portability:** Terraform supports multiple cloud providers (future flexibility)
- **State management:** Explicit state file makes infrastructure tracking transparent
- **Module ecosystem:** Large community with reusable modules
- **HCL syntax:** More readable than CloudFormation JSON/YAML for complex logic
- **Industry standard:** Widely adopted in DevOps roles (career relevance)

**Trade-offs:**
- ✅ **Pro:** Declarative syntax, plan/apply workflow prevents accidental changes
- ❌ **Con:** Requires external state management (S3 backend) for team collaboration
- ✅ **Pro:** Dry-run capability (`terraform plan`) before making changes
- ❌ **Con:** Learning curve for HCL syntax and provider-specific resources

---

### CI/CD Platform: AWS CodePipeline + CodeBuild

**Decision:** Use AWS-native CI/CD services over Jenkins/GitLab CI

**Rationale:**
- **Serverless:** No infrastructure to manage (EC2 instances, patching, scaling)
- **Cost-effective:** Pay-per-use model (no idle server costs)
- **AWS integration:** Native IAM roles, VPC networking, KMS encryption
- **Simplicity:** Reduced operational overhead for small teams/projects
- **PCI-DSS alignment:** AWS services have compliance certifications

**Trade-offs:**
- ✅ **Pro:** No maintenance burden, automatic scaling, built-in logging
- ❌ **Con:** Vendor lock-in to AWS ecosystem
- ✅ **Pro:** Integrated security (KMS, IAM, VPC)
- ❌ **Con:** Less flexible than Jenkins for complex workflows

**Alternatives Considered:**
| Tool | Why Not Chosen |
|------|----------------|
| **Jenkins** | Requires EC2 instance management, patching, security hardening |
| **GitLab CI** | Additional service cost, requires GitLab repository hosting |
| **GitHub Actions** | Works well but wanted to demonstrate AWS expertise |
| **CircleCI/Travis** | Third-party service, less control over security posture |

---

### Security Scanning: Checkov (SAST)

**Decision:** Integrate Checkov for static application security testing

**Rationale:**
- **Infrastructure-focused:** Designed specifically for IaC (Terraform, CloudFormation)
- **Policy-as-code:** Detects misconfigurations before deployment
- **Open-source:** No licensing costs, active community
- **CI/CD integration:** Easy to embed in CodeBuild buildspec
- **Compliance mapping:** Checks map to PCI-DSS, HIPAA, CIS benchmarks

**Implementation Details:**
```bash
# Buildspec integration with soft-fail for controlled exceptions
checkov -d . --soft-fail --output junitxml > checkov-report.xml
```

**Trade-offs:**
- ✅ **Pro:** Catches 90+ security issues automatically
- ❌ **Con:** Some checks require business justification to suppress (e.g., cross-region replication)
- ✅ **Pro:** Fast execution (~30 seconds for this project)
- ❌ **Con:** False positives require manual review and suppression comments

---

## Infrastructure as Code Approach

### Modular Terraform Design

**Decision:** Organize Terraform into reusable modules (security, networking, pipeline)

**Rationale:**
- **Separation of concerns:** Each module has a single responsibility
- **Reusability:** Modules can be used across dev/staging/prod environments
- **Testing:** Easier to test individual components in isolation
- **Collaboration:** Team members can work on different modules without conflicts
- **Maintainability:** Changes to networking don't affect pipeline configuration

**Module Structure:**
```
modules/
├── security/       # KMS keys, IAM roles, policies
├── networking/     # VPC, subnets, security groups, endpoints
└── pipeline/       # CodePipeline, CodeBuild, S3 buckets
```

**Dependency Management:**
- Security module creates KMS key → used by networking and pipeline
- Networking module creates VPC → used by CodeBuild for private builds
- Pipeline module creates S3 buckets → referenced by security module for IAM policies

**Trade-offs:**
- ✅ **Pro:** Clear boundaries, easier to understand and modify
- ❌ **Con:** Module dependencies require careful ordering (security → networking → pipeline)
- ✅ **Pro:** Can version modules independently in future
- ❌ **Con:** Initial setup more complex than monolithic configuration

---

### Variable-Driven Configuration

**Decision:** Use `terraform.tfvars` for environment-specific values

**Rationale:**
- **Environment isolation:** Same code deploys to dev/staging/prod with different values
- **Security:** Sensitive values (AWS account ID) marked as `sensitive = true`
- **Validation:** Input validation prevents invalid configurations (e.g., environment must be dev/staging/prod)
- **Documentation:** Variable descriptions serve as inline documentation

**Example:**
```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

---

## Security Architecture

### Encryption at Rest: AWS KMS

**Decision:** Use customer-managed KMS keys instead of AWS-managed keys

**Rationale:**
- **Control:** Full control over key rotation, access policies, deletion
- **Audit trail:** CloudTrail logs all key usage for compliance
- **Cross-service encryption:** Single key encrypts S3, CloudWatch, CodeBuild
- **PCI-DSS requirement:** Customer-managed keys demonstrate due diligence

**Key Policy Design:**
- Least-privilege access (only CodePipeline, CodeBuild, CloudWatch can use key)
- Condition-based restrictions (services can only decrypt artifacts they own)
- Automatic key rotation enabled (365-day cycle)

**Trade-offs:**
- ✅ **Pro:** Enhanced security posture, compliance alignment
- ❌ **Con:** $1/month cost vs free AWS-managed keys
- ✅ **Pro:** Granular access control via IAM policies
- ❌ **Con:** More complex to manage (key policies + IAM policies)

---

### IAM Least-Privilege Policies

**Decision:** Scope IAM permissions to specific resources, not wildcards

**Rationale:**
- **Security:** Limits blast radius if credentials are compromised
- **Compliance:** PCI-DSS Requirement 7.1 (limit access by business need-to-know)
- **Auditability:** Clear policy statements make security reviews easier
- **Defense-in-depth:** Multiple layers of access control

**Example Pattern:**
```json
{
  "Effect": "Allow",
  "Action": ["codebuild:CreateReportGroup"],
  "Resource": [
    "arn:aws:codebuild:us-east-1:ACCOUNT_ID:report-group/secure-cicd-pci-dev-*"
  ]
}
```

**vs. Overprivileged (avoided):**
```json
{
  "Effect": "Allow",
  "Action": ["codebuild:*"],
  "Resource": "*"  # ❌ Too broad
}
```

---

### Security Scanning Integration

**Decision:** Block deployments on critical/high security findings

**Rationale:**
- **Shift-left security:** Catch issues before they reach production
- **Automated enforcement:** No manual review required for common issues
- **Fail-fast:** Pipeline stops immediately on security violations
- **Documented exceptions:** Suppressed checks require business justification

**Threshold Configuration:**
```bash
# Block deployment if any of these severities are found
CHECKOV_THRESHOLD="CRITICAL"  # Can be: CRITICAL, HIGH, MEDIUM, LOW
```

**Exception Handling:**
```hcl
# Example: Documented suppression for dev environment
# checkov:skip=CKV_AWS_144:Cross-region replication is cost-prohibitive for dev environment
resource "aws_s3_bucket" "artifacts" {
  # ... configuration
}
```

---

## Networking Design

### VPC Configuration (Dev Environment)

**Decision:** Remove VPC configuration for dev environment to reduce costs

**Rationale:**
- **Cost savings:** Eliminates $32/month NAT Gateway requirement
- **Simplicity:** Fewer networking components to manage and troubleshoot
- **Acceptable risk:** Dev environment does not handle production data
- **Documented trade-off:** Production will require VPC with proper egress routing

**Original Architecture (Production-ready):**
```
┌─────────────────────────────────────────┐
│ VPC (10.0.0.0/16)                       │
│  ┌───────────────────────────────────┐  │
│  │ Private Subnets                   │  │
│  │ • CodeBuild                       │  │
│  │ • No internet access              │  │
│  ��───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ NAT Gateway (Public Subnet)       │  │
│  │ • $32/month                       │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ VPC Endpoints                     │  │
│  │ • S3 (Gateway - Free)             │  │
│  │ • CodeBuild (Interface - $7/mo)   │  │
│  │ • Secrets Mgr (Interface - $7/mo) │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**Dev Environment Decision:**
- Removed NAT Gateway (saved $32/month)
- Kept VPC Endpoints for demonstration purposes ($14.40/month)
- CodeBuild runs in AWS-managed VPC (no private subnet isolation)

**Production Requirements:**
- Full VPC implementation with NAT Gateway OR VPC Endpoints
- Network isolation for CodeBuild
- VPC Flow Logs for network traffic monitoring
- Private subnet routing through NAT Gateway for internet access

---

### VPC Endpoints

**Decision:** Use VPC Gateway Endpoint for S3, Interface Endpoints for CodeBuild/Secrets Manager

**Rationale:**
- **S3 Gateway Endpoint:** Free, routes S3 traffic through VPC without internet
- **Interface Endpoints:** Required for CodeBuild and Secrets Manager in private subnets
- **Security:** Keeps traffic within AWS network (not traversing internet)
- **Compliance:** Demonstrates network isolation best practices

**Cost Breakdown:**
| Endpoint Type | Service | Cost |
|---------------|---------|------|
| Gateway | S3 | Free |
| Interface | CodeBuild | $7.20/month |
| Interface | Secrets Manager | $7.20/month |

---

## CI/CD Pipeline Design

### Pipeline Stages

**Decision:** Four-stage pipeline (Source → SecurityScan → ApprovalGate → Deploy)

**Rationale:**
- **Source:** Automated trigger on GitHub commits (webhook-based)
- **SecurityScan:** Checkov SAST catches infrastructure misconfigurations
- **ApprovalGate:** Manual review before production (compliance requirement)
- **Deploy:** Placeholder for actual deployment logic (future expansion)

**Stage Flow:**
```
GitHub Push → CodePipeline → CodeBuild (Checkov) → Manual Approval → Deploy
```

**Why Manual Approval:**
- PCI-DSS requires human review for production changes
- Allows security team to verify scan results
- Prevents accidental deployments
- Demonstrates separation of duties

---

### Artifact Management

**Decision:** S3 with versioning, encryption, and lifecycle policies

**Rationale:**
- **Versioning:** Rollback capability if deployment fails
- **Encryption:** KMS-encrypted at rest (PCI-DSS requirement)
- **Lifecycle policies:** Auto-delete old artifacts after 90 days (cost optimization)
- **Access logging:** Audit trail of who accessed artifacts

**Lifecycle Configuration:**
```hcl
lifecycle_rule {
  enabled = true
  
  noncurrent_version_expiration {
    days = 30  # Delete old versions after 30 days
  }
  
  expiration {
    days = 90  # Delete current version after 90 days
  }
}
```

---

## Cost Optimization Decisions

### Dev vs. Production Trade-offs

**Decision:** Optimize dev environment for cost, not maximum security/isolation

**Cost Comparison:**

| Component | Dev Cost | Production Cost | Decision |
|-----------|----------|-----------------|----------|
| NAT Gateway | $0 | $32/month | Removed in dev |
| VPC Endpoints | $14.40/month | $14.40/month | Kept for demo |
| Cross-region replication | $0 | ~$20/month | Skipped in dev |
| KMS encryption | $1/month | $1/month | Non-negotiable |
| Log retention | 365 days | 365 days | Non-negotiable |

**Dev Environment Total:** ~$17.50/month  
**Production Environment Estimate:** $80-120/month

**Rationale:**
- Dev environment focuses on learning and portfolio demonstration
- Production would require full security controls regardless of cost
- All cost decisions documented in code comments for transparency

---

### Build Compute Sizing

**Decision:** Use `BUILD_GENERAL1_SMALL` for CodeBuild

**Rationale:**
- **Sufficient resources:** 3 GB RAM, 2 vCPUs handles Checkov scanning
- **Cost-effective:** $0.005/minute vs $0.01/minute for MEDIUM
- **Fast enough:** Builds complete in ~2-3 minutes
- **Scalable:** Can upgrade to MEDIUM/LARGE if needed

**Cost Analysis:**
```
Assumptions: 20 builds/month, 3 minutes/build

SMALL:  20 builds × 3 min × $0.005/min = $0.30/month
MEDIUM: 20 builds × 3 min × $0.01/min  = $0.60/month
LARGE:  20 builds × 3 min × $0.02/min  = $1.20/month

Decision: SMALL ($0.30/month) is adequate for this workload
```

---

## Compliance Considerations

### PCI-DSS Alignment

**Requirements Addressed:**

| Requirement | Implementation |
|-------------|----------------|
| **3.4** - Encryption at rest | KMS customer-managed keys for S3, CloudWatch |
| **6.2** - Security vulnerabilities | Checkov automated scanning on every commit |
| **6.3** - Secure development | Approval gate before production deployment |
| **7.1** - Access control | IAM least-privilege policies |
| **10.7** - Audit trail retention | 365-day CloudWatch log retention |
| **12.8** - Vendor compliance | AWS services with PCI-DSS certification |

**Documentation Strategy:**
- All security decisions documented in code comments
- Checkov suppression comments explain why checks are skipped
- Architecture decisions documented in this file

---

### Audit Logging

**Decision:** Enable VPC Flow Logs, S3 Access Logs, and CloudWatch Logs

**Rationale:**
- **VPC Flow Logs:** Network-level visibility (detect anomalous traffic)
- **S3 Access Logs:** Track who accessed artifacts (compliance requirement)
- **CloudWatch Logs:** Application-level logging (CodeBuild execution logs)
- **365-day retention:** Meets PCI-DSS Requirement 10.7

**Log Aggregation:**
```
VPC Flow Logs → CloudWatch Log Group (KMS-encrypted, 365-day retention)
S3 Access Logs → Separate S3 bucket (lifecycle policies, KMS-encrypted)
CodeBuild Logs → CloudWatch Log Group (KMS-encrypted, 365-day retention)
```

---

## Future Enhancements

### Short-Term (Next 3-6 Months)

**1. Multi-Environment Support**
- Create separate `dev`, `staging`, `prod` workspaces
- Use Terraform workspaces or separate state files
- Variable-driven configuration for environment-specific settings

**2. Remote State Management**
- Configure S3 backend with DynamoDB state locking
- Enable state file encryption
- Implement state file versioning

**3. Enhanced Security Scanning**
- Add Trivy for container image scanning
- Integrate OWASP Dependency-Check for third-party libraries
- Add TFSec for additional Terraform security checks

**4. Automated Testing**
- Terratest for infrastructure testing
- Terraform validate in pre-commit hooks
- Integration tests after deployment

---

### Medium-Term (6-12 Months)

**1. Multi-Account Architecture**
- Separate AWS accounts for dev/staging/prod
- AWS Organizations with Service Control Policies (SCPs)
- Cross-account IAM role assumption

**2. Secrets Management**
- Migrate hardcoded values to AWS Secrets Manager
- Rotate secrets automatically
- Dynamic secrets for database credentials

**3. Monitoring & Alerting**
- CloudWatch alarms for pipeline failures
- SNS notifications for manual approval requests
- Dashboards for pipeline metrics (build duration, success rate)

**4. Disaster Recovery**
- Cross-region S3 replication for artifacts
- Multi-region CodePipeline deployment
- Automated backup and restore procedures

---

### Long-Term (12+ Months)

**1. GitOps Workflow**
- ArgoCD for Kubernetes deployments
- Pull-based deployment model
- Infrastructure drift detection

**2. Policy as Code**
- Open Policy Agent (OPA) for custom compliance policies
- Automated policy enforcement
- Policy version control

**3. Cost Optimization Automation**
- AWS Cost Anomaly Detection
- Automated rightsizing recommendations
- Reserved Instance/Savings Plan analysis

---

## Lessons Learned

### What Went Well

1. **Modular Terraform design** made debugging easier (isolated issues to specific modules)
2. **Checkov integration** caught 6 security issues before deployment
3. **Systematic troubleshooting** (documented in TROUBLESHOOTING_JOURNEY.md) built institutional knowledge
4. **Cost-conscious decisions** kept dev environment under $20/month

### What Could Be Improved

1. **State management:** Local state file is not suitable for team collaboration (need S3 backend)
2. **Testing:** No automated tests for Terraform code (should add Terratest)
3. **Monitoring:** Limited visibility into pipeline performance (add CloudWatch dashboards)
4. **Secrets:** Some values in `terraform.tfvars` (should use Secrets Manager)

### Technical Debt

| Item | Priority | Effort | Impact |
|------|----------|--------|--------|
| Implement S3 backend for Terraform state | High | 2 hours | Team collaboration |
| Add Terratest for infrastructure testing | Medium | 8 hours | Code quality |
| Migrate to AWS Secrets Manager | Medium | 4 hours | Security posture |
| Implement multi-account architecture | Low | 16 hours | Production readiness |

---

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [PCI-DSS Requirements](https://www.pcisecuritystandards.org/)
- [Checkov Documentation](https://www.checkov.io/1.Welcome/What%20is%20Checkov.html)
- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/)

---

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-03-03 | AuthaHub | Initial architecture decisions documented |
| 2026-03-03 | AuthaHub | Added VPC configuration rationale |
| 2026-03-03 | AuthaHub | Documented cost optimization decisions |

---

**This document should be reviewed and updated as architecture evolves.**