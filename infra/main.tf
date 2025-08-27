terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Archive the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../target/lambda/lambda_http_geolocation/bootstrap"
  output_path = "../target/lambda/lambda_http_geolocation.zip"
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_http_geolocation-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic execution role policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "main" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "lambda_http_geolocation"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "bootstrap"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "provided.al2023"
  architectures   = ["arm64"]

  environment {
    variables = {
      RUST_LOG = "info"
    }
  }
}

# API Gateway V2 (HTTP API)
resource "aws_apigatewayv2_api" "main" {
  name          = "lambda_http_geolocation-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

# API Gateway V2 stage
resource "aws_apigatewayv2_stage" "main" {
  api_id = aws_apigatewayv2_api.main.id
  name   = "prod"
  auto_deploy = true
}

# API Gateway V2 integration
resource "aws_apigatewayv2_integration" "main" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  
  integration_method = "POST"
  integration_uri    = aws_lambda_function.main.invoke_arn
  payload_format_version = "2.0"
}

# API Gateway V2 route for root
resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# API Gateway V2 route for geolocation
resource "aws_apigatewayv2_route" "geo" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /geo"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# API Gateway V2 route for catch-all (proxy)
resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# Lambda permission for API Gateway V2
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
