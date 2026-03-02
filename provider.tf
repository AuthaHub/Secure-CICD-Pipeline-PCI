# ============================================================================
# AWS Provider Configuration
# ============================================================================
# Purpose: Configures Terraform to interact with AWS services
# PCI-DSS: Supports secure infrastructure deployment for Requirements 6.2 & 6.3
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for remote state (optional - uncomment when ready)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "secure-cicd-pipeline/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# Primary provider configuration (Dev Account)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Secure-CICD-Pipeline-PCI"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Compliance  = "PCI-DSS"
      Owner       = "AuthaHub"
      CostCenter  = "DevSecOps-Portfolio"
    }
  }
}

# Secondary provider for production account (uncomment when ready)
# provider "aws" {
#   alias  = "prod"
#   region = var.aws_region
#
#   assume_role {
#     role_arn = "arn:aws:iam::PROD_ACCOUNT_ID:role/TerraformCrossAccountRole"
#   }
#
#   default_tags {
#     tags = {
#       Project     = "Secure-CICD-Pipeline-PCI"
#       ManagedBy   = "Terraform"
#       Environment = "production"
#       Compliance  = "PCI-DSS"
#       Owner       = "AuthaHub"
#       CostCenter  = "DevSecOps-Portfolio"
#     }
#   }
# }