# Terraform configuration for development environment
terraform {
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "dev"
  azs         = ["us-east-1a", "us-east-1b"]
  tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

module "account_baseline" {
  source = "../../modules/account-baseline"

  account_name                  = "${local.environment}-account"
  logging_bucket_name           = "lz-${local.environment}-logs-example"
  cloudtrail_name               = "lz-${local.environment}-trail"
  cloudtrail_source_arn         = "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/lz-${local.environment}-trail"
  logging_storage_days          = 60
  cloudtrail_log_retention_days = 180
  config_recorder_name          = "lz-${local.environment}-config"
  config_delivery_channel_name  = "lz-${local.environment}-delivery"
  tags                          = local.tags
}

module "networking" {
  source = "../../modules/networking"

  name                    = "lz-${local.environment}"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = local.azs
  public_subnet_cidrs     = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway      = true
  flow_log_retention_days = 30
  tags                    = local.tags
}

module "security" {
  source = "../../modules/security"

  enable_guardduty           = true
  enable_security_hub        = true
  security_hub_linked_region = "us-east-1"
  tags                       = local.tags
}

data "aws_caller_identity" "current" {}
