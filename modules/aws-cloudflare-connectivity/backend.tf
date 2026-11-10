terraform {
  # Values supplied at `terraform init -backend-config=backend.hcl` time (see
  # backend.hcl.example) and via the GitHub Actions workflow, not hardcoded
  # here, so the same config works across forks/accounts.
  backend "s3" {}
}
