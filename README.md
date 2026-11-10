# clickhouse-aws-connectivity

Terraform for AWS/Cloudflare infrastructure, organized as one independently
plannable/applyable module per top-level folder under `modules/` — mirroring
the per-module CI pattern used in BGS's `tf-az-bgs`, adapted for a personal
AWS + Cloudflare setup (no shared private workflows, no Azure-specific
tooling).

## Modules

| Module | Purpose |
|---|---|
| [`aws-cloudflare-connectivity`](modules/aws-cloudflare-connectivity) | Cloudflare Tunnel + Private Network route from a Cloudflare Zero Trust org to a ClickHouse Cloud instance hosted on AWS (no AWS compute — `cloudflared` runs on your own infra, e.g. Azure) |

Add further modules as new folders under `modules/` — the workflows below
pick up any folder containing `.tf` files automatically.

## CI/CD

- **`pr-workflow.yml`** — on a PR touching a module folder: `terraform plan`
  for that module, posted as a PR comment. On merge to `main`: `terraform
  apply` for the same folders.
- **`module-workflow.yml`** — manual (`workflow_dispatch`): plan or apply a
  single named module on demand.

`main` is a protected branch: changes land via PR with at least one approval
and a passing plan.

See each module's own README for module-specific setup and required
variables.
