# Secure CI/CD Pipeline for PCI-DSS Compliance

## Project Status: COMPLETE & OPERATIONAL

**Latest Pipeline Run:** All stages passed  
**Security Scan:** 90 checks passed, 0 failed, 6 skipped (with documented justifications)  
**Deployment:** Fully automated with manual approval gate  

[View Troubleshooting Journey](docs/TROUBLESHOOTING_JOURNEY.md)  
[View Success Summary](docs/SUCCESS_SUMMARY.md)

> **Project A — "I Secure the Software Supply Chain"**  
> Demonstrates DevSecOps best practices with automated security scanning, secrets management, and Zero Trust architecture.

---

## Project Overview

This project implements a **PCI-DSS compliant CI/CD pipeline** using AWS services and Terraform to demonstrate enterprise-grade DevSecOps practices. The architecture focuses on **Requirements 6.2 (Security Vulnerabilities)** and **6.3 (Secure Development)**.

### Key Features

- **Automated Security Scanning** — SAST with Checkov blocking vulnerable deployments
- **Multi-Account Architecture** — Separate AWS accounts for dev/prod isolation
- **Zero Trust Security** — Least-privilege IAM roles and KMS encryption
- **Secrets Management** — AWS Secrets Manager (no hardcoded credentials)
- **Artifact Integrity** — S3 versioning, encryption, and signing
- **Compliance Gates** — Manual approval for production deployments
- **Infrastructure as Code** — Modular Terraform with state management

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Organizations                        │
├──────────────────────┬──────────────────────────────────────┤
│   Dev Account        │         Prod Account                  │
│  (Primary)           │        (Secondary)                    │
├──────────────────────┼──────────────────────────────────────┤
│ • CodePipeline       │ • Manual Approval Gate               │
│ • CodeBuild          │ • Encrypted Artifacts                │
│ • Checkov SAST       │ • Least Privilege IAM                │
│ • S3 + KMS           │ • S3 + KMS                           │
│ • Secrets Manager    │ • CloudWatch Logs                    │
└──────────────────────┴──────────────────────────────────────┘
```

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| **IaC** | Terraform (>= 1.0) |
| **CI/CD** | AWS CodePipeline, CodeBuild |
| **Security Scanning** | Checkov (SAST) |
| **Encryption** | AWS KMS |
| **Secrets** | AWS Secrets Manager |
| **Storage** | S3 with versioning |
| **IAM** | Least-privilege policies |
| **Region** | us-east-1 |

---

## Project Structure

```
.
├── main.tf                    # Root module orchestration
├── provider.tf                # AWS provider configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars           # Variable values (git-ignored)
│
├── modules/
│   ├── networking/            # VPC, subnets, security groups
│   ├── security/              # KMS, IAM, Secrets Manager
│   └── pipeline/              # CodePipeline, CodeBuild
│
└── docs/
    ├── progress-todo.md       # Build checklist
    ├── build-log.md           # Troubleshooting log
    ├── architecture-decisions.md  # Design rationale
    ├── cost-and-cleanup.md    # Cost analysis
    ├── screenshots/           # Phase-based screenshots
    └── scan-results/          # Checkov scan outputs
```

---

## Quick Start

### Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0
- Checkov installed (`pip install checkov`)
- Two AWS accounts (dev/prod)

### Deployment Steps

```bash
# 1. Clone repository
git clone https://github.com/AuthaHub/Secure-CICD-Pipeline-PCI.git
cd Secure-CICD-Pipeline-PCI

# 2. Initialize Terraform
terraform init

# 3. Run security scan
checkov -d . --framework terraform

# 4. Plan infrastructure
terraform plan -out=tfplan

# 5. Apply infrastructure
terraform apply tfplan
```

---

## Cost Breakdown

| Resource | Monthly Cost |
|----------|--------------|
| KMS Keys (2) | ~$2.00 |
| CodePipeline | ~$1.00 |
| S3 Buckets | ~$0.05 |
| CodeBuild | $0 (pay per build) |
| **Total** | **~$3-4/month** |

> **Cost-aware:** All resources are destroyed when not in use.

---

## Security Highlights

- **PCI-DSS 6.2** — Automated vulnerability scanning with Checkov
- **PCI-DSS 6.3** — Secure SDLC with approval gates and encryption
- **Zero Trust** — No long-lived credentials, IAM roles only
- **Encryption at Rest** — KMS-encrypted S3 artifacts
- **Least Privilege** — Scoped IAM policies per service
- **Audit Trail** — CloudWatch Logs for all pipeline actions

---

## Documentation

- [Progress & TODO](docs/progress-todo.md) — Step-by-step build checklist
- [Build Log](docs/build-log.md) — Troubleshooting and resolutions
- [Architecture Decisions](docs/architecture-decisions.md) — Design rationale
- [Cost & Cleanup](docs/cost-and-cleanup.md) — Resource destruction guide

---

## Connect

**Portfolio by AuthaHub**  
www.linkedin.com/in/darnellivy | github.com/authahub 

---

## License

This project is open-source for educational and portfolio purposes.

---

**If this project helped you, please star it!**