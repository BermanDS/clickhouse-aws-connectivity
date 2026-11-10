output "vpc_id" {
  value = aws_vpc.this.id
}

output "cloudflared_ecs_service_names" {
  description = "ECS Fargate services running cloudflared (one per AZ). Check their task status/logs via the ECS console or `aws ecs describe-services`."
  value       = aws_ecs_service.cloudflared[*].name
}

output "cloudflared_log_group" {
  value = aws_cloudwatch_log_group.cloudflared.name
}

output "nat_gateway_eips" {
  description = "Static egress IPs of the two NAT Gateways (one per AZ). Only relevant if you also add ClickHouse IP allow-listing as a secondary control."
  value       = aws_eip.nat[*].public_ip
}

output "cloudflare_tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.clickhouse.id
}

output "cloudflare_tunnel_cname" {
  description = "CNAME target for the tunnel, in case you want to expose it via a Cloudflare DNS record as well."
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.clickhouse.id}.cfargotunnel.com"
}
