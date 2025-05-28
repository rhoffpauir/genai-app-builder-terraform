# Generate a random string for resource naming
resource "random_string" "random_suffix" {
  length  = 6
  special = false
  upper   = false
}

# UUID generator for anonymous metrics
resource "random_uuid" "uuid" {}

# S3 bucket for access logging
resource "aws_s3_bucket" "access_log" {
  bucket_prefix = "deployment-platform-setup-access-log-"
  
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "DeploymentPlatformSetupAccessLog"
  }
}

# S3 bucket server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "access_log" {
  bucket = aws_s3_bucket.access_log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "access_log" {
  bucket = aws_s3_bucket.access_log.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy to enforce HTTPS connections
resource "aws_s3_bucket_policy" "access_log" {
  bucket = aws_s3_bucket.access_log.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonSecureTransport"
        Effect    = "Deny"
        Principal = { AWS = "*" }
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.access_log.arn,
          "${aws_s3_bucket.access_log.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# IAM Role for Custom Resource Lambda
resource "aws_iam_role" "custom_resource_lambda_role" {
  name = "DeploymentPlatformSetupCustomResourceLambdaRole-${random_string.random_suffix.result}"

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

  inline_policy {
    name = "LambdaFunctionServiceRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = []
    })
  }

  tags = {
    Name = "DeploymentPlatformSetupCustomResourceLambdaRole"
  }
}

# IAM Policy for custom resource lambda to access DynamoDB
resource "aws_iam_policy" "custom_resource_dynamodb_policy" {
  name = "DeploymentPlatformSetupInfraSetupCustomResourceDynamoDBPolicy-${random_string.random_suffix.result}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*"
      },
      {
        Effect = "Allow"
        Action = "lambda:GetFunction"
        Resource = "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*",
          "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
        ]
      }
    ]
  })
}

# Attach DynamoDB policy to Lambda role
resource "aws_iam_role_policy_attachment" "custom_resource_dynamodb_policy_attachment" {
  role       = aws_iam_role.custom_resource_lambda_role.name
  policy_arn = aws_iam_policy.custom_resource_dynamodb_policy.arn
}

# Default Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.custom_resource_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Data source for current partition
data "aws_partition" "current" {}

# Data source for current region
data "aws_region" "current" {}

# Data source for caller identity
data "aws_caller_identity" "current" {}

# Lambda layer for Boto3
resource "aws_lambda_layer_version" "boto3_layer" {
  layer_name = "Boto3Layer-${random_string.random_suffix.result}"
  s3_bucket  = "solutions-${data.aws_region.current.name}"
  s3_key     = "generative-ai-application-builder-on-aws/${local.solution_version}/asset<BOTO3_ASSET_KEY>.zip"

  compatible_runtimes = ["python3.12"]
}

# Lambda layer for Python User Agent
resource "aws_lambda_layer_version" "python_user_agent_layer" {
  layer_name = "PythonUserAgentLayer-${random_string.random_suffix.result}"
  s3_bucket  = "solutions-${data.aws_region.current.name}"
  s3_key     = "generative-ai-application-builder-on-aws/${local.solution_version}/asset<PYTHON_USER_AGENT_ASSET_KEY>.zip"

  compatible_runtimes = ["python3.12"]
}

# Custom Resource Lambda Function
resource "aws_lambda_function" "infra_setup_custom_resource" {
  function_name = "DeploymentPlatformSetupInfraSetupCustomResource-${random_string.random_suffix.result}"
  description   = "A custom resource lambda function to perform operations based on operation type"
  
  s3_bucket     = "solutions-${data.aws_region.current.name}"
  s3_key        = "generative-ai-application-builder-on-aws/${local.solution_version}/assetdfd5d4fdc4fa1e50d8de40d00872632fa3716341c39a9a3100ee5e3a1c2d3aa5.zip"
  
  handler       = "lambda_func.handler"
  role          = aws_iam_role.custom_resource_lambda_role.arn
  runtime       = "python3.12"
  timeout       = 900
  
  layers = [
    aws_lambda_layer_version.boto3_layer.arn,
    aws_lambda_layer_version.python_user_agent_layer.arn
  ]

  environment {
    variables = {
      POWERTOOLS_SERVICE_NAME = "CUSTOM-RESOURCE"
      AWS_SDK_USER_AGENT      = "{ \"user_agent_extra\": \"AWSSOLUTION/${local.solution_id}/${local.solution_version}\" }"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_iam_role_policy_attachment.custom_resource_dynamodb_policy_attachment,
    aws_iam_role_policy_attachment.lambda_basic_execution
  ]
}

# Create a null resource to simulate CloudFormation custom resource for log retention
resource "null_resource" "custom_resource_log_retention" {
  triggers = {
    lambda_function_name = aws_lambda_function.infra_setup_custom_resource.function_name
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.infra_setup_custom_resource.function_name} --payload '{\"RequestType\": \"Create\", \"ResourceProperties\": {\"Resource\": \"CW_LOG_RETENTION\", \"FunctionName\": \"${aws_lambda_function.infra_setup_custom_resource.function_name}\"}}' /tmp/output.json"
  }

  depends_on = [aws_lambda_function.infra_setup_custom_resource]
}

# IAM Role for Anonymous Metrics Lambda
resource "aws_iam_role" "scheduled_metrics_lambda_role" {
  name = "DeploymentPlatformSetupScheduledMetricsLambdaRole-${random_string.random_suffix.result}"

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

  inline_policy {
    name = "LambdaFunctionServiceRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = []
    })
  }
}

# Anonymous Metrics Lambda Function (conditionally created)
resource "aws_lambda_function" "scheduled_anonymous_metrics" {
  count = local.anonymous_data_condition ? 1 : 0
  
  function_name = "DeploymentPlatformSetupInfraSetupScheduledAnonymousMetrics-${random_string.random_suffix.result}"
  description   = "A lambda function that runs as per defined schedule to publish metrics"
  
  s3_bucket     = "solutions-${data.aws_region.current.name}"
  s3_key        = "generative-ai-application-builder-on-aws/${local.solution_version}/assetdfd5d4fdc4fa1e50d8de40d00872632fa3716341c39a9a3100ee5e3a1c2d3aa5.zip"
  
  handler       = "lambda_ops_metrics.handler"
  role          = aws_iam_role.scheduled_metrics_lambda_role.arn
  runtime       = "python3.12"
  timeout       = 900

  layers = [
    aws_lambda_layer_version.boto3_layer.arn,
    aws_lambda_layer_version.python_user_agent_layer.arn
  ]

  environment {
    variables = {
      POWERTOOLS_SERVICE_NAME = "ANONYMOUS-CW-METRICS"
      SOLUTION_ID             = local.solution_id
      SOLUTION_VERSION        = local.solution_version
      USE_CASE_UUID           = random_uuid.uuid.result
      REST_API_NAME           = "${local.stack_name}-UseCaseManagementAPI"
      AWS_SDK_USER_AGENT      = "{ \"user_agent_extra\": \"AWSSOLUTION/${local.solution_id}/${local.solution_version}\" }"
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# CloudWatch Metrics Data Policy for Scheduled Metrics Lambda
resource "aws_iam_policy" "get_metrics_data_policy" {
  count = local.anonymous_data_condition ? 1 : 0
  
  name = "DeploymentPlatformSetupInfraSetupGetMetricsDataPolicy-${random_string.random_suffix.result}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "cloudwatch:GetMetricData"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "get_metrics_data_attachment" {
  count = local.anonymous_data_condition ? 1 : 0
  
  role       = aws_iam_role.scheduled_metrics_lambda_role.name
  policy_arn = aws_iam_policy.get_metrics_data_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "scheduled_lambda_basic_execution" {
  role       = aws_iam_role.scheduled_metrics_lambda_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the CloudWatch Event Rule to trigger metrics publication
resource "aws_cloudwatch_event_rule" "metrics_publish_frequency" {
  count = local.anonymous_data_condition ? 1 : 0
  
  name                = "DeploymentPlatformSetupInfraSetupMetricsPublishFrequency-${random_string.random_suffix.result}"
  schedule_expression = "rate(3 hours)"
  state               = "ENABLED"
}

# Add the Lambda target to the CloudWatch Event Rule
resource "aws_cloudwatch_event_target" "metrics_publish_target" {
  count = local.anonymous_data_condition ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.metrics_publish_frequency[0].name
  target_id = "Target0"
  arn       = aws_lambda_function.scheduled_anonymous_metrics[0].arn
}

# Lambda permission for CloudWatch Events to invoke the function
resource "aws_lambda_permission" "allow_cloudwatch_to_call_metrics_lambda" {
  count = local.anonymous_data_condition ? 1 : 0
  
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_anonymous_metrics[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.metrics_publish_frequency[0].arn
}

# Null resource to simulate CloudFormation custom resource for scheduled lambda log retention
resource "null_resource" "scheduled_lambda_log_retention" {
  count = local.anonymous_data_condition ? 1 : 0

  triggers = {
    lambda_function_name = aws_lambda_function.scheduled_anonymous_metrics[0].function_name
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.infra_setup_custom_resource.function_name} --payload '{\"RequestType\": \"Create\", \"ResourceProperties\": {\"Resource\": \"CW_LOG_RETENTION\", \"FunctionName\": \"${aws_lambda_function.scheduled_anonymous_metrics[0].function_name}\"}}' /tmp/output.json"
  }

  depends_on = [aws_lambda_function.infra_setup_custom_resource, aws_lambda_function.scheduled_anonymous_metrics]
}
