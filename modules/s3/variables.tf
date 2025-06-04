# Variables for S3 module

variable "source_bucket_name" {
  description = "Name of the source S3 bucket"
  type        = string
}

variable "target_bucket_name" {
  description = "Name of the processed S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "Boolean to force destruction of S3 buckets even if not empty"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}