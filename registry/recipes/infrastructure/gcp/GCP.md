# GCP infrastructure (Terraform)

**Registry recipe:** `gcp` — Terraform layout for Google Cloud: VPC networking, Cloud SQL (PostgreSQL), Memorystore (Redis), Cloud Run services, Secret Manager, Artifact Registry integration, optional Typesense on Compute Engine, and a bootstrap script for CI/CD service accounts and remote state.

## Requirements

- **Terraform** compatible with the root `terraform` block (Google provider **7.14.0**, `time` **~> 0.12**)
- **Google provider** — project and region via `var.project_id` / `var.region`
- **Remote state:** root uses `backend "gcs" {}` — pass backend config at init, e.g. `terraform init -backend-config=environments/qa/backend.hcl`
- **GCP APIs** — root enables required services (Compute, IAM, Cloud Run, SQL, Redis, Secret Manager, etc.); run **`setup-gcp.sh`** once per project for bootstrap (state bucket, Terraform/GitHub Actions service accounts, keys)

## High-level architecture

```text
VPC (custom subnets) ──► Cloud Run (server + clients) + VPC connector
                    ├──► Cloud SQL (PostgreSQL)
                    ├──► Memorystore (Redis)
                    ├──► Secret Manager (runtime secrets)
                    └──► Optional: Typesense VM + disk (module)

Artifact Registry: Docker images referenced by Cloud Run
```

## Layout

| Path                               | Role                                                |
| ---------------------------------- | --------------------------------------------------- |
| `main.tf`                          | Root module: APIs, IAM, wiring, Cloud Run, SQL, …   |
| `variables.tf` / `outputs.tf`    | Root inputs and outputs                             |
| `setup-gcp.sh`                     | One-time bootstrap: SA keys, GCS state bucket, GH hints |
| `environments/qa/backend.hcl`      | Example GCS backend config                          |
| `environments/qa/terraform.tfvars` | Example QA variable overrides                       |
| `modules/*`                        | networking, database, redis, cloud-run, secret-manager-secrets, typesense |

## Usage

1. Complete **`setup-gcp.sh`** in your target GCP project (or replicate its resources manually).
2. Copy/adjust **`environments/<env>/terraform.tfvars`** and **`backend.hcl`** for your project.
3. From the recipe root (as `infrastructure/gcp` in your repo):

   ```bash
   terraform init -backend-config=environments/qa/backend.hcl
   terraform plan -var-file=environments/qa/terraform.tfvars
   terraform apply -var-file=environments/qa/terraform.tfvars
   ```

4. Store generated keys and project/region in your CI secrets as documented in `setup-gcp.sh`.

## Notes

- **Secrets:** prefer Secret Manager + IAM; avoid committing real values in `tfvars`.
- **Typesense:** optional module; review `modules/typesense` for startup script and sizing.
- Align **image URLs** and **Artifact Registry** repository id with your CI build pipeline.
