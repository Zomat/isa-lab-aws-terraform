provider "aws" {
   region = var.aws_region
}

provider "archive" {}

data "aws_iam_role" "main_role" {
   name = "LabRole"
}

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "SensorsT"
}

module "sqs" {
  source     = "./modules/sqs"
  queue_name = "SensorQueueT"
}

module "sns" {
  source            = "./modules/sns"
  topic_name        = "TemperatureAlertT"
  notification_email = data.aws_ssm_parameter.notification_email.value
}

module "lambda" {
  source = "./modules/lambda"

  lambda_source_dir      = "${path.module}/python"
  function_name          = "LabFunction"
  lambda_role_arn        = data.aws_iam_role.main_role.arn
  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.table_name
    SQS_QUEUE_URL  = module.sqs.queue_url
    SNS_TOPIC_ARN  = module.sns.topic_arn
  }
}