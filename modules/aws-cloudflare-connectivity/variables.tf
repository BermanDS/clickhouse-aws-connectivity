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
