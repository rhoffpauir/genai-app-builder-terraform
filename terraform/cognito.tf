# Create Cognito resources if existing ones are not provided
resource "aws_cognito_user_pool" "user_pool" {
  count = local.generate_cognito_resources ? 1 : 0
  
  name = "DeploymentPlatformUserPool-${random_string.random_suffix.result}"
  
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  
  auto_verify {
    email = true
  }
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  
  # Email configuration settings
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Lambda triggers (would be configured as needed)
  # lambda_config {
  #   # Configure Lambda triggers as needed
  # }
  
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true
    
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your verification code"
    email_message        = "Your verification code is {####}"
  }

  # Amazon Web Services recommends against using user pool domains in production
  # This is just for demo purposes
  domain = local.cognito_domain_prefix

  tags = {
    Name = "DeploymentPlatformUserPool"
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  count = local.generate_cognito_resources ? 1 : 0
  
  name                   = "DeploymentPlatformUserPoolClient-${random_string.random_suffix.result}"
  user_pool_id           = aws_cognito_user_pool.user_pool[0].id
  generate_secret        = true
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1
  
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
  
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  
  # callback and logout URLs - in a real implementation, replace with your actual URLs  
  callback_urls = ["http://localhost:3000/", "https://${aws_cognito_user_pool.user_pool[0].domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/idpresponse"]
  logout_urls   = ["http://localhost:3000/"]
  
  supported_identity_providers = ["COGNITO"]
  
  prevent_user_existence_errors = "ENABLED"
}

# Create a Cognito user for the admin
resource "aws_cognito_user" "admin_user" {
  count = local.generate_cognito_resources ? 1 : 0
  
  user_pool_id = aws_cognito_user_pool.user_pool[0].id
  username     = var.admin_user_email
  
  attributes = {
    email          = var.admin_user_email
    email_verified = "true"
  }
}

# Resource to set admin password
resource "null_resource" "set_admin_password" {
  count = local.generate_cognito_resources ? 1 : 0
  
  triggers = {
    user_pool_id = aws_cognito_user_pool.user_pool[0].id
    user_email   = var.admin_user_email
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws cognito-idp admin-set-user-password \
        --user-pool-id ${aws_cognito_user_pool.user_pool[0].id} \
        --username ${var.admin_user_email} \
        --password "InitialP@ssword1" \
        --permanent
    EOT
  }

  depends_on = [aws_cognito_user.admin_user]
}
