terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ultimatenew-tf-state-202264954476" # change this
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ultimatenew-tf-lock"
    encrypt        = true
  }
}


provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ultimatenew"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}