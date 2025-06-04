# Lambda module for image processing

# Create IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.function_name}-role"
    Environment = var.environment
  }
}

# Create Lambda layer for dependencies
resource "aws_lambda_layer_version" "dependencies" {
  filename            = "${path.module}/lambda_layer.zip"
  layer_name          = "${var.function_name}-dependencies"
  compatible_runtimes = ["nodejs18.x"]
  
  depends_on = [
    null_resource.install_dependencies
  ]
}

# Install dependencies for Lambda layer
resource "null_resource" "install_dependencies" {
  triggers = {
    package_json = filemd5("${path.root}/package.json")
    package_lock = filemd5("${path.root}/package-lock.json")
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${path.module}/nodejs
      cp ${path.root}/package.json ${path.module}/nodejs/
      cp ${path.root}/package-lock.json ${path.module}/nodejs/
      cd ${path.module}/nodejs
      npm ci --production
      cd ..
      zip -r lambda_layer.zip nodejs/
    EOT
  }
}

# Create Lambda function
resource "aws_lambda_function" "image_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  description      = var.description
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  memory_size     = var.memory_size
  timeout         = var.timeout
  
  layers = [aws_lambda_layer_version.dependencies.arn]

  environment {
    variables = {
      PROCESSED_BUCKET = var.target_bucket_name
      SOURCE_BUCKET    = var.source_bucket_name
      SNS_TOPIC_ARN    = var.sns_topic_arn
    }
  }

  tags = {
    Name        = var.function_name
    Environment = var.environment
  }
}

# Create CloudWatch log group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.image_processor.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.function_name}-logs"
    Environment = var.environment
  }
}

# Create Lambda permission for S3 to invoke function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.source_bucket_arn
}

# Lambda IAM policy for S3 access
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${var.function_name}-s3-policy"
  description = "Policy for Lambda to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.source_bucket_arn,
          "${var.source_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          var.target_bucket_arn,
          "${var.target_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Lambda IAM policy for CloudWatch Logs
resource "aws_iam_policy" "lambda_logs_policy" {
  name        = "${var.function_name}-logs-policy"
  description = "Policy for Lambda to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
        ]
      }
    ]
  })
}

# Lambda IAM policy for SNS publishing
resource "aws_iam_policy" "lambda_sns_policy" {
  name        = "${var.function_name}-sns-policy"
  description = "Policy for Lambda to publish to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          var.sns_topic_arn
        ]
      }
    ]
  })
}

# Attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sns_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

# Lambda code deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content  = file("${path.module}/src/index.js")
    filename = "index.js"
  }

  depends_on = [
    local_file.lambda_code
  ]
}

# Create Lambda code file
resource "local_file" "lambda_code" {
  content  = file("${path.module}/src/index.js")
  filename = "${path.module}/src/index.js"

  # Create directory if it doesn't exist
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/src"
  }
}