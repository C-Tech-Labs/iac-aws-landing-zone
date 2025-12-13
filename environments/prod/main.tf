# Terraform configuration for production environment
terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1" # TODO: adjust region
}

module "account_baseline" {
  source = "../../modules/account-baseline"
  # TODO: Add required variables
}

module "networking" {
  source = "../../modules/networking"
  # TODO: Add required variables
}

module "security" {
  source = "../../modules/security"
  # TODO: Add required variables
}
