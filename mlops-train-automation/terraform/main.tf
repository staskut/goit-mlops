terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  backend "s3" {
    bucket  = "mlops-tfstate-stankutnyk"
    key     = "sf-lambda/terraform.tfstate"
    region  = "eu-west-2"
    profile = "personal"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

locals {
  lambda_runtime = "python3.12"
  prefix         = var.project_name
}

# ---------- IAM role for Lambda ----------
resource "aws_iam_role" "lambda_role" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Lambda functions ----------
resource "aws_lambda_function" "validate" {
  function_name    = "${local.prefix}-validate"
  role             = aws_iam_role.lambda_role.arn
  handler          = "validate.handler"
  runtime          = local.lambda_runtime
  architectures    = ["x86_64"]
  timeout          = 10

  filename         = "${path.module}/lambda/validate.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/validate.zip")
}

resource "aws_lambda_function" "log_metrics" {
  function_name    = "${local.prefix}-log-metrics"
  role             = aws_iam_role.lambda_role.arn
  handler          = "log_metrics.handler"
  runtime          = local.lambda_runtime
  architectures    = ["x86_64"]
  timeout          = 10

  filename         = "${path.module}/lambda/log_metrics.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/log_metrics.zip")
}

# ---------- Allow Step Functions to invoke Lambdas ----------
resource "aws_lambda_permission" "allow_sfn_validate" {
  statement_id  = "AllowExecutionFromStepFunctionsValidate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validate.function_name
  principal     = "states.amazonaws.com"
}

resource "aws_lambda_permission" "allow_sfn_log" {
  statement_id  = "AllowExecutionFromStepFunctionsLog"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_metrics.function_name
  principal     = "states.amazonaws.com"
}

# ---------- IAM role for Step Functions ----------
resource "aws_iam_role" "sfn_role" {
  name               = "${local.prefix}-sfn-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "states.${var.aws_region}.amazonaws.com" }
    }]
  })
}

# Allow the state machine to invoke these Lambdas
resource "aws_iam_role_policy" "sfn_invoke_lambda" {
  name = "${local.prefix}-sfn-invoke-lambda"
  role = aws_iam_role.sfn_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["lambda:InvokeFunction"],
      Resource = [
        aws_lambda_function.validate.arn,
        aws_lambda_function.log_metrics.arn
      ]
    }]
  })
}

# ---------- Step Functions: Validate -> LogMetrics ----------
resource "aws_sfn_state_machine" "train_pipeline" {
  name     = "${local.prefix}-state-machine"
  role_arn = aws_iam_role.sfn_role.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "Simple training pipeline: Validate → LogMetrics",
    StartAt = "ValidateData",
    States = {
      ValidateData = {
        Type     = "Task",
        Resource = aws_lambda_function.validate.arn,
        Next     = "LogMetrics"
      },
      LogMetrics = {
        Type     = "Task",
        Resource = aws_lambda_function.log_metrics.arn,
        End      = true
      }
    }
  })
}
