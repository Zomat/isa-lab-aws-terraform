data "aws_ssm_parameter" "notification_email" {
  name = "/notification/email"
  with_decryption = true
}

variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "us-east-1"
}
