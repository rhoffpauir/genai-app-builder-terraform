output "deployment_platform_access_log_bucket" {
  description = "The S3 bucket created for access logging"
  value       = aws_s3_bucket.access_log.id
}

output "deployment_platform_access_log_bucket_arn" {
  description = "The ARN of the S3 bucket created for access logging"
  value       = aws_s3_bucket.access_log.arn
}

output "custom_resource_lambda_role_arn" {
  description = "The ARN of the IAM role created for the custom resource Lambda function"
  value       = aws_iam_role.custom_resource_lambda_role.arn
}

output "custom_resource_lambda_function_arn" {
  description = "The ARN of the custom resource Lambda function"
  value       = aws_lambda_function.infra_setup_custom_resource.arn
}

output "custom_resource_lambda_function_name" {
  description = "The name of the custom resource Lambda function"
  value       = aws_lambda_function.infra_setup_custom_resource.function_name
}

output "scheduled_metrics_lambda_function_arn" {
  description = "The ARN of the scheduled metrics Lambda function"
  value       = local.anonymous_data_condition ? aws_lambda_function.scheduled_anonymous_metrics[0].arn : null
}

output "scheduled_metrics_lambda_function_name" {
  description = "The name of the scheduled metrics Lambda function"
  value       = local.anonymous_data_condition ? aws_lambda_function.scheduled_anonymous_metrics[0].function_name : null
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = local.generate_cognito_resources ? aws_cognito_user_pool.user_pool[0].id : var.existing_cognito_user_pool_id
}

output "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = local.generate_cognito_resources ? aws_cognito_user_pool.user_pool[0].arn : null
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = local.generate_cognito_resources ? aws_cognito_user_pool_client.user_pool_client[0].id : var.existing_cognito_user_pool_client
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.deploy_vpc_condition ? aws_vpc.vpc[0].id : var.existing_vpc_id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = local.deploy_vpc_condition ? aws_subnet.private[*].id : var.existing_private_subnet_ids
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = local.deploy_vpc_condition ? aws_subnet.public[*].id : null
}

output "lambda_security_group_id" {
  description = "The ID of the security group for Lambda functions"
  value       = local.deploy_vpc_condition ? aws_security_group.lambda_sg[0].id : null
}

output "solution_id" {
  description = "The ID of the solution"
  value       = local.solution_id
}

output "solution_version" {
  description = "The version of the solution"
  value       = local.solution_version
}

output "use_case_uuid" {
  description = "The UUID generated for this use case"
  value       = random_uuid.uuid.result
}
