# SNS module for notifications

resource "aws_sns_topic" "notifications" {
  name = var.topic_name
  
  tags = {
    Name        = var.topic_name
    Environment = var.environment
  }
}

# Create email subscriptions
resource "aws_sns_topic_subscription" "email_subscriptions" {
  count     = length(var.email_subscriptions)
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.email_subscriptions[count.index]
}