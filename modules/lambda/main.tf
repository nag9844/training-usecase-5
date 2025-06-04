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
    dependencies_versions = jsonencode({
      sharp = "0.32.6"
      aws-sdk = "2.1450.0"
    })
  }

  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/nodejs
      mkdir -p ${path.module}/nodejs
      cd ${path.module}/nodejs
      npm init -y
      npm install sharp@0.32.6 aws-sdk@2.1450.0 --save
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
      target_bucket = var.target_bucket_name
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

# Create Lambda code file
resource "local_file" "lambda_code" {
  content  = <<-EOT
    // Image processing Lambda function
    const AWS = require('aws-sdk');
    const sharp = require('sharp');
    
    const s3 = new AWS.S3();
    const sns = new AWS.SNS();
    
    // Image sizes for resizing
    const sizes = [
      { width: 100, height: 100, suffix: 'thumbnail' },
      { width: 800, height: null, suffix: 'medium' },
      { width: 1200, height: null, suffix: 'large' }
    ];
    
    exports.handler = async (event) => {
      try {
        // Get the object from the event
        const sourceBucket = event.Records[0].s3.bucket.name;
        const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
        
        // Skip processing if the file is not in the uploads folder or not an image
        if (!key.startsWith('uploads/') || !key.match(/\.(jpg|jpeg|png|gif)$/i)) {
          console.log('Skipping non-image file:', key);
          return;
        }
        
        // Get the image from S3
        const params = {
          Bucket: sourceBucket,
          Key: key
        };
        
        const { Body: imageBody } = await s3.getObject(params).promise();
        
        // Original filename without path
        const filename = key.split('/').pop();
        const fileNameWithoutExt = filename.substring(0, filename.lastIndexOf('.'));
        const extension = filename.substring(filename.lastIndexOf('.') + 1);
        
        // Process image for each size
        const resizePromises = sizes.map(async (size) => {
          const resizedImage = await sharp(imageBody)
            .resize(size.width, size.height)
            .toBuffer();
          
          const destKey = "processed/" + fileNameWithoutExt + "-" + size.suffix + "." + extension;
          
          await s3.putObject({
            Bucket: process.env.target_bucket,
            Key: destKey,
            Body: resizedImage,
            ContentType: "image/" + (extension === "jpg" ? "jpeg" : extension)
          }).promise();
          
          return destKey;
        });
        
        const resizedImageKeys = await Promise.all(resizePromises);
        
        // Send notification
        await sns.publish({
          TopicArn: process.env.SNS_TOPIC_ARN,
          Subject: 'Image Processing Completed',
          Message: JSON.stringify({
            originalImage: key,
            processedImages: resizedImageKeys,
            timestamp: new Date().toISOString()
          })
        }).promise();
        
        console.log('Image processing completed successfully');
        return {
          statusCode: 200,
          body: JSON.stringify({
            message: 'Image processing completed successfully',
            originalImage: key,
            processedImages: resizedImageKeys
          })
        };
        
      } catch (error) {
        console.error('Error processing image:', error);
        
        // Send error notification
        await sns.publish({
          TopicArn: process.env.SNS_TOPIC_ARN,
          Subject: 'Image Processing Error',
          Message: JSON.stringify({
            error: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString()
          })
        }).promise();
        
        return {
          statusCode: 500,
          body: JSON.stringify({
            message: 'Error processing image',
            error: error.message
          })
        };
      }
    };
  EOT
  filename = "${path.module}/src/index.js"

  # Create directory if it doesn't exist
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/src"
  }
}

# Lambda code deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content  = local_file.lambda_code.content
    filename = "index.js"
  }
}