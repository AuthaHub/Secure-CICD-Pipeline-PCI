# ============================================================================
# Terraform Outputs
# ============================================================================
# Purpose: Exposes important resource attributes after deployment
# PCI-DSS: Provides audit trail and resource verification
# ============================================================================

# ============================================================================
# Networking Outputs
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "security_group_id" {
  description = "ID of the CodeBuild security group"
  value       = module.networking.security_group_id
}

# ============================================================================
# Security Outputs
# ============================================================================

output "kms_key_id_dev" {
  description = "KMS key ID for dev environment"
  value       = module.security.kms_key_id
  sensitive   = true
}

output "kms_key_arn_dev" {
  description = "KMS key ARN for dev environment"
  value       = module.security.kms_key_arn
}

output "codepipeline_role_arn" {
  description = "ARN of CodePipeline service role"
  value       = module.security.codepipeline_role_arn
}

output "codebuild_role_arn" {
  description = "ARN of CodeBuild service role"
  value       = module.security.codebuild_role_arn
}

# ============================================================================
# Pipeline Outputs
# ============================================================================

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.pipeline.pipeline_name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = module.pipeline.pipeline_arn
}

output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = module.pipeline.artifact_bucket_name
}

output "artifact_bucket_arn" {
  description = "ARN of the S3 artifact bucket"
  value       = module.pipeline.artifact_bucket_arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.pipeline.codebuild_project_name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = module.pipeline.codebuild_project_arn
}

# ============================================================================
# General Outputs
# ============================================================================

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "deployment_timestamp" {
  description = "Timestamp of Terraform deployment"
  value       = timestamp()
}

# ============================================================================
# Console URLs (Convenience)
# ============================================================================

output "pipeline_console_url" {
  description = "AWS Console URL for CodePipeline"
  value       = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${module.pipeline.pipeline_name}/view?region=${var.aws_region}"
}

output "codebuild_console_url" {
  description = "AWS Console URL for CodeBuild project"
  value       = "https://console.aws.amazon.com/codesuite/codebuild/projects/${module.pipeline.codebuild_project_name}?region=${var.aws_region}"
}

output "s3_console_url" {
  description = "AWS Console URL for S3 artifact bucket"
  value       = "https://s3.console.aws.amazon.com/s3/buckets/${module.pipeline.artifact_bucket_name}?region=${var.aws_region}"
}