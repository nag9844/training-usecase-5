# SNS module for notifications

resource "aws_sns_topic" "notifications" {
  name = var.topic_name
  
  tags = {
    Name        = var.topic_name
    Environment = var.environment
  }
}

# Create email subscriptions with confirmation disabled
resource "aws_sns_topic_subscription" "email_subscriptions" {
  count     = length(var.email_subscriptions)
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.email_subscriptions[count.index]
  endpoint_auto_confirms = true

  depends_on = [aws_sns_topic.notifications]
}

# SNS topic policy
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}