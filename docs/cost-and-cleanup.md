# Cost Analysis & Cleanup Guide

**Project:** Secure CI/CD Pipeline with PCI-DSS Compliance  
**Author:** AuthaHub  
**Last Updated:** March 3, 2026  
**Purpose:** Document AWS costs, optimization strategies, and resource cleanup procedures

---

## Table of Contents

1. [Cost Breakdown](#cost-breakdown)
2. [Cost Optimization Strategies](#cost-optimization-strategies)
3. [Cost Comparison: Dev vs Production](#cost-comparison-dev-vs-production)
4. [Resource Cleanup Procedures](#resource-cleanup-procedures)
5. [Cost Monitoring](#cost-monitoring)
6. [Budget Recommendations](#budget-recommendations)

---

## Cost Breakdown

### Monthly Operating Costs (Dev Environment)

| Service | Resource | Quantity | Unit Cost | Monthly Cost | Notes |
|---------|----------|----------|-----------|--------------|-------|
| **KMS** | Customer-managed key | 1 | $1.00/month | **$1.00** | Required for encryption |
| **VPC Endpoints** | Interface endpoints | 2 | $7.20/month each | **$14.40** | CodeBuild, Secrets Manager |
| **S3** | Artifact storage | ~20 GB | $0.023/GB | **$0.46** | Versioned objects |
| **S3** | Access logs | ~1 GB | $0.023/GB | **$0.02** | Server access logs |
| **CodePipeline** | Pipeline execution | 1 | $1.00/month (free tier) | **$0.00** | First pipeline free |
| **CodeBuild** | Build minutes | ~60 min/month | $0.005/min (SMALL) | **$0.30** | 20 builds × 3 min |
| **CloudWatch Logs** | Log ingestion | ~5 GB | $0.50/GB | **$2.50** | Pipeline + build logs |
| **CloudWatch Logs** | Log storage | ~5 GB | $0.03/GB | **$0.15** | 365-day retention |
| **VPC Flow Logs** | Log generation | Minimal | ~$0.50/GB | **$0.50** | Network monitoring |
| | | | **TOTAL** | **~$19.33/month** | |

### Annual Cost Estimate

```
$19.33/month × 12 months = ~$232/year (Dev Environment)
```

---

## Cost Optimization Strategies

### 1. NAT Gateway Elimination (Saved $32/month)

**Original Design:**
- CodeBuild in private subnet → NAT Gateway for internet access
- NAT Gateway cost: $0.045/hour = $32.40/month

**Optimized Design:**
- CodeBuild in AWS-managed VPC (default)
- Uses AWS public networking (no NAT Gateway needed)
- **Savings: $32.40/month ($388.80/year)**

**Trade-off:**
- **Pro:** Significant cost reduction for dev environment
- **Con:** Less network isolation (acceptable for non-production)
- **Pro:** Simpler architecture (fewer components to manage)
- **Con:** Production should use private subnets with NAT Gateway

---

### 2. S3 Lifecycle Policies

**Configuration:**
```hcl
lifecycle_rule {
  enabled = true
  
  # Delete non-current versions after 30 days
  noncurrent_version_expiration {
    days = 30
  }
  
  # Delete objects after 90 days
  expiration {
    days = 90
  }
}
```

**Impact:**
- Prevents indefinite storage growth
- Estimated savings: $5-10/month over 6 months
- Balance between rollback capability and cost

**Rollback Window:**
- 30 days for version history
- 90 days for current artifacts
- Adequate for non-production environment

---

### 3. CodeBuild Compute Type Selection

**Options:**

| Compute Type | vCPU | RAM | Cost/Minute | 60 min/month | Notes |
|--------------|------|-----|-------------|--------------|-------|
| **SMALL** (chosen) | 2 | 3 GB | $0.005 | **$0.30** | Adequate for Checkov scans |
| MEDIUM | 4 | 7 GB | $0.010 | $0.60 | Overkill for this workload |
| LARGE | 8 | 15 GB | $0.020 | $1.20 | Unnecessary for IaC scanning |

**Decision Rationale:**
- Checkov scan completes in ~2-3 minutes on SMALL
- No performance issues observed
- **Savings: $0.30/month vs MEDIUM ($3.60/year)**

---

### 4. Log Retention Strategy

**CloudWatch Logs:**
- **Retention:** 365 days (PCI-DSS compliance requirement)
- **Cannot reduce:** Required for audit trail
- **Cost:** ~$2.65/month for ingestion + storage

**Alternative (not chosen):**
- Export logs to S3 after 30 days → CloudWatch to S3 Glacier
- Estimated savings: $1.50/month
- Complexity: Requires Lambda function, S3 lifecycle policies
- **Decision:** Not implemented for dev environment (overhead not justified)

---

### 5. VPC Endpoint Strategy

**Current Configuration:**

| Endpoint Type | Service | Cost | Decision |
|---------------|---------|------|----------|
| **Gateway** | S3 | Free | Keep (no cost) |
| **Interface** | CodeBuild | $7.20/month | Keep (demonstration value) |
| **Interface** | Secrets Manager | $7.20/month | Keep (demonstration value) |

**Alternative (maximum cost savings):**
- Remove VPC entirely (save $14.40/month)
- Lose demonstration of VPC endpoint architecture
- **Decision:** Keep for portfolio demonstration

---

## Cost Comparison: Dev vs Production

### Development Environment (Current)

**Monthly Cost:** ~$19.33/month  
**Annual Cost:** ~$232/year

**Characteristics:**
- Single region (us-east-1)
- No NAT Gateway (uses default VPC networking)
- 90-day artifact retention
- Minimal build frequency (~20 builds/month)
- No cross-region replication
- No disaster recovery

---

### Production Environment (Estimated)

**Monthly Cost:** ~$85-120/month  
**Annual Cost:** ~$1,020-1,440/year

**Additional Components:**

| Component | Cost | Rationale |
|-----------|------|-----------|
| **NAT Gateway** | $32.40/month | Private subnet internet access |
| **Cross-region S3 replication** | ~$20/month | Disaster recovery |
| **Increased build frequency** | ~$5/month | More deployments |
| **CloudWatch alarms** | $0.50/month | 5 alarms × $0.10 each |
| **SNS notifications** | $0.50/month | Approval notifications |
| **CloudTrail** | $2.00/month | Compliance auditing |
| **WAF (optional)** | $5-10/month | API protection |
| **VPC Endpoints (additional)** | $14.40/month | More services |

**Total Estimated Cost:** $85-120/month

**Production Requirements:**
- Multi-region deployment (2× costs)
- 24/7 monitoring and alerting
- Cross-region replication for DR
- Enhanced security controls
- Compliance auditing (CloudTrail)

---

### Staging Environment (Estimated)

**Monthly Cost:** ~$35-50/month  
**Annual Cost:** ~$420-600/year

**Configuration:**
- Similar to production but smaller scale
- Single region (cost savings vs production)
- NAT Gateway for network isolation
- Limited cross-region replication
- Reduced build frequency

---

### Cost Summary by Environment

| Environment | Monthly | Annual | Use Case |
|-------------|---------|--------|----------|
| **Development** | $19.33 | $232 | Portfolio demonstration, testing |
| **Staging** | $35-50 | $420-600 | Pre-production validation |
| **Production** | $85-120 | $1,020-1,440 | Live workloads, full DR |

---

## Resource Cleanup Procedures

### Option 1: Full Teardown (Zero Cost)

**Use case:** Project complete, no longer need infrastructure

**Steps:**

1. **Empty S3 Buckets First** (Terraform can't delete non-empty buckets)

```bash
# List buckets to get names
aws s3 ls | grep secure-cicd-pci-dev

# Force delete all objects and versions from artifacts bucket
aws s3 rm s3://secure-cicd-pci-dev-artifacts-XXXXXXXXX --recursive
aws s3api delete-objects --bucket secure-cicd-pci-dev-artifacts-XXXXXXXXX \
  --delete "$(aws s3api list-object-versions --bucket secure-cicd-pci-dev-artifacts-XXXXXXXXX \
  --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Force delete access logs bucket
aws s3 rm s3://secure-cicd-pci-dev-access-logs-XXXXXXXXX --recursive
aws s3 rb s3://secure-cicd-pci-dev-access-logs-XXXXXXXXX --force
```

2. **Run Terraform Destroy**

```bash
cd /path/to/Secure-CICD-Pipeline-PCI
terraform destroy
```

3. **Verify Deletion**

```bash
# Check for remaining resources
aws s3 ls | grep secure-cicd-pci
aws kms list-keys | grep secure-cicd-pci
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*secure-cicd-pci*"
```

**Expected Result:** $0/month (all resources deleted)

---

### Option 2: Partial Teardown (Minimize Cost)

**Use case:** Keep project for demos but reduce costs

**Strategy:** Remove expensive components, keep lightweight resources

**Steps:**

1. **Remove VPC Endpoints** (Save $14.40/month)

```bash
# Destroy only VPC endpoints
terraform destroy -target=module.networking.aws_vpc_endpoint.codebuild
terraform destroy -target=module.networking.aws_vpc_endpoint.secretsmanager
```

2. **Shorten S3 Lifecycle Policies** (Save $2-3/month)

Edit `modules/pipeline/main.tf`:
```hcl
lifecycle_rule {
  enabled = true
  
  noncurrent_version_expiration {
    days = 7  # Changed from 30
  }
  
  expiration {
    days = 30  # Changed from 90
  }
}
```

Then apply:
```bash
terraform apply
```

3. **Reduce Log Retention** (⚠️ Not recommended for compliance)

Edit `main.tf`:
```hcl
resource "aws_cloudwatch_log_group" "pipeline_logs" {
  retention_in_days = 30  # Changed from 365
}
```

**New Monthly Cost:** ~$5-7/month

**Remaining Resources:**
- KMS key ($1/month)
- S3 buckets with minimal storage (~$1/month)
- CloudWatch logs (reduced retention, ~$1/month)
- VPC and networking (free tier)
- VPC Endpoints removed (saved $14.40/month)

---

### Option 3: Pause (No New Costs)

**Use case:** Temporarily stop using but keep infrastructure

**Strategy:** Don't trigger any builds, let lifecycle policies delete old data

**Actions:**
1. Don't push code to GitHub (no pipeline triggers)
2. S3 lifecycle policies auto-delete old artifacts
3. CloudWatch logs stay within retention period

**Monthly Cost:** ~$19/month (baseline infrastructure remains)

**Resume:** Simply push code to trigger pipeline again

---

### Option 4: Archive for Portfolio

**Use case:** Keep as portfolio piece but minimize cost

**Strategy:** Destroy infrastructure, keep code and documentation

**Steps:**

1. **Take final screenshots** (for portfolio)
   - Pipeline view (all stages)
   - CodeBuild configuration
   - S3 buckets with encryption
   - KMS key with rotation

2. **Export cost analysis**
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-03-01,End=2026-03-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter file://cost-filter.json
```

3. **Destroy all infrastructure**
```bash
terraform destroy
```

4. **Keep GitHub repository**
   - Code remains accessible
   - Documentation preserved
   - Architecture diagrams available
   - README.md shows final pipeline screenshots

**Monthly Cost:** $0 (all AWS resources deleted)  
**Portfolio Value:** High (code + docs demonstrate skills)

---

## Cost Monitoring

### AWS Cost Explorer Setup

**Create custom cost report:**

1. Navigate to: https://console.aws.amazon.com/cost-management/home
2. Click: **Cost Explorer** → **Reports** → **Create report**
3. Configure:
   - **Report name:** secure-cicd-pci-dev-monthly
   - **Granularity:** Monthly
   - **Group by:** Service
   - **Filter by tags:** Project = secure-cicd-pci-dev

---

### Budget Alerts

**Create budget alarm:**

```bash
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

**budget.json:**
```json
{
  "BudgetName": "secure-cicd-pci-dev-budget",
  "BudgetLimit": {
    "Amount": "25",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

**notifications.json:**
```json
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "your-email@example.com"
      }
    ]
  }
]
```

**Alert Thresholds:**
- 80% of budget ($20): Warning email
- 100% of budget ($25): Critical alert
- Forecasted to exceed: Predictive alert

---

### Cost Anomaly Detection

**Enable AWS Cost Anomaly Detection:**

1. Navigate to: AWS Cost Management Console
2. Enable: **Cost Anomaly Detection**
3. Configure threshold: Alert on spend > $5 above expected

**Example alert:**
```
Your AWS costs for secure-cicd-pci-dev increased by $10 
compared to expected spend of $20/month.

Detected anomaly: VPC Endpoint usage spike
```

---

## Budget Recommendations

### Conservative Budget (Learning Phase)

**Monthly:** $25-30  
**Purpose:** Accommodate unexpected costs, testing, experimentation

**Allocation:**
- Infrastructure baseline: $19/month
- Buffer for testing: $6/month
- Unexpected charges: $5/month

---

### Aggressive Budget (Cost-Conscious)

**Monthly:** $20-22  
**Purpose:** Strict cost control, minimal experimentation

**Requirements:**
- Monitor build frequency (limit to 20 builds/month)
- Aggressive S3 lifecycle policies (7-day retention)
- Consider removing VPC Endpoints if not actively demoing

---

### Production Budget (Enterprise)

**Monthly:** $100-150  
**Purpose:** Full-featured, production-ready infrastructure

**Includes:**
- Multi-region deployment
- Cross-region replication
- NAT Gateway
- Enhanced monitoring
- CloudTrail auditing
- WAF protection
- 24/7 availability

---

## Cost Optimization Checklist

**Before deploying:**
- [ ] Review compute types (SMALL vs MEDIUM)
- [ ] Set S3 lifecycle policies (30-90 day retention)
- [ ] Enable budget alerts ($25/month threshold)
- [ ] Consider VPC vs default networking trade-offs

**Monthly review:**
- [ ] Check Cost Explorer for unexpected charges
- [ ] Review S3 bucket sizes (lifecycle policies working?)
- [ ] Verify build frequency (within expected range?)
- [ ] Review CloudWatch log ingestion (any spikes?)

**Quarterly review:**
- [ ] Evaluate Reserved Instance opportunities (if high usage)
- [ ] Review VPC Endpoint usage (still demonstrating?)
- [ ] Consider archiving old logs to S3 Glacier
- [ ] Reassess environment needs (still need dev running?)

---

## Frequently Asked Questions

### Q: Can I reduce costs below $19/month?

**A:** Yes, with trade-offs:

| Action | Savings | Impact |
|--------|---------|--------|
| Remove VPC Endpoints | -$14.40/month | Lose VPC architecture demonstration |
| Shorten log retention to 30 days | -$1.50/month | Non-compliant with PCI-DSS |
| Use AWS-managed keys | -$1.00/month | Lose encryption control demonstration |

**Minimum viable cost:** ~$3-5/month (S3 + CodeBuild only)

---

### Q: What if I accidentally leave resources running?

**A:** Set up budget alerts (see [Budget Alerts](#budget-alerts))

**Worst-case scenario:**
- $19/month baseline = $0.63/day
- If forgotten for 1 month: ~$19 unintended cost
- **Mitigation:** Budget alert at $20 threshold

---

### Q: How do I verify all resources are deleted?

**A:** Run these verification commands:

```bash
# Check S3 buckets
aws s3 ls | grep secure-cicd-pci
# Expected: No output

# Check KMS keys
aws kms list-keys --query "Keys[*].KeyId" | xargs -I {} aws kms describe-key --key-id {} --query "KeyMetadata.Description" | grep secure-cicd-pci
# Expected: No output

# Check VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=Secure-CICD-Pipeline-PCI" --query "Vpcs[*].VpcId"
# Expected: []

# Check CodePipeline
aws codepipeline list-pipelines --query "pipelines[?starts_with(name, 'secure-cicd-pci')]"
# Expected: []
```

---

### Q: Should I keep the infrastructure running for my portfolio?

**A:** Depends on your job search timeline:

| Scenario | Recommendation | Cost |
|----------|----------------|------|
| **Actively interviewing** | Keep running for live demos | $19/month |
| **Not interviewing yet** | Destroy, keep screenshots | $0/month |
| **Need to show live system** | Keep running, minimize costs | $5-7/month (partial teardown) |

**Portfolio value:**
- Code + documentation = 90% of portfolio value
- Live demo = 10% additional value
- **Verdict:** Code/docs are sufficient for most cases

---

## Conclusion

**Dev Environment Summary:**
- **Current Cost:** ~$19.33/month (~$232/year)
- **Optimized:** Removed $32/month NAT Gateway
- **Production Estimate:** $85-120/month with full security controls

**Key Takeaways:**
1. Cost-conscious architecture is achievable without sacrificing learning value
2. Lifecycle policies and compute sizing have significant impact
3. Production environments require 4-5× dev costs for proper security/DR
4. Budget alerts prevent unexpected charges

**Recommendation:**
- Keep infrastructure running during active job search ($19/month investment)
- Destroy after securing position or if budget-constrained
- Code and documentation retain full portfolio value after teardown

---

## Resources

- [AWS Pricing Calculator](https://calculator.aws/)
- [AWS Cost Management Console](https://console.aws.amazon.com/cost-management/)
- [AWS Well-Architected Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/)
- [Terraform Cost Estimation](https://www.terraform.io/cloud-docs/cost-estimation)

---

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-03-03 | AuthaHub | Initial cost analysis documented |
| 2026-03-03 | AuthaHub | Added cleanup procedures |
| 2026-03-03 | AuthaHub | Documented budget recommendations |

---

**Review this document monthly to ensure costs remain within expected range.**