# Cloudflare Tunnel: terminates on the EC2 instances in the private subnets and
# exposes a private network route to the ClickHouse Cloud hostname, reachable
# from any Azure/AWS client enrolled in the same Zero Trust org via WARP.

resource "random_id" "tunnel_secret" {
  byte_length = 35
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "clickhouse" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "clickhouse" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.clickhouse.id

  config {
    ingress_rule {
      hostname = var.clickhouse_hostname
      service  = "https://${var.clickhouse_hostname}:${var.clickhouse_port}"

      origin_request {
        origin_server_name = var.clickhouse_hostname
        no_tls_verify      = false
      }
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Private Network route — tells Cloudflare "traffic to this CIDR goes through this tunnel".
# Cloudflare Private Network routes are CIDR-based, not hostname-based, hence var.clickhouse_ip.
resource "cloudflare_zero_trust_tunnel_route" "clickhouse" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.clickhouse.id
  network    = "${var.clickhouse_ip}/32"
  comment    = "ClickHouse Cloud (${var.clickhouse_hostname})"
}
