# Create CloudWatch Dashboard if enabled
resource "aws_cloudwatch_dashboard" "ops_dashboard" {
  count = local.deploy_custom_dashboard ? 1 : 0
  
  dashboard_name = "DeploymentPlatformSetupOpsCustomDashboard-${random_string.random_suffix.result}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text",
        x      = 0,
        y      = 0,
        width  = 24,
        height = 1,
        properties = {
          markdown = "# Generative AI Application Builder on AWS - Operational Dashboard"
        }
      },
      
      # Lambda Invocations
      {
        type   = "metric",
        x      = 0,
        y      = 1,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.infra_setup_custom_resource.function_name]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          title   = "Lambda Invocations",
          period  = 300
        }
      },
      
      # Lambda Duration
      {
        type   = "metric",
        x      = 12,
        y      = 1,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.infra_setup_custom_resource.function_name]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          title   = "Lambda Duration",
          period  = 300
        }
      },
      
      # Lambda Errors
      {
        type   = "metric",
        x      = 0,
        y      = 7,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.infra_setup_custom_resource.function_name]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          title   = "Lambda Errors",
          period  = 300
        }
      },
      
      # Lambda Throttles
      {
        type   = "metric",
        x      = 12,
        y      = 7,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/Lambda", "Throttles", "FunctionName", aws_lambda_function.infra_setup_custom_resource.function_name]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          title   = "Lambda Throttles",
          period  = 300
        }
      }
    ]
  })
}
