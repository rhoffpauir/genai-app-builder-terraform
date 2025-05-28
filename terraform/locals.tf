locals {
  solution_version = "v2.1.9"
  solution_id      = "SO0276"
  
  # Conditions equivalent to CloudFormation conditions
  vpc_enabled_condition      = var.vpc_enabled
  create_new_vpc_condition   = var.create_new_vpc
  deploy_vpc_condition       = var.vpc_enabled && var.create_new_vpc
  ipam_pool_id_provided      = var.ipam_pool_id != ""
  anonymous_data_condition   = var.send_anonymous_usage_data
  deploy_web_app_ui          = var.deploy_ui
  generate_cognito_resources = var.existing_cognito_user_pool_id == ""
  deploy_custom_dashboard    = var.deploy_custom_dashboard
  
  # Check if user is internal (amazon)
  is_internal_user = length(regexall("amazon", split("@", var.admin_user_email)[1])) > 0
  
  # Get account ID, region and create a stack name for resources
  stack_name = "generative-ai-app-builder"

  # For validation
  vpc_enabled_and_existing = var.vpc_enabled && !var.create_new_vpc
  vpc_not_enabled_or_new_vpc = !var.vpc_enabled || var.create_new_vpc
  
  # Hash based domain prefix if not provided
  cognito_domain_prefix = var.cognito_domain_prefix == "" ? "gai-app-builder-${random_string.random_suffix.result}" : var.cognito_domain_prefix
}
