# clickhouse-aws-connectivity

Terraform that builds **only the Cloudflare side** of a private path from your
Cloudflare Zero Trust org (e.g. Azure VMs/AKS nodes enrolled via WARP) to a
ClickHouse Cloud instance hosted on AWS:
`<your-instance>.eu-west-2.aws.clickhouse.cloud:8443`.

This module does **not** provision any compute to run `cloudflared` — no VPC,
no ECS, no EC2. You run `cloudflared` yourself, wherever you already have
compute (an Azure VM, AKS, Azure Container Instances, etc.), using the tunnel
token this module outputs. That avoids needing any new AWS compute/network
resources, which matters if your AWS account has Service Control Policies
blocking `ec2:*`/`ecs:*`/`iam:CreateRole` (as this one does).

```
Azure Workloads (WARP client)
      │
      ▼
Cloudflare Zero Trust Network
      │  cloudflared tunnel (outbound only, runs wherever you choose)
      ▼
<your-instance>.eu-west-2.aws.clickhouse.cloud:8443
```

## What this builds

- Cloudflare Tunnel (`cloudflare_zero_trust_tunnel_cloudflared`) + tunnel
  config pointing at the ClickHouse hostname over HTTPS
- A Cloudflare **Private Network route** (CIDR-based) for the ClickHouse IP,
  so WARP-enrolled clients can reach it through the tunnel
- A `cloudflare_tunnel_token` output for you to run `cloudflared` with,
  wherever you run it

## Prerequisites you provide

1. **Cloudflare API token**, exported as an env var (never put it in tfvars):
   ```bash
   export CLOUDFLARE_API_TOKEN=xxxx
   ```
   Scope it to at least: `Account.Cloudflare Tunnel:Edit`.
2. **Resolve the ClickHouse IP** for the Private Network route (Cloudflare
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
# edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

## After apply

1. Get the tunnel token:
   ```bash
   terraform output -raw cloudflare_tunnel_token
   ```
2. Run `cloudflared` wherever you have compute (example: a container):
   ```bash
   docker run -d --name cloudflared cloudflare/cloudflared:latest \
     tunnel --no-autoupdate run --token <token-from-above>
   ```
   On Azure, this can be an AKS deployment, an ACI container group, or a
   service on an existing VM — any host with outbound HTTPS access.
3. In the Cloudflare Zero Trust dashboard, confirm the tunnel
   (`aws-hub-clickhouse` by default) shows as healthy once `cloudflared` is
   running.
4. Enable **WARP-to-Tunnel routing** and add the ClickHouse hostname/CIDR to
   your WARP client's **Split Tunnel include list** (Zero Trust → Settings →
   WARP Client → Split Tunnels).
5. Install the WARP client on the Azure VMs/AKS nodes that need access, and
   enroll them in this Cloudflare Zero Trust org.
6. Verify end-to-end from an enrolled Azure client:
   ```bash
   curl --user 'default:<password>' \
     --data-binary 'SELECT 1' \
     https://<your-instance>.eu-west-2.aws.clickhouse.cloud:8443
   ```

## Things intentionally left out (add if you need them)

- **Where `cloudflared` actually runs** — deliberately out of scope here; see
  "After apply" above. Pick the Azure compute you already manage.
- **Access policies / mTLS** — this repo only builds the network path, not
  identity-aware access control on top. If you want to gate who can reach
  ClickHouse through the tunnel, add a `cloudflare_zero_trust_access_application`
  + `cloudflare_zero_trust_access_policy` pair.
- **ClickHouse IP Access List hardening** — once this tunnel is the sole path
  in, consider restricting ClickHouse Cloud's IP Access List to Cloudflare's
  published egress ranges (or removing `0.0.0.0/0` if currently set) so the
  public endpoint only accepts tunnel-originated traffic.
