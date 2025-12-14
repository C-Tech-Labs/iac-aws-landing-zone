# Security services module: enables GuardDuty and Security Hub

terraform {
  required_version = ">= 1.4.0"
}

locals {
  base_tags = {
    Component = "security"
  }

  tags = merge(local.base_tags, var.tags)
}

resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable = true
  tags   = local.tags
}

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0

  auto_enable_controls = true
  tags                 = local.tags
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each = var.enable_security_hub ? toset(var.security_hub_standards) : []

  standards_arn = each.value
  depends_on    = [aws_securityhub_account]
}

resource "aws_securityhub_finding_aggregator" "this" {
  count = var.enable_security_hub && var.security_hub_linked_region != null ? 1 : 0

  linking_mode      = "SPECIFIED_REGIONS"
  specified_regions = [var.security_hub_linked_region]

  depends_on = [aws_securityhub_account]
}

output "guardduty_detector_id" {
  description = "GuardDuty detector identifier"
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].id : null
}

output "security_hub_enabled" {
  description = "Whether Security Hub is enabled"
  value       = var.enable_security_hub
}
