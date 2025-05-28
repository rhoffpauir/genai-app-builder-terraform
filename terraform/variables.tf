variable "region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_enabled" {
  description = "Should the stacks resources be deployed within a VPC"
  type        = bool
  default     = false
}

variable "create_new_vpc" {
  description = "Select true, if you would like to create a new VPC"
  type        = bool
  default     = false
}

variable "ipam_pool_id" {
  description = "If you would like to assign the CIDR range using AWS VPC IP Address Manager, please provide the IPAM pool Id to use"
  type        = string
  default     = ""
  validation {
    condition     = var.ipam_pool_id == "" || can(regex("^ipam-pool-([0-9a-zA-Z])+$", var.ipam_pool_id))
    error_message = "The provided IPAM Pool Id is not a valid format. IPAM Id should be of the following format \"ipam-pool-([0-9a-zA-Z])+\""
  }
}

variable "deploy_ui" {
  description = "Please select the option to deploy the front end UI for this deployment. Selecting false will only create the infrastructure to host the APIs, the authentication for the APIs, and backend processing"
  type        = bool
  default     = true
}

variable "cognito_domain_prefix" {
  description = "If you would like to provide a domain for the Cognito User Pool Client, please enter a value. If a value is not provided, the deployment will generate one"
  type        = string
  default     = ""
  validation {
    condition     = var.cognito_domain_prefix == "" || can(regex("^[a-z0-9](?:[a-z0-9\\-]{0,61}[a-z0-9])?$", var.cognito_domain_prefix))
    error_message = "The provided domain prefix is not a valid format. The domain prefix should be of the following format \"^[a-z0-9](?:[a-z0-9\\-]{0,61}[a-z0-9])?$\""
  }
}

variable "existing_vpc_id" {
  description = "VPC ID of an existing VPC to be used for the use case"
  type        = string
  default     = ""
  validation {
    condition     = var.existing_vpc_id == "" || can(regex("^vpc-\\w{8}(\\w{9})?$", var.existing_vpc_id))
    error_message = "The provided VPC ID is not valid. It should match the pattern vpc-xxxxxxxx or vpc-xxxxxxxxxxxxxxxxx"
  }
}

variable "existing_private_subnet_ids" {
  description = "Comma separated list of subnet IDs of existing private subnets to be used to deploy the AWS Lambda function"
  type        = list(string)
  default     = []
  validation {
    condition = length([
      for subnet_id in var.existing_private_subnet_ids :
      subnet_id if subnet_id == "" || can(regex("^subnet-\\w{8}(\\w{9})?$", subnet_id))
    ]) == length(var.existing_private_subnet_ids)
    error_message = "If using an existing VPC configuration, please provide a valid list of subnet Ids for AWS Lambda function configuration"
  }
}

variable "vpc_azs" {
  description = "Comma separated list of AZs in which subnets of the VPCs are created"
  type        = list(string)
  default     = []
  validation {
    condition = length([
      for az in var.vpc_azs :
      az if az == "" || can(regex("^[a-z0-9-]+$", az))
    ]) == length(var.vpc_azs)
    error_message = "If using an existing VPC, please provide a valid list of AZs"
  }
}

variable "existing_security_group_ids" {
  description = "Comma separated list of security groups of the existing vpc to be used for configuring lambda functions"
  type        = list(string)
  default     = []
  validation {
    condition = length([
      for sg_id in var.existing_security_group_ids :
      sg_id if sg_id == "" || can(regex("^sg-\\w{8}(\\w{9})?$", sg_id))
    ]) == length(var.existing_security_group_ids)
    error_message = "If using an existing VPC, please provide a valid list of Security Group IDs for AWS Lambda function configuration"
  }
}

variable "admin_user_email" {
  description = "Email required to create the default user for the admin platform"
  type        = string
  validation {
    condition     = can(regex("[A-Za-z0-9_!#$%&'*+/=?`{|}~^.-]+@[A-Za-z0-9.-]+$", var.admin_user_email))
    error_message = "Please provide a valid email"
  }
}

variable "existing_cognito_user_pool_id" {
  description = "UserPoolId of an existing cognito user pool which this use case will be authenticated with. Typically will be provided when deploying from the deployment platform, but can be omitted when deploying this use-case stack standalone."
  type        = string
  default     = ""
  validation {
    condition     = var.existing_cognito_user_pool_id == "" || can(regex("^[0-9a-zA-Z_-]{9,24}$", var.existing_cognito_user_pool_id))
    error_message = "Provide a valid UserPoolId of an existing cognito user pool"
  }
}

variable "existing_cognito_user_pool_client" {
  description = "Optional - Provide a User Pool Client (App Client) to use an existing one. If not provided a new User Pool Client will be created. This parameter can only be provided if an existing User Pool Id is provided"
  type        = string
  default     = ""
  validation {
    condition     = var.existing_cognito_user_pool_client == "" || can(regex("^[a-z0-9]{3,128}$", var.existing_cognito_user_pool_client))
    error_message = "Provide a valid User Pool Client ID"
  }
}

variable "send_anonymous_usage_data" {
  description = "Send anonymous usage data to AWS"
  type        = bool
  default     = true
}

variable "deploy_custom_dashboard" {
  description = "Deploy custom dashboard"
  type        = bool
  default     = true
}
