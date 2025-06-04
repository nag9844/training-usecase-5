# S3 bucket module for image storage

resource "aws_s3_bucket" "source" {
  bucket        = var.source_bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = var.source_bucket_name
    Environment = var.environment
    Purpose     = "Source images storage"
  }
}

resource "aws_s3_bucket" "target" {
  bucket        = var.target_bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = var.target_bucket_name
    Environment = var.environment
    Purpose     = "target images storage"
  }
}

# Configure versioning for source bucket
resource "aws_s3_bucket_versioning" "source_versioning" {
  bucket = aws_s3_bucket.source.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Configure versioning for target bucket
resource "aws_s3_bucket_versioning" "target_versioning" {
  bucket = aws_s3_bucket.target.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Block public access for source bucket
resource "aws_s3_bucket_public_access_block" "source_public_access_block" {
  bucket                  = aws_s3_bucket.source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Block public access for target bucket
resource "aws_s3_bucket_public_access_block" "target_public_access_block" {
  bucket                  = aws_s3_bucket.target.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure CORS for source bucket
resource "aws_s3_bucket_cors_configuration" "source_cors" {
  bucket = aws_s3_bucket.source.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Encrypt buckets with SSE-S3 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "source_encryption" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "target_encryption" {
  bucket = aws_s3_bucket.target.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}