# Main Terraform configuration file

terraform {
  required_version = ">= 1.12.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.default_tags
  }
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  resource_suffix = random_string.suffix.result
}

# Create S3 buckets for image storage
module "s3_buckets" {
  source = "./modules/s3"
  
  source_bucket_name      = "${local.name_prefix}-source-${local.resource_suffix}"
  target_bucket_name   = "${local.name_prefix}-processed-${local.resource_suffix}"
  force_destroy           = var.force_destroy_buckets
  environment             = var.environment
  enable_versioning       = var.enable_bucket_versioning
}

# Create SNS topic for notifications
module "sns" {
  source = "./modules/sns"
  
  topic_name              = "${local.name_prefix}-notifications-${local.resource_suffix}"
  email_subscriptions     = var.notification_emails
  environment             = var.environment
}

# Create Lambda function for image processing
module "lambda" {
  source = "./modules/lambda"
  
  function_name           = "${local.name_prefix}-image-processor-${local.resource_suffix}"
  description             = "Processes and resizes images from S3"
  source_bucket_name      = module.s3_buckets.source_bucket_name
  source_bucket_arn       = module.s3_buckets.source_bucket_arn
  target_bucket_name   = module.s3_buckets.target_bucket_name
  target_bucket_arn    = module.s3_buckets.target_bucket_arn
  sns_topic_arn           = module.sns.topic_arn
  environment             = var.environment
  memory_size             = var.lambda_memory_size
  timeout                 = var.lambda_timeout
}

# Configure S3 event notifications to trigger Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3_buckets.source_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda.function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".jpg"
  }
  
  depends_on = [
    module.lambda.lambda_permission_s3
  ]
}