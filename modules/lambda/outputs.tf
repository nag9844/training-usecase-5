# Outputs for Lambda module

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.image_processor.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.image_processor.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.lambda_role.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_permission_s3" {
  description = "Lambda permission for S3"
  value       = aws_lambda_permission.allow_s3
}