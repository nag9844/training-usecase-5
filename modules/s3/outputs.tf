# Outputs for S3 module

output "source_bucket_id" {
  description = "ID of the source S3 bucket"
  value       = aws_s3_bucket.source.id
}

output "source_bucket_name" {
  description = "Name of the source S3 bucket"
  value       = aws_s3_bucket.source.bucket
}

output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = aws_s3_bucket.source.arn
}

output "target_bucket_id" {
  description = "ID of the processed S3 bucket"
  value       = aws_s3_bucket.processed.id
}

output "target_bucket_name" {
  description = "Name of the processed S3 bucket"
  value       = aws_s3_bucket.processed.bucket
}

output "target_bucket_arn" {
  description = "ARN of the processed S3 bucket"
  value       = aws_s3_bucket.processed.arn
}