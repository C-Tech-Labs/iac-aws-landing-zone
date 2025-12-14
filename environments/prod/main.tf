# Terraform configuration for production environment
terraform {
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = "us-east-2"
}

locals {
  environment = "prod"
  azs         = ["us-east-2a", "us-east-2b", "us-east-2c"]
  tags = {
    Environment     = local.environment
    ManagedBy       = "terraform"
    Confidentiality = "restricted"
  }
}

module "account_baseline" {
  source = "../../modules/account-baseline"

  account_name                  = "${local.environment}-account"
  logging_bucket_name           = "lz-${local.environment}-logs-example"
  cloudtrail_name               = "lz-${local.environment}-trail"
  cloudtrail_source_arn         = "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/lz-${local.environment}-trail"
  logging_storage_days          = 180
  cloudtrail_log_retention_days = 400
  config_recorder_name          = "lz-${local.environment}-config"
  config_delivery_channel_name  = "lz-${local.environment}-delivery"
  tags                          = local.tags
}

module "networking" {
  source = "../../modules/networking"

  name                    = "lz-${local.environment}"
  vpc_cidr                = "10.1.0.0/16"
  azs                     = local.azs
  public_subnet_cidrs     = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs    = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
  enable_nat_gateway      = true
  flow_log_retention_days = 400
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
