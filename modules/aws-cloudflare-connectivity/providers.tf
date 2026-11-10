# Reads the API token from the CLOUDFLARE_API_TOKEN environment variable —
# never store it in tfvars or commit it to the repo.
provider "cloudflare" {}
