# Variables for SNS module

variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "email_subscriptions" {
  description = "List of email addresses to subscribe to the SNS topic"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}