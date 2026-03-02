# ============================================================================
# Pipeline Module - Input Variables
# ============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "source_repo_name" {
  description = "Name of the source code repository"
  type        = string
}

variable "source_repo_branch" {
  description = "Branch to trigger pipeline"
  type        = string
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
}

variable "build_image" {
  description = "CodeBuild Docker image"
  type        = string
}

variable "s3_artifact_retention_days" {
  description = "Number of days to retain S3 artifacts"
  type        = number
}

variable "enable_checkov_scan" {
  description = "Enable Checkov SAST scanning"
  type        = bool
}

variable "checkov_fail_threshold" {
  description = "Checkov severity level to fail builds"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption"
  type        = string
}

variable "codepipeline_role_arn" {
  description = "ARN of CodePipeline IAM role"
  type        = string
}

variable "codebuild_role_arn" {
  description = "ARN of CodeBuild IAM role"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of subnets for CodeBuild"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of security group for CodeBuild"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}