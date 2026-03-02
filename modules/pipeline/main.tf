# ============================================================================
# Pipeline Module - CodePipeline, CodeBuild, S3
# ============================================================================
# Purpose: CI/CD automation with SAST security scanning
# PCI-DSS: Requirements 6.2 (Vulnerability Management), 6.3 (Secure SDLC)
# ============================================================================

# ============================================================================
# S3 Bucket for Pipeline Artifacts
# ============================================================================

# checkov:skip=CKV2_AWS_62:Event notifications not required for dev pipeline artifacts
# checkov:skip=CKV_AWS_144:Cross-region replication is cost-prohibitive for dev environment
resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "${var.project_name}-${var.environment}-artifacts-"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-artifacts"
    }
  )
}

# Enable versioning for artifact integrity
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ✅ FIXED: Lifecycle policy with filter block
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    # ✅ NEW: Add filter to apply rule to all objects
    filter {}

    expiration {
      days = var.s3_artifact_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ============================================================================
# S3 Bucket for Access Logs
# ============================================================================

# checkov:skip=CKV2_AWS_62:Event notifications not required for dev access logs
# checkov:skip=CKV_AWS_144:Cross-region replication is cost-prohibitive for dev environment
resource "aws_s3_bucket" "access_logs" {
  bucket_prefix = "${var.project_name}-${var.environment}-access-logs-"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-access-logs"
    }
  )
}

# Enable versioning for access logs bucket
resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# ✅ FIXED: Lifecycle with filter block
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    # ✅ NEW: Add filter to apply rule to all objects
    filter {}

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Enable access logging on artifacts bucket
resource "aws_s3_bucket_logging" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "artifacts-access-logs/"
}

# ============================================================================
# CodeBuild Project for Security Scanning
# ============================================================================

resource "aws_codebuild_project" "security_scan" {
  name          = "${var.project_name}-${var.environment}-security-scan"
  description   = "SAST security scanning with Checkov"
  build_timeout = 15
  service_role  = var.codebuild_role_arn

  encryption_key = var.kms_key_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.build_compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "CHECKOV_ENABLED"
      value = var.enable_checkov_scan
    }

    environment_variable {
      name  = "CHECKOV_THRESHOLD"
      value = var.checkov_fail_threshold
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build-log"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  # ✅ COMMENTED OUT: VPC config causing S3 download timeout
  # For dev environment, CodeBuild doesn't need VPC access
  # Uncomment and add NAT Gateway or S3 VPC Endpoint for production
  # vpc_config {
  #   vpc_id             = var.vpc_id
  #   subnets            = var.subnet_ids
  #   security_group_ids = [var.security_group_id]
  # }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-security-scan"
    }
  )
}

# CloudWatch Log Group with 365-day retention and KMS encryption
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-security-scan"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-codebuild-logs"
    }
  )
}

# ============================================================================
# CodeStar Connection (for GitHub)
# ============================================================================

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-${var.environment}-github"
  provider_type = "GitHub"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-github-connection"
    }
  )
}

# ============================================================================
# CodePipeline
# ============================================================================

resource "aws_codepipeline" "main" {
  name     = "${var.project_name}-${var.environment}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"

    encryption_key {
      id   = var.kms_key_arn
      type = "KMS"
    }
  }

  # Stage 1: Source from GitHub
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "AuthaHub/${var.source_repo_name}"
        BranchName       = var.source_repo_branch
        DetectChanges    = true
      }
    }
  }

  # Stage 2: Security Scan (Checkov SAST)
  stage {
    name = "SecurityScan"

    action {
      name             = "Checkov-SAST"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["scan_output"]

      configuration = {
        ProjectName = aws_codebuild_project.security_scan.name
      }
    }
  }

  # Stage 3: Manual Approval Gate
  stage {
    name = "ApprovalGate"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Please review security scan results before deploying to production."
      }
    }
  }

  # Stage 4: Deploy (placeholder for future deployment logic)
  stage {
    name = "Deploy"

    action {
      name            = "DeployPlaceholder"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["scan_output"]

      configuration = {
        ProjectName = aws_codebuild_project.security_scan.name
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-pipeline"
    }
  )
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_region" "current" {}