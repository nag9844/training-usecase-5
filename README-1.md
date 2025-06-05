# AWS Automated Image Resizing and Transfer System

This project provides a complete infrastructure as code (IaC) solution for an automated image processing and management system using AWS services.

## Architecture

.
The system automatically:
1. Detects new image uploads to a source S3 bucket
2. Processes the images (resizes to multiple dimensions)
3. Stores the processed images in a destination S3 bucket
4. Sends notifications about the processing status

## Features

- **Image processing automation**: Automatically resize and optimize images upon upload
- **Secure storage**: Store processed images in a secure and reliable S3 bucket
- **Real-time notifications**: Receive immediate updates about image processing via SNS
- **Scalable architecture**: Design for scalability to handle image processing demands
- **Cost-efficient solution**: Leverage AWS serverless technologies to minimize operational costs

## Prerequisites

- AWS Account
- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or later)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions

## Quick Start

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/aws-image-processing.git
   cd aws-image-processing
   ```

2. Update the `terraform.tfvars` file with your configuration:
   ```
   aws_region = "ap-south-1"
   project_name = "img-processor"
   environment = "dev"
   notification_emails = ["your-email@example.com"]
   ```

3. Initialize Terraform:
   ```
   terraform init
   ```

4. Plan the deployment:
   ```
   terraform plan
   ```

5. Apply the configuration:
   ```
   terraform apply
   ```

6. Confirm by typing `yes` when prompted

## Usage

1. Upload images to the source S3 bucket in the `uploads/` folder:
   ```
   aws s3 cp your-image.jpg s3://[source-bucket-name]/uploads/
   ```

2. The system will automatically:
   - Process the image
   - Store resized versions in the processed bucket
   - Send a notification via SNS

## Module Structure

- **Root Module**: Orchestrates the entire infrastructure
- **S3 Module**: Manages S3 buckets for image storage
- **Lambda Module**: Handles image processing logic
- **SNS Module**: Manages notifications

## Customization

You can customize the following parameters in `terraform.tfvars`:

- AWS region
- Project name
- Environment (dev, staging, prod)
- Notification emails
- Lambda memory size and timeout
- S3 bucket versioning settings

## CI/CD with GitHub Actions

This project includes a GitHub Actions workflow that:

1. Validates Terraform formatting
2. Initializes Terraform
3. Validates the Terraform configuration
4. Creates a plan for pull requests
5. Applies the configuration when merged to main

## Security Considerations

- All S3 buckets are configured with public access blocked
- Server-side encryption is enabled for all buckets
- IAM roles follow the principle of least privilege
- SNS topic is configured for secure message delivery

## Cost Optimization

This solution uses serverless components to minimize costs:
- Lambda functions only run when processing images
- S3 storage costs scale with usage
- SNS pricing is based on the number of notifications sent

