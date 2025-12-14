variable "enable_guardduty" {
  description = "Enable GuardDuty in the account."
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable Security Hub in the account."
  type        = bool
  default     = true
}

variable "security_hub_standards" {
  description = "List of Security Hub standard ARNs to subscribe to."
  type        = list(string)
  default = [
    "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0",
    "arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0"
  ]
}

variable "security_hub_linked_region" {
  description = "Aggregator region for Security Hub findings (optional)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default     = {}
}
