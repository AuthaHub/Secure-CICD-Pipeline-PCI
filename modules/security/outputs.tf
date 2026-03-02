# ============================================================================
# Security Module - Outputs
# ============================================================================

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.pipeline.key_id
  sensitive   = true
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.pipeline.arn
}

output "kms_alias_name" {
  description = "Alias name of the KMS key"
  value       = aws_kms_alias.pipeline.name
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline IAM role"
  value       = aws_iam_role.codepipeline.arn
}

output "codepipeline_role_name" {
  description = "Name of the CodePipeline IAM role"
  value       = aws_iam_role.codepipeline.name
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild IAM role"
  value       = aws_iam_role.codebuild.arn
}

output "codebuild_role_name" {
  description = "Name of the CodeBuild IAM role"
  value       = aws_iam_role.codebuild.name
}