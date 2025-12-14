variable "account_name" {
  description = "Friendly account name used in resource naming."
  type        = string
}

variable "logging_bucket_name" {
  description = "Name of the S3 bucket for centralized logging (must be globally unique)."
  type        = string
}

variable "logging_storage_days" {
  description = "Number of days before log objects transition to Glacier."
  type        = number
  default     = 90
}

variable "enable_cloudtrail" {
  description = "Whether to enable a multi-region CloudTrail."
  type        = bool
  default     = true
}

variable "cloudtrail_name" {
  description = "Name for the CloudTrail."
  type        = string
  default     = "lz-org-trail"
}

variable "cloudtrail_kms_key_arn" {
  description = "Optional KMS key ARN for encrypting CloudTrail logs."
  type        = string
  default     = null
}

variable "cloudtrail_log_retention_days" {
  description = "Retention in days for CloudTrail CloudWatch logs."
  type        = number
  default     = 365
}

variable "cloudtrail_source_arn" {
  description = "Expected source ARN used to scope log delivery permissions."
  type        = string
  default     = "*"
}

variable "enable_config" {
  description = "Whether to enable AWS Config."
  type        = bool
  default     = true
}

variable "config_recorder_name" {
  description = "Name of the AWS Config recorder."
  type        = string
  default     = "lz-config-recorder"
}

variable "config_delivery_channel_name" {
  description = "Name of the AWS Config delivery channel."
  type        = string
  default     = "lz-config-delivery"
}

variable "config_sns_topic_arn" {
  description = "Optional SNS topic ARN for AWS Config notifications."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default     = {}
}
