# ============================================================================
# Root Module - Secure CI/CD Pipeline for PCI-DSS Compliance
# ============================================================================
# Purpose: Orchestrates networking, security, and pipeline modules
# PCI-DSS Requirements: 6.2 (Security Vulnerabilities), 6.3 (Secure Development)
# Author: AuthaHub
# ============================================================================

# ============================================================================
# Local Variables
# ============================================================================

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Compliance  = "PCI-DSS"
      Owner       = "AuthaHub"
    },
    var.additional_tags
  )

  name_prefix = "${var.project_name}-${var.environment}"
}

# ============================================================================
# Security Module (Created First - KMS Key Needed by Other Modules)
# ============================================================================
# Creates: KMS Keys, IAM Roles, Policies
# Purpose: Encryption, authentication, and authorization

module "security" {
  source = "./modules/security"

  project_name            = var.project_name
  environment             = var.environment
  aws_account_id          = var.aws_account_id
  aws_region              = var.aws_region
  enable_kms_rotation     = var.enable_kms_rotation
  kms_deletion_window     = var.kms_deletion_window
  
  # Pass artifact bucket name from pipeline module (will be created in dependency)
  artifact_bucket_arn = module.pipeline.artifact_bucket_arn
  
  tags = local.common_tags
}

# ============================================================================
# Networking Module
# ============================================================================
# Creates: VPC, Subnets, Security Groups
# Purpose: Network isolation for pipeline resources

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  
  # ✅ FIXED: Pass kms_key_arn instead of kms_key_id
  kms_key_arn = module.security.kms_key_arn
  
  tags = local.common_tags
}

# ============================================================================
# Pipeline Module
# ============================================================================
# Creates: CodePipeline, CodeBuild, S3 Buckets
# Purpose: CI/CD automation with security scanning

module "pipeline" {
  source = "./modules/pipeline"

  project_name               = var.project_name
  environment                = var.environment
  aws_account_id             = var.aws_account_id
  aws_region                 = var.aws_region
  source_repo_name           = var.source_repo_name
  source_repo_branch         = var.source_repo_branch
  build_compute_type         = var.build_compute_type
  build_image                = var.build_image
  s3_artifact_retention_days = var.s3_artifact_retention_days
  enable_checkov_scan        = var.enable_checkov_scan
  checkov_fail_threshold     = var.checkov_fail_threshold
  
  # Dependencies from other modules
  kms_key_arn          = module.security.kms_key_arn
  codepipeline_role_arn = module.security.codepipeline_role_arn
  codebuild_role_arn    = module.security.codebuild_role_arn
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.private_subnet_ids
  security_group_id     = module.networking.security_group_id
  
  tags = local.common_tags
}

# ============================================================================
# Additional Resources (Optional)
# ============================================================================

# CloudWatch Log Group for centralized logging (365-day retention for compliance)
resource "aws_cloudwatch_log_group" "pipeline_logs" {
  name              = "/aws/codepipeline/${local.name_prefix}"
  retention_in_days = 365  # ✅ FIXED: Changed from 30 to 365 days for PCI-DSS compliance
  kms_key_id        = module.security.kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-pipeline-logs"
    }
  )
}

# SNS Topic for pipeline notifications (optional)
resource "aws_sns_topic" "pipeline_notifications" {
  name              = "${local.name_prefix}-pipeline-notifications"
  kms_master_key_id = module.security.kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-notifications"
    }
  )
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}