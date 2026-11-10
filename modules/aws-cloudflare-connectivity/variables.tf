variable "aws_region" {
  description = "AWS region to deploy into. Matches the ClickHouse Cloud service region (eu-west-2) to keep egress traffic in-region."
  type        = string
  default     = "eu-west-2"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names/tags."
  type        = string
  default     = "ch-tunnel"
}

variable "vpc_cidr" {
  description = "CIDR block for the hub VPC."
  type        = string
  default     = "10.90.0.0/24"
}

variable "availability_zones" {
  description = "Two AZs for HA public/private subnets and NAT gateways."
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR per public subnet (one per AZ)."
  type        = list(string)
  default     = ["10.90.0.0/27", "10.90.0.32/27"]
}

variable "private_subnet_cidrs" {
  description = "CIDR per private subnet (one per AZ) — hosts the cloudflared instances."
  type        = list(string)
  default     = ["10.90.0.64/27", "10.90.0.96/27"]
}

variable "instance_type" {
  description = "Instance type for the cloudflared tunnel hosts."
  type        = string
  default     = "t3.small"
}

variable "clickhouse_hostname" {
  description = "ClickHouse Cloud hostname to route through the tunnel."
  type        = string
}

variable "clickhouse_port" {
  description = "Port the Cloudflare tunnel proxies to on the ClickHouse hostname (8443 = HTTPS interface)."
  type        = number
  default     = 8443
}

variable "clickhouse_ip" {
  description = "Resolved IP address of clickhouse_hostname, used for the Cloudflare Private Network route (CIDR-based, not hostname-based). Resolve with `dig +short <hostname>` and pin it here — ClickHouse Cloud IPs for a given service are stable but not guaranteed permanent, so re-check if connectivity breaks."
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the Zero Trust org/tunnel."
  type        = string
}

variable "cloudflare_tunnel_name" {
  description = "Name of the Cloudflare Tunnel."
  type        = string
  default     = "aws-hub-clickhouse"
}

variable "tags" {
  description = "Common tags applied to all AWS resources."
  type        = map(string)
  default = {
    Project   = "clickhouse-aws-connectivity"
    ManagedBy = "terraform"
  }
}
