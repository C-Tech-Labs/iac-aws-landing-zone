#!/usr/bin/env bash

# Deploy the AWS landing zone using Terraform

set -euo pipefail

# Initialize Terraform and format/validate configuration
terraform init
terraform fmt -check
terraform validate

# Plan and apply with provided arguments (workspace, variables, etc.)
terraform plan -out=tfplan "$@"
terraform apply tfplan
