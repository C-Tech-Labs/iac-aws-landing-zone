# Networking module: provides a hub VPC with public and private subnets

terraform {
  required_version = ">= 1.4.0"
}

locals {
  base_tags = {
    Component = "networking"
  }

  tags = merge(local.base_tags, var.tags)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-igw" })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/lz/${var.name}/flow-logs"
  retention_in_days = var.flow_log_retention_days
  tags              = merge(local.tags, { Purpose = "vpc-flow-logs" })
}

resource "aws_iam_role" "flow_logs" {
  name = "lz-${var.name}-flow-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "lz-${var.name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
  tags                 = merge(local.tags, { Name = "${var.name}-flow-log" })
}

locals {
  public_subnet_map  = { for idx, az in var.azs : az => var.public_subnet_cidrs[idx] }
  private_subnet_map = { for idx, az in var.azs : az => var.private_subnet_cidrs[idx] }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.name}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.tags, {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? aws_subnet.public : {}

  vpc  = true
  tags = merge(local.tags, { Name = "${var.name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "this" {
  for_each = var.enable_nat_gateway ? aws_subnet.public : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(local.tags, { Name = "${var.name}-nat-${each.key}" })
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-private-rt-${each.key}" })
}

resource "aws_route" "private_nat" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.enable_nat_gateway ? aws_nat_gateway.this[each.key].id : null

  lifecycle {
    ignore_changes = [nat_gateway_id]
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_security_group" "endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name        = "${var.name}-endpoints"
  description = "Restrict interface endpoints to private subnets"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = values(local.private_subnet_map)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.name}-endpoints" })
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = var.enable_vpc_endpoints ? toset(var.gateway_endpoint_services) : []

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type = "Gateway"

  route_table_ids = values(aws_route_table.private)[*].id

  tags = merge(local.tags, { Name = "${var.name}-${each.key}-endpoint" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_vpc_endpoints ? toset(var.interface_endpoint_services) : []

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  private_dns_enabled = true

  security_group_ids = [aws_security_group.endpoints[0].id]

  tags = merge(local.tags, { Name = "${var.name}-${each.key}-endpoint" })
}

data "aws_region" "current" {}

output "vpc_id" {
  description = "VPC identifier"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = values(aws_subnet.private)[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[*].id : []
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = values(aws_route_table.private)[*].id
}

output "endpoint_security_group_id" {
  description = "Security group protecting interface endpoints"
  value       = var.enable_vpc_endpoints ? aws_security_group.endpoints[0].id : null
}

output "vpc_endpoints" {
  description = "Map of created VPC endpoints"
  value = var.enable_vpc_endpoints ? {
    gateway   = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
    interface = { for k, v in aws_vpc_endpoint.interface : k => v.id }
    } : {
    gateway   = {}
    interface = {}
  }
}
