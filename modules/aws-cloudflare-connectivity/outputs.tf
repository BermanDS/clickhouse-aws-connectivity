output "cloudflare_tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.clickhouse.id
}

output "cloudflare_tunnel_cname" {
  description = "CNAME target for the tunnel, in case you want to expose it via a Cloudflare DNS record as well."
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.clickhouse.id}.cfargotunnel.com"
}

output "cloudflare_tunnel_token" {
  description = "Run `cloudflared tunnel run --token <this>` on whatever host you choose to run the tunnel from."
  value       = cloudflare_zero_trust_tunnel_cloudflared.clickhouse.tunnel_token
  sensitive   = true
}
