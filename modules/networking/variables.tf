variable "name" {
  description = "Name prefix for networking resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability Zones to use."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (must align with azs order)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs must match the number of azs"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must align with azs order)."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs must match the number of azs"
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways for private subnets."
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Create gateway and interface endpoints for private networking."
  type        = bool
  default     = true
}

variable "gateway_endpoint_services" {
  description = "Gateway endpoint services to attach to private route tables."
  type        = list(string)
  default     = ["s3", "dynamodb"]
}

variable "interface_endpoint_services" {
  description = "Interface endpoint services to create inside the VPC."
  type        = list(string)
  default = [
    "ec2",
    "ec2messages",
    "ssm",
    "ssmmessages",
    "logs",
    "events",
    "kms",
    "secretsmanager",
    "ecr.api",
    "ecr.dkr",
  ]
}

variable "flow_log_retention_days" {
  description = "Retention period for VPC flow logs."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default     = {}
}
