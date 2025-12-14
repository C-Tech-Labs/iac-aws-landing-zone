# Security Module

Turns on core security services for an account: GuardDuty for threat detection and Security Hub for control coverage.

## Features
- GuardDuty detector enabled by default for continuous threat detection
- Security Hub with auto-enabled controls and optional aggregation region
- Configurable set of Security Hub standards to subscribe to

## Inputs
| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `enable_guardduty` | Enable GuardDuty in the account. | `bool` | `true` |
| `enable_security_hub` | Enable Security Hub in the account. | `bool` | `true` |
| `security_hub_standards` | List of Security Hub standard ARNs to subscribe to. | `list(string)` | `["arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0", "arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0"]` |
| `security_hub_linked_region` | Aggregator region for Security Hub findings (optional). | `string` | `null` |
| `tags` | Common tags to apply to resources. | `map(string)` | `{}` |

## Outputs
| Name | Description |
| --- | --- |
| `guardduty_detector_id` | GuardDuty detector identifier |
| `security_hub_enabled` | Whether Security Hub is enabled |
