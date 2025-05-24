provider "aws" {
   region = var.aws_region
}

provider "archive" {}

data "aws_iam_role" "main_role" {
   name = "LabRole"
}

resource "aws_dynamodb_table" "sensors" {
   name = "SensorsT"
   billing_mode = "PAY_PER_REQUEST"
   hash_key = "sensor_id"

   attribute {
      name = "sensor_id"
      type = "S"
   }
}

resource "aws_sqs_queue" "sensor_queue" {
   name = "SensorQueueT"
   visibility_timeout_seconds = 30
   message_retention_seconds = 86400
}

resource "aws_sns_topic" "temperature_alert" {
   name = "TempertaureAlertT"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.temperature_alert.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

data "archive_file" "lambda_zip" {
   type = "zip"
   source_dir = "${path.module}/python"
   output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "main" {
   function_name = "LabFunction"
   handler = "lambda_function.lambda_handler"
   runtime = "python3.13"
   role = data.aws_iam_role.main_role.arn
   filename = "${path.module}/lambda_function.zip"
   memory_size = 128
   timeout = 10

   environment {
      variables = {
         DYNAMODB_TABLE = aws_dynamodb_table.sensors.name
         SQS_QUEUE_URL = aws_sqs_queue.sensor_queue.id
         SNS_TOPIC_ARN = aws_sns_topic.temperature_alert.arn
      }
   }
}