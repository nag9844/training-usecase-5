# Output values for the main module

output "source_bucket_name" {
  description = "Name of the source S3 bucket"
  value       = module.s3_buckets.source_bucket_name
}

output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = module.s3_buckets.source_bucket_arn
}

output "target_bucket_name" {
  description = "Name of the processed S3 bucket"
  value       = module.s3_buckets.target_bucket_name
}

output "target_bucket_arn" {
  description = "ARN of the processed S3 bucket"
  value       = module.s3_buckets.target_bucket_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = module.sns.topic_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.sns.topic_arn
}