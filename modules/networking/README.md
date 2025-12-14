# Networking Module

Creates a VPC foundation with public and private subnets, internet access, optional NAT gateways, VPC endpoints, and VPC flow logs.

## Features
- Opinionated VPC with DNS support enabled
- Public and private subnets aligned to the provided Availability Zones
- Internet gateway for public subnets and optional NAT gateways for private egress
- Gateway endpoints (S3/DynamoDB by default) and interface endpoints for common services (SSM, EC2, ECR, Logs, Events, KMS, Secrets Manager)
- Dedicated security group protecting interface endpoints
- VPC flow logs shipped to CloudWatch with a dedicated IAM role

## Inputs
| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `name` | Name prefix for networking resources. | `string` | n/a |
| `vpc_cidr` | CIDR block for the VPC. | `string` | n/a |
| `azs` | Availability Zones to use. | `list(string)` | n/a |
| `public_subnet_cidrs` | CIDR blocks for public subnets (must align with azs order). | `list(string)` | n/a |
| `private_subnet_cidrs` | CIDR blocks for private subnets (must align with azs order). | `list(string)` | n/a |
| `enable_nat_gateway` | Create NAT gateways for private subnets. | `bool` | `true` |
| `enable_vpc_endpoints` | Create gateway and interface endpoints for private networking. | `bool` | `true` |
| `gateway_endpoint_services` | Gateway endpoint services to attach to private route tables. | `list(string)` | `["s3", "dynamodb"]` |
| `interface_endpoint_services` | Interface endpoint services to create inside the VPC. | `list(string)` | `[...]` |
| `flow_log_retention_days` | Retention period for VPC flow logs. | `number` | `90` |
| `tags` | Common tags to apply to resources. | `map(string)` | `{}` |

## Outputs
| Name | Description |
| --- | --- |
| `vpc_id` | VPC identifier |
| `public_subnet_ids` | IDs of the created public subnets |
| `private_subnet_ids` | IDs of the created private subnets |
| `nat_gateway_ids` | IDs of the NAT gateways |
| `private_route_table_ids` | IDs of private route tables |
| `endpoint_security_group_id` | Security group protecting interface endpoints |
| `vpc_endpoints` | Map of created VPC endpoints (gateway and interface) |
