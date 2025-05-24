resource "aws_sns_topic" "this" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = data.aws_ssm_parameter.notification_email.value
}