# Outputs for SNS module

output "topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.notifications.name
}

output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.notifications.arn
}