variable "notification_email" {
  description = "Adres e-mail do subskrypcji SNS"
  type        = string
}

variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "us-east-1"
}
