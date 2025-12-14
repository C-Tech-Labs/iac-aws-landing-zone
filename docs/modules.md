# Module reference

This repository provides three reusable Terraform modules that can be composed per account. Each module has a README describing inputs/outputs; this guide shows how they fit together across environments.

## Account baseline (`modules/account-baseline`)
- Secure logging bucket (versioned, encrypted, lifecycle) shared by CloudTrail and AWS Config
- Multi-Region CloudTrail writing to S3 and CloudWatch Logs with optional KMS encryption
- AWS Config recorder, delivery channel, and SNS notification hook
- Opinionated tagging and public access protections on the logging bucket

### Example
```hcl
module "account_baseline" {
  source = "../../modules/account-baseline"

  account_name                  = "prod-account"
  logging_bucket_name           = "lz-prod-logs-example"
  cloudtrail_name               = "lz-prod-trail"
  cloudtrail_log_retention_days = 400
  config_recorder_name          = "lz-prod-config"
  config_delivery_channel_name  = "lz-prod-delivery"
  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

## Networking (`modules/networking`)
- VPC with DNS support, internet gateway, and VPC flow logs to CloudWatch
- Public and private subnets aligned to configured AZs
- Optional NAT gateways for private egress

### Example
```hcl
module "networking" {
  source = "../../modules/networking"

  name                  = "lz-dev"
  vpc_cidr              = "10.0.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway    = true
  flow_log_retention_days = 90
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Security (`modules/security`)
- GuardDuty detector enabled by default
- Security Hub with configurable standards and optional aggregator region

### Example
```hcl
module "security" {
  source = "../../modules/security"

  enable_guardduty          = true
  enable_security_hub       = true
  security_hub_linked_region = "us-east-1"
  security_hub_standards    = [
    "arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0"
  ]
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Environment composition
- `environments/dev` wires the three modules together for a two-AZ development footprint in `us-east-1`.
- `environments/prod` mirrors the composition with three AZs in `us-east-2` and longer retention defaults.

Before applying, set a remote backend in each environment directory and adjust regions/CIDRs to match your AWS accounts.
