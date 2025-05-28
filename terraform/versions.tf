terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Solution = "generative-ai-application-builder-on-aws"
      Version  = "v2.1.9"
    }
  }
}

provider "random" {}
provider "archive" {}
