# Variables for Lambda module

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Image processing function"
}

variable "source_bucket_name" {
  description = "Name of the source S3 bucket"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  type        = string
}

variable "target_bucket_name" {
  description = "Name of the processed S3 bucket"
  type        = string
}

variable "target_bucket_arn" {
  description = "ARN of the processed S3 bucket"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "memory_size" {
  description = "Memory allocation for Lambda function in MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 60
}