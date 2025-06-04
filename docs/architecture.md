# Automated Image Resizing and Transfer System Architecture

## 1. Overview

This document describes the architecture of an automated image resizing and transfer system built using AWS services and Terraform. The system automatically processes images uploaded to a source S3 bucket, resizes them to different dimensions, and stores the processed images in a separate S3 bucket. Notifications about the processing status are sent via SNS.

## 2. Target Architecture

```
                 ┌───────────────┐
                 │               │
  Upload         │  Source S3    │     S3 Event         ┌──────────────┐
 ─────────────► │  Bucket       │────Notification─────►│ AWS Lambda   │
                 │               │                      │ Function     │
                 └───────────────┘                      │              │
                                                        │  (Image      │
                                                        │  Processing) │
                                                        └──────┬───────┘
                                                               │
                                                               │
                                                               │
                 ┌───────────────┐                             │
                 │ Processed S3  │                             │
                 │ Bucket        │◄────────────────────────────┘
                 │               │      Store processed images
                 └───────────────┘
                         │
                         │
                         │
                         ▼
                 ┌───────────────┐
                 │ Amazon SNS    │
                 │ Topic         │
                 │               │
                 └───────┬───────┘
                         │
                         │
                         │
    ┌──────────┐  ┌─────┴──────┐  ┌──────────┐
    │          │  │            │  │          │
    │ Email    │  │ SMS        │  │ Other    │
    │ Endpoint │  │ Endpoint   │  │ Endpoints│
    │          │  │            │  │          │
    └──────────┘  └────────────┘  └──────────┘
```

## 3. Target Technology Stack

- **Amazon S3**: For storing source and processed images
- **AWS Lambda**: For image processing (resizing)
- **Amazon SNS**: For sending notifications about processing status
- **AWS IAM**: For secure access control
- **AWS CloudWatch**: For monitoring and logging
- **Terraform**: For Infrastructure as Code (IaC)
- **GitHub Actions**: For CI/CD automation

## 4. Implementation Details

### 4.1 S3 Buckets

The system uses two S3 buckets:
- **Source Bucket**: Where original images are uploaded
- **Processed Bucket**: Where resized images are stored

Both buckets are configured with:
- Server-side encryption (SSE-S3)
- Versioning (optional)
- Blocked public access
- CORS configuration (for the source bucket)

### 4.2 Lambda Function

The Lambda function is triggered when a new image is uploaded to the source bucket. It:
1. Retrieves the image from the source bucket
2. Resizes the image to multiple dimensions using the Sharp library
3. Saves the resized images to the processed bucket
4. Sends a notification via SNS about the successful processing

The function is configured with:
- Memory: 512MB (configurable)
- Timeout: 60 seconds (configurable)
- Node.js 18.x runtime

### 4.3 SNS Topic

The SNS topic sends notifications about:
- Successful image processing
- Processing errors

Subscriptions can be configured for:
- Email notifications
- SMS notifications
- Other endpoints (HTTP/HTTPS, SQS, etc.)

### 4.4 IAM Roles and Policies

The system uses IAM roles and policies to ensure the principle of least privilege:
- Lambda role with permissions to:
  - Read from the source S3 bucket
  - Write to the processed S3 bucket
  - Publish to the SNS topic
  - Write logs to CloudWatch

### 4.5 S3 Event Notifications

S3 event notifications are configured to trigger the Lambda function when:
- A new object is created in the source bucket
- The object has a .jpg extension
- The object is in the "uploads/" prefix

## 5. Security Considerations

- All S3 buckets have public access blocked
- Server-side encryption is enabled for all S3 buckets
- IAM roles follow the principle of least privilege
- Lambda functions are isolated in a VPC (optional enhancement)

## 6. Scalability

- Lambda functions automatically scale based on the number of incoming events
- S3 provides virtually unlimited storage
- The system can handle varying loads without manual intervention

## 7. Cost Optimization

- Serverless architecture (Lambda, S3, SNS) means you only pay for what you use
- No always-on servers or instances
- Lambda memory and timeout are configurable to optimize cost

## 8. Monitoring and Logging

- CloudWatch logs for Lambda function execution
- CloudWatch metrics for monitoring system performance
- SNS notifications for processing status

## 9. Deployment and CI/CD

- Infrastructure deployed using Terraform
- CI/CD automation using GitHub Actions
- Environment-specific configurations via Terraform variables