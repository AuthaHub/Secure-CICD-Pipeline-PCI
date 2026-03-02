# ============================================================================
# Input Variables for Secure CI/CD Pipeline
# ============================================================================
# Purpose: Defines configurable parameters for the infrastructure
# PCI-DSS: Supports flexible, secure configuration management
# ============================================================================

# ============================================================================
# General Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "secure-cicd-pci"
}

variable "aws_account_id" {
  description = "AWS account ID for the dev environment"
  type        = string
  sensitive   = true
}

# ============================================================================
# Networking Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnet deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ============================================================================
# Pipeline Configuration
# ============================================================================

variable "source_repo_name" {
  description = "Name of the source code repository"
  type        = string
  default     = "Secure-CICD-Pipeline-PCI"
}

variable "source_repo_branch" {
  description = "Branch to trigger pipeline"
  type        = string
  default     = "main"
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  
  validation {
    condition     = contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE"], var.build_compute_type)
    error_message = "Build compute type must be a valid CodeBuild size."
  }
}

variable "build_image" {
  description = "CodeBuild Docker image"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

# ============================================================================
# Security Configuration
# ============================================================================

variable "enable_kms_rotation" {
  description = "Enable automatic KMS key rotation (PCI-DSS best practice)"
  type        = bool
  default     = true
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "s3_artifact_retention_days" {
  description = "Number of days to retain S3 artifacts"
  type        = number
  default     = 90
}

variable "enable_checkov_scan" {
  description = "Enable Checkov SAST scanning in pipeline"
  type        = bool
  default     = true
}

variable "checkov_fail_threshold" {
  description = "Checkov severity level to fail builds (CRITICAL, HIGH, MEDIUM, LOW)"
  type        = string
  default     = "HIGH"
  
  validation {
    condition     = contains(["CRITICAL", "HIGH", "MEDIUM", "LOW"], var.checkov_fail_threshold)
    error_message = "Checkov fail threshold must be CRITICAL, HIGH, MEDIUM, or LOW."
  }
}

# ============================================================================
# Tagging Configuration
# ============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Production Account Configuration (Optional)
# ============================================================================

variable "prod_account_id" {
  description = "AWS account ID for production environment (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_prod_deployment" {
  description = "Enable production deployment stage"
  type        = bool
  default     = false
}