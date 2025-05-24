variable "lambda_source_dir" {
  type = string
}

variable "function_name" {
  type = string
}

variable "lambda_handler" {
  type    = string
  default = "lambda_function.lambda_handler"
}

variable "lambda_runtime" {
  type    = string
  default = "python3.13"
}

variable "lambda_role_arn" {
  type = string
}

variable "environment_variables" {
  type = map(string)
  default = {}
}