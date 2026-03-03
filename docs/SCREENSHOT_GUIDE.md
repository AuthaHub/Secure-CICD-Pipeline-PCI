# AWS Screenshot Evidence Guide

**Purpose:** Document deployed infrastructure for portfolio  
**Security:** Blur all sensitive information before committing  

---

## Screenshot Checklist

### 1. CodePipeline Overview
**Navigation:**
1. Go to: https://console.aws.amazon.com/codesuite/codepipeline/pipelines
2. Click: `secure-cicd-pci-dev-pipeline`

**What to Capture:**
- Pipeline stages (Source, SecurityScan, ApprovalGate, Deploy)
- Overall pipeline status

**File Name:** `screenshots/01-codepipeline-overview.png`

**Blur:**
- ❌ AWS Account ID (top-right corner)
- ❌ Full ARNs (if visible)
- ✅ Keep: Pipeline name, stages, status

---

### 2. CodeBuild Project Configuration
**Navigation:**
1. Go to: https://console.aws.amazon.com/codesuite/codebuild/projects
2. Click: `secure-cicd-pci-dev-security-scan`
3. Click: **Build details** tab

**What to Capture:**
- Project name
- Environment settings (image, compute type)
- VPC configuration
- Encryption settings (KMS key)

**File Name:** `screenshots/02-codebuild-config.png`

**Blur:**
- ❌ AWS Account ID
- ❌ KMS Key ID (full ID)
- ❌ VPC ID, Subnet IDs
- ✅ Keep: Project name, image type, compute type

---

### 3. S3 Buckets with Encryption
**Navigation:**
1. Go to: https://s3.console.aws.amazon.com/s3/buckets
2. Look for: `secure-cicd-pci-dev-artifacts-*`

**What to Capture:**
- Bucket list showing artifact and access-logs buckets
- Versioning enabled
- Encryption settings

**File Name:** `screenshots/03-s3-buckets.png`

**Blur:**
- ❌ Full bucket names (timestamps)
- ❌ AWS Account ID
- ✅ Keep: Bucket prefix, versioning status, encryption type (KMS)

---

### 4. KMS Key Configuration
**Navigation:**
1. Go to: https://console.aws.amazon.com/kms/home
2. Click: **Customer managed keys**
3. Click: `secure-cicd-pci-dev-kms-key`

**What to Capture:**
- Key alias/name
- Key rotation enabled
- Key policy (General configuration tab)

**File Name:** `screenshots/04-kms-key.png`

**Blur:**
- ❌ Full Key ID
- ❌ Key ARN
- ❌ AWS Account ID
- ✅ Keep: Key alias, rotation status

---

### 5. VPC Configuration
**Navigation:**
1. Go to: https://console.aws.amazon.com/vpc/home
2. Click: **Your VPCs**
3. Find: VPC with name tag containing `secure-cicd-pci-dev`

**What to Capture:**
- VPC name
- CIDR block (10.0.0.0/16)
- Flow logs enabled

**File Name:** `screenshots/05-vpc-overview.png`

**Blur:**
- ❌ VPC ID
- ❌ AWS Account ID
- ✅ Keep: VPC name, CIDR block, flow logs status

---

### 6. VPC Endpoints
**Navigation:**
1. Go to: https://console.aws.amazon.com/vpc/home
2. Click: **Endpoints** (left sidebar)
3. Filter by VPC: `secure-cicd-pci-dev`

**What to Capture:**
- List of endpoints (S3, CodeBuild, Secrets Manager)
- Endpoint types (Gateway, Interface)

**File Name:** `screenshots/06-vpc-endpoints.png`

**Blur:**
- ❌ Endpoint IDs
- ❌ VPC ID
- ✅ Keep: Service names, endpoint types

---

### 7. IAM Roles
**Navigation:**
1. Go to: https://console.aws.amazon.com/iam/home#/roles
2. Search: `secure-cicd-pci-dev`

**What to Capture:**
- CodePipeline role
- CodeBuild role
- VPC Flow Logs role

**File Name:** `screenshots/07-iam-roles.png`

**Blur:**
- ❌ AWS Account ID (in ARNs)
- ❌ Role ARNs (full)
- ✅ Keep: Role names, creation dates

---

### 8. CloudWatch Log Groups
**Navigation:**
1. Go to: https://console.aws.amazon.com/cloudwatch/home
2. Click: **Logs** → **Log groups**
3. Search: `secure-cicd-pci`

**What to Capture:**
- Log groups list
- Retention period (365 days)
- KMS encryption status

**File Name:** `screenshots/08-cloudwatch-logs.png`

**Blur:**
- ❌ AWS Account ID
- ❌ Full ARNs
- ✅ Keep: Log group names, retention periods

---

### 9. Security Groups
**Navigation:**
1. Go to: https://console.aws.amazon.com/vpc/home
2. Click: **Security Groups**
3. Search: `secure-cicd-pci-dev`

**What to Capture:**
- CodeBuild security group
- VPC endpoints security group
- Inbound/outbound rules

**File Name:** `screenshots/09-security-groups.png`

**Blur:**
- ❌ Security Group IDs
- ❌ VPC ID
- ✅ Keep: Group names, rule descriptions, ports

---

### 10. Terraform Outputs (Terminal)
**Navigation:**
1. In terminal, run: `terraform output`

**What to Capture:**
- Terminal output showing all outputs

**File Name:** `screenshots/10-terraform-outputs.png`

**Blur:**
- ❌ AWS Account IDs (in ARNs)
- ❌ Subnet IDs
- ❌ VPC ID
- ❌ S3 bucket full names
- ✅ Keep: Output names, resource prefixes

---

## Screenshot Folder Structure

```
screenshots/
├── 01-codepipeline-overview.png
├── 02-codebuild-config.png
├── 03-s3-buckets.png
├── 04-kms-key.png
├── 05-vpc-overview.png
├── 06-vpc-endpoints.png
├── 07-iam-roles.png
├── 08-cloudwatch-logs.png
├── 09-security-groups.png
└── 10-terraform-outputs.png
```

---

## Security Reminder

**NEVER commit screenshots with:**
- ❌ AWS Account IDs
- ❌ Full ARNs
- ❌ Resource IDs (VPC, Subnet, KMS Key, Security Group)
- ❌ S3 bucket timestamps
- ❌ IP addresses

**Use a tool like:**
- Windows: **Snipping Tool** (built-in blur/highlight)
- Third-party: **Greenshot**, **ShareX**
- Mac: **Skitch**, **CleanShot X**

---

**Status:** ⏳ Screenshots to be taken after Phase 4 (GitHub connection)