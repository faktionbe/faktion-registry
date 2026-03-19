# AWS infrastructure (Terraform)

**Registry recipe:** `aws` — Terraform layout for a full-stack AWS deployment: VPC, public ALB for the API, internal ALB for the SQS worker, ECS Fargate (server + SQS services), RDS PostgreSQL, S3 (app assets + static site), ECR, Secrets Manager, optional SQS dev queues and a Lambda orchestrator.

## Requirements

- **Terraform** `>= 1.11.3`
- **AWS provider** `~> 5.0` (declared in modules; default region in root is **`eu-west-1`**)
- **Remote state:** root uses `backend "s3" {}` — configure bucket/key/region (and locking if used) before `terraform init`.
- **ACM certificates:** ARNs for TLS on the API ALB and the static site (`custom_domain_api_certificate_arn`, `custom_domain_certificate_arn`). Comments in `variables.tf` reference **us-east-1** (typical for CloudFront); ensure ARNs match where the resources are created.

## High-level architecture

```text
Internet ──► Public ALB (HTTPS) ──► ECS server tasks (private subnets, :4000)
                    │
                    └── /api/health

Internal ALB (private subnets) ──► ECS SQS worker tasks (:4001, /health)

ECS tasks pull secrets from Secrets Manager; server talks to RDS, S3, and internal SQS ALB.

S3 (bucket) + optional ML IAM principals (ml_accesses)
S3 website module + custom domain (frontend)
ECR: server, frontend, sqs images
RDS PostgreSQL (see security notes below)

Optional: Lambda SQS orchestrator + FIFO dev queues (local_dev_queues) with queue policies
```

## Layout

| Path                               | Role                                               |
| ---------------------------------- | -------------------------------------------------- |
| `main.tf`                          | Root module wiring all components                  |
| `variables.tf`                     | Root input variables                               |
| `environments/qa/terraform.tfvars` | Example QA overrides                               |
| `modules/*`                        | Reusable Terraform modules (VPC, ALB, ECS, RDS, …) |

## Root module: what gets created

| Area                   | Description                                                                                                                                                                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Resource group**     | `resource_group` — logical grouping / tags                                                                                                                                                                                                                      |
| **Network**            | `vpc` — `10.0.0.0/16`, 2 public + 2 private subnets in `eu-west-1a/b`                                                                                                                                                                                           |
| **Load balancing**     | **Public** `alb_backend` — internet-facing, targets ECS server on port **4000**, health ` /api/health`, TLS from `custom_domain_api_certificate_arn`. **Internal** `alb_sqs` — in private subnets, ingress from VPC CIDR only, port **4001**, health `/health`. |
| **Secrets**            | `server-env`, `sqs-env` (empty JSON placeholders; **`ignore_secret_changes`** so you manage values in AWS/console without Terraform fighting you), `client-env` (includes `BACKEND_URL`), `db-env` (RDS connection + `DATABASE_URL`)                            |
| **Database**           | `rds` — PostgreSQL **17.4**, password from `random_password`                                                                                                                                                                                                    |
| **Security groups**    | `security_group` — ties ALBs and ECS tasks together                                                                                                                                                                                                             |
| **Storage**            | `s3` — general bucket (versioning lifecycle, optional local dev access via `s3_allow_local_access`). `s3_website` — static site + custom domain                                                                                                                 |
| **Container registry** | `ecr` — repositories **`server`**, **`frontend`**, **`sqs`**                                                                                                                                                                                                    |
| **Compute**            | `ecs_cluster` + `ecs_server` + `ecs_sqs` — Fargate, 2 desired tasks each (as in root), CloudWatch logs (30 days)                                                                                                                                                |
| **ML / data**          | `ml_accesses` — grants listed IAM ARNs access to the S3 bucket                                                                                                                                                                                                  |
| **SQS (optional)**     | `sqs_dev_queues` — one FIFO queue per name in `local_dev_queues`. `sqs_orchestrator` — Lambda (only if `use_sqs_orchestrator = true`). Queue policies allow the orchestrator role to `sqs:SendMessage` to dev queues                                            |

### Custom domain naming

- **`environment`** = `prod` → host-style domain is `var.custom_domain` as-is.
- Any other environment → **`{environment}.{custom_domain}`** (e.g. `qa` + `evals.faktion.ai` → `qa.evals.faktion.ai`).
- Server env sets `FRONTEND_URL` to `https://{that host}`; SQS worker uses `https://api.{that host}` for `BACKEND_URL` (ensure DNS/ALB matches your real API hostname).

## Variables (root)

### Required (no default in `variables.tf`)

| Variable                            | Purpose                                    |
| ----------------------------------- | ------------------------------------------ |
| `custom_domain`                     | Base domain for site / derived hostnames   |
| `custom_domain_certificate_arn`     | ACM cert for static site / CloudFront path |
| `custom_domain_api_certificate_arn` | ACM cert for public API ALB                |

Set explicitly (recommended for any real deploy):

| Variable       | Purpose                                                               |
| -------------- | --------------------------------------------------------------------- |
| `project_name` | Used in naming (secrets, buckets, ECR, etc.); default is empty string |

### Common optional variables

| Variable                                    | Default / notes                                                                                               |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `environment`                               | `qa`                                                                                                          |
| `region`                                    | `eu-west-1` (provider in `main.tf` is fixed to `eu-west-1`; keep in sync)                                     |
| `ml_arns`                                   | `[]` — IAM ARNs for ML workloads needing S3 access                                                            |
| **RDS**                                     | `rds_instance_class`, storage, backup windows, `multi_az`, `deletion_protection`, `skip_final_snapshot`, etc. |
| `s3_allow_local_access`                     | `true`                                                                                                        |
| `ecs_enable_exec`                           | `false` — enable ECS Exec for debugging                                                                       |
| `ecs_task_min_count` / `ecs_task_max_count` | Defined in variables; scaling wiring may live in modules — check `ecs_service` if you rely on these           |
| **SQS / orchestrator**                      | See below                                                                                                     |

### SQS orchestrator and dev queues

| Variable                                   | Purpose                                                                 |
| ------------------------------------------ | ----------------------------------------------------------------------- |
| `use_sqs_orchestrator`                     | When `true`, provisions `modules/lambda/sqs-orchestrator`               |
| `local_dev_queues`                         | List of **suffix names**; each becomes a FIFO SQS queue in this account |
| `request_queue_arn` / `response_queue_arn` | Passed into ECS services (cross-queue integration)                      |
| `sqs_orchestrator_queue_arn`               | Source queue for the Lambda (module input)                              |

**Important:** Dev queue IAM policies reference the orchestrator role (`module.sqs_orchestrator[0]`). If you set **`local_dev_queues`** to a non-empty list, you should set **`use_sqs_orchestrator = true`** and provide **`sqs_orchestrator_queue_arn`** so apply succeeds and policies are valid.

## Secrets you must populate (after apply)

Terraform creates the secrets; some versions use **`ignore_secret_changes`** so you update values in **AWS Secrets Manager** without drift:

- **`server-env`** — keys referenced by ECS include: `JWT_SECRET`, `ENCRYPTION_KEY`, `MODELS_S3_BUCKET`, `MODELS_S3_KEY`, `POSTMARK_API_KEY`, `POSTMARK_SENDER`, and `DATABASE_URL` is injected from **`db-env`** separately.
- **`sqs-env`** — `AWS_SQS_REQUEST_QUEUE`, `AWS_SQS_RESPONSE_QUEUE` (JSON keys; values are ARNs or URLs per your app contract).
- **`db-env`** — Managed by Terraform (RDS credentials + `DATABASE_URL`).

## RDS security (read before production)

`main.tf` includes explicit **development-oriented** settings:

- RDS subnets are currently **`public_subnet_ids`** (TODO in code: move to private when VPN is in place).
- `allowed_cidr_blocks = ["0.0.0.0/0"]` and **`publicly_accessible = true`**.

Tighten these for production (private subnets, restricted SG CIDRs, `publicly_accessible = false`, appropriate `deletion_protection` / snapshots).

## Using this recipe

1. Copy the recipe into your repo (e.g. via the shadcn registry / Faktion registry **`aw-iac`** recipe targets under `infrastructure/aws/`).
2. Configure the **S3 backend** for Terraform state.
3. Add a `terraform.tfvars` (see `environments/qa/terraform.tfvars` as a template) with **`project_name`**, domain, certificate ARNs, and any RDS/SQS/ML overrides.
4. Run `terraform init` → `terraform plan` → `terraform apply`.
5. Push images to **ECR** (`server`, `frontend`, `sqs`), fill **Secrets Manager**, and point **DNS** at the ALB / CloudFront outputs as defined in your modules.

## Modules reference

| Module                    | Responsibility                                                                    |
| ------------------------- | --------------------------------------------------------------------------------- |
| `resource_group`          | AWS resource group                                                                |
| `vpc`                     | VPC, subnets, routing                                                             |
| `alb`                     | Application Load Balancer (used twice: public API + internal SQS)                 |
| `secrets`                 | Secrets Manager secret + versioning / ignore rules                                |
| `rds`                     | PostgreSQL instance + subnet/SG wiring                                            |
| `security_group`          | ECS + ALB security groups                                                         |
| `s3`                      | General-purpose bucket                                                            |
| `s3_website`              | Static hosting + custom domain                                                    |
| `ecr`                     | Docker repositories                                                               |
| `ecs_cluster`             | ECS cluster + execution roles                                                     |
| `ecs_service`             | Fargate service, task def, LB attachment, IAM for secrets/SQS                     |
| `ml_accesses`             | S3 policy attachments for ML roles                                                |
| `sqs`                     | FIFO queue module                                                                 |
| `lambda/sqs-orchestrator` | Lambda placeholder for orchestration (replace `placeholder-index.js` in real use) |

For per-module inputs/outputs, see each module’s `variables.tf` and `outputs.tf`.
