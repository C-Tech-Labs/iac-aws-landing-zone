# Account Baseline Module

Establishes baseline services for an AWS landing zone account, including centralized logging, CloudTrail, and AWS Config.

## Features
- Secure S3 logging bucket with versioning, encryption, lifecycle, and restrictive bucket policy
- Multi-Region CloudTrail streaming to S3 and CloudWatch (optional KMS encryption)
- AWS Config recorder and delivery channel targeting the logging bucket
- Opinionated tagging for traceability

## Inputs
| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `account_name` | Friendly account name used in resource naming. | `string` | n/a |
| `logging_bucket_name` | Name of the S3 bucket for centralized logging (must be globally unique). | `string` | n/a |
| `logging_storage_days` | Number of days before log objects transition to Glacier. | `number` | `90` |
| `enable_cloudtrail` | Whether to enable a multi-region CloudTrail. | `bool` | `true` |
| `cloudtrail_name` | Name for the CloudTrail. | `string` | `"lz-org-trail"` |
| `cloudtrail_kms_key_arn` | Optional KMS key ARN for encrypting CloudTrail logs. | `string` | `null` |
| `cloudtrail_log_retention_days` | Retention in days for CloudTrail CloudWatch logs. | `number` | `365` |
| `cloudtrail_source_arn` | Expected source ARN used to scope log delivery permissions. | `string` | `"*"` |
| `enable_config` | Whether to enable AWS Config. | `bool` | `true` |
| `config_recorder_name` | Name of the AWS Config recorder. | `string` | `"lz-config-recorder"` |
| `config_delivery_channel_name` | Name of the AWS Config delivery channel. | `string` | `"lz-config-delivery"` |
| `config_sns_topic_arn` | Optional SNS topic ARN for AWS Config notifications. | `string` | `null` |
| `tags` | Common tags to apply to resources. | `map(string)` | `{}` |

## Outputs
| Name | Description |
| --- | --- |
| `logging_bucket_name` | Central logging bucket name |
| `cloudtrail_trail_arn` | ARN of the CloudTrail trail |
| `config_recorder_id` | ID of the AWS Config recorder |
