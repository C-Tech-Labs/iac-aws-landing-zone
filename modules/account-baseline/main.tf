# Account baseline module: establishes logging, CloudTrail, and AWS Config

terraform {
  required_version = ">= 1.4.0"
}

locals {
  base_tags = {
    Component = "account-baseline"
  }

  tags = merge(local.base_tags, var.tags)

  config_sns_statement = var.config_sns_topic_arn == null ? [] : [
    {
      Effect   = "Allow",
      Action   = ["sns:Publish"],
      Resource = [var.config_sns_topic_arn]
    }
  ]
}

resource "aws_s3_bucket" "logging" {
  bucket = var.logging_bucket_name

  tags = merge(local.tags, {
    Name = "${var.account_name}-logs"
  })
}

resource "aws_s3_bucket_versioning" "logging" {
  bucket = aws_s3_bucket.logging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  bucket = aws_s3_bucket.logging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logging" {
  bucket = aws_s3_bucket.logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  bucket = aws_s3_bucket.logging.id

  rule {
    id     = "retain-current"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = var.logging_storage_days
      storage_class   = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid     = "AWSCloudTrailAclCheck"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = [aws_s3_bucket.logging.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [var.cloudtrail_source_arn]
    }
  }

  statement {
    sid     = "AWSCloudTrailWrite"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.logging.arn}/AWSLogs/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [var.cloudtrail_source_arn]
    }
  }

  statement {
    sid     = "AWSConfigWrite"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.logging.arn}/AWSLogs/*/Config/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logging.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# CloudTrail resources
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name              = "/aws/lz/cloudtrail"
  retention_in_days = var.cloudtrail_log_retention_days

  tags = merge(local.tags, { Purpose = "cloudtrail" })
}

resource "aws_iam_role" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name = "lz-cloudtrail-${var.account_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name = "lz-cloudtrail-to-logs"
  role = aws_iam_role.cloudtrail[count.index].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = aws_cloudwatch_log_group.cloudtrail[count.index].arn
      }
    ]
  })
}

resource "aws_cloudtrail" "this" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = var.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.logging.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.cloudtrail_kms_key_arn
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail[count.index].arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail[count.index].arn

  tags = local.tags
}

# AWS Config
resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name = "lz-config-${var.account_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "config" {
  count = var.enable_config ? 1 : 0

  name = "lz-config-policy"
  role = aws_iam_role.config[count.index].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "config:Put*",
          "config:BatchPut*",
          "config:Get*",
          "config:Describe*"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["${aws_s3_bucket.logging.arn}/AWSLogs/*/Config/*"],
        Condition = {
          StringLike = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ] + local.config_sns_statement
  })
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_config ? 1 : 0

  name     = var.config_recorder_name
  role_arn = aws_iam_role.config[count.index].arn
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_config ? 1 : 0

  name           = var.config_delivery_channel_name
  s3_bucket_name = aws_s3_bucket.logging.id
  sns_topic_arn  = var.config_sns_topic_arn

  depends_on = [aws_config_configuration_recorder]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[count.index].name
  is_enabled = true
}

output "logging_bucket_name" {
  description = "Central logging bucket name"
  value       = aws_s3_bucket.logging.id
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.this[0].arn : null
}

output "config_recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = var.enable_config ? aws_config_configuration_recorder.this[0].id : null
}
