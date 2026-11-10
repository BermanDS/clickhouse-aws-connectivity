# clickhouse-aws-connectivity

Terraform that builds the AWS + Cloudflare side of a private path from your
Cloudflare Zero Trust org (e.g. Azure VMs/AKS nodes enrolled via WARP) to a
ClickHouse Cloud instance hosted on AWS:
`<your-instance>.eu-west-2.aws.clickhouse.cloud:8443`.

```
Azure Workloads (WARP client)
      │
      ▼
Cloudflare Zero Trust Network
      │  cloudflared tunnel (outbound only)
      ▼
AWS Hub VPC (eu-west-2) — this repo
  Private Subnet A: cloudflared Fargate task #1 (AZ-a)
  Private Subnet B: cloudflared Fargate task #2 (AZ-b)
      │  Private Network route
      ▼
<your-instance>.eu-west-2.aws.clickhouse.cloud:8443
```

## What this builds

- VPC across 2 AZs: public + private subnets, IGW, 2x NAT Gateway (one per AZ,
  needed for the Fargate tasks to pull their container image and reach the
  Cloudflare edge — the tunnel traffic itself then rides the Cloudflare edge,
  not the NAT path, once established)
- An ECS cluster running `cloudflared` (official `cloudflare/cloudflared`
  image) as 2x **Fargate** tasks, one per private subnet/AZ
  - No EC2 instances, no AMIs, no OS patching — `desired_count` is the only
    thing you scale
  - No inbound ports, no public IP (`assign_public_ip = false`); security
    group is outbound-443-only
  - Logs go to CloudWatch (`/ecs/<name_prefix>-cloudflared`)
- Cloudflare Tunnel (`cloudflare_zero_trust_tunnel_cloudflared`) + tunnel
  config pointing at the ClickHouse hostname over HTTPS
- A Cloudflare **Private Network route** (CIDR-based) for the ClickHouse IP,
  so WARP-enrolled clients can reach it through the tunnel

**Note on the tunnel token:** it's currently passed as a plain command-line
arg in the ECS task definition (visible in the ECS console/Terraform state).
For anything beyond a quick test, move it into **AWS Secrets Manager** and
reference it via the task definition's `secrets` block instead.

## Prerequisites you provide

1. **AWS credentials** for the target account (via your usual method — env
   vars, SSO profile, etc.)
2. **Cloudflare API token**, exported as an env var (never put it in tfvars):
   ```bash
   export CLOUDFLARE_API_TOKEN=xxxx
   ```
   Scope it to at least: `Account.Cloudflare Tunnel:Edit`.
3. **Resolve the ClickHouse IP** for the Private Network route (Cloudflare
   routes are CIDR-based, not hostname-based):
   ```bash
   dig +short <your-instance>.eu-west-2.aws.clickhouse.cloud
   ```
   Put the result in `clickhouse_ip` in your `terraform.tfvars`. ClickHouse
   Cloud IPs for a given service are generally stable but not contractually
   permanent — re-resolve if connectivity breaks later.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set clickhouse_ip at minimum
terraform init
terraform plan
terraform apply
```

## After apply

1. In the Cloudflare Zero Trust dashboard, confirm the tunnel
   (`aws-hub-clickhouse` by default) shows both EC2 connectors as healthy.
2. Enable **WARP-to-Tunnel routing** and add the ClickHouse hostname/CIDR to
   your WARP client's **Split Tunnel include list** (Zero Trust → Settings →
   WARP Client → Split Tunnels).
3. Install the WARP client on the Azure VMs/AKS nodes that need access, and
   enroll them in this Cloudflare Zero Trust org.
4. Verify end-to-end from an enrolled Azure client:
   ```bash
   curl --user 'default:<password>' \
     --data-binary 'SELECT 1' \
     https://<your-instance>.eu-west-2.aws.clickhouse.cloud:8443
   ```

## Things intentionally left out (add if you need them)

- **Access policies / mTLS** — this repo only builds the network path, not
  identity-aware access control on top. If you want to gate who can reach
  ClickHouse through the tunnel, add a `cloudflare_zero_trust_access_application`
  + `cloudflare_zero_trust_access_policy` pair.
- **ClickHouse IP Access List hardening** — once this tunnel is the sole path
  in, consider restricting ClickHouse Cloud's IP Access List to Cloudflare's
  published egress ranges (or removing `0.0.0.0/0` if currently set) so the
  public endpoint only accepts tunnel-originated traffic.
- **Remote state backend** — this repo ships with local state by default; add
  an `s3`/`backend.tf` block before using this for anything beyond a one-off
  test, so state isn't only on one machine.
