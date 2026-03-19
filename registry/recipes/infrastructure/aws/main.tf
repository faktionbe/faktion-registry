#tmp
terraform {
  required_version = ">= 1.11.3"

  backend "s3" {}
}

provider "aws" {
  region = "eu-west-1"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

locals {
  environment   = var.environment
  project_name  = var.project_name
  custom_domain = var.environment == "prod" ? var.custom_domain : "${var.environment}.${var.custom_domain}"
  common_tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
  }
  region      = "eu-west-1"
  account_id  = data.aws_caller_identity.current.account_id
  server_port = 4000
  sqs_port    = 4001
}

module "resource_group" {
  source = "./modules/resource_group"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
}

module "vpc" {
  source = "./modules/vpc"

  environment          = local.environment
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["eu-west-1a", "eu-west-1b"]
  tags                 = local.common_tags
  project_name         = local.project_name
}


module "alb_backend" {
  source = "./modules/alb"

  project_name            = "${local.project_name}-backend"
  environment             = local.environment
  tags                    = local.common_tags
  internal                = false
  public_subnet_ids       = module.vpc.public_subnet_ids
  vpc_id                  = module.vpc.vpc_id
  alb_ingress_cidr_blocks = ["0.0.0.0/0"]
  target_port             = local.server_port
  target_type             = "ip"
  health_check_path       = "/api/health"
  custom_domain           = local.custom_domain
  certificate_arn         = var.custom_domain_api_certificate_arn
  idle_timeout            = 4000
}

module "alb_sqs" {
  source = "./modules/alb"

  project_name            = "${local.project_name}-sqs"
  environment             = local.environment
  tags                    = local.common_tags
  internal                = true
  public_subnet_ids       = module.vpc.private_subnet_ids
  vpc_id                  = module.vpc.vpc_id
  alb_ingress_cidr_blocks = [module.vpc.vpc_cidr]
  target_port             = local.sqs_port
  target_type             = "ip"
  health_check_path       = "/health"
  idle_timeout            = 4000
}

module "secrets_server_env" {
  source = "./modules/secrets"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  secret_name   = "server-env"
  secret_string = jsonencode({})

  ignore_secret_changes = true
}

module "secrets_sqs_env" {
  source = "./modules/secrets"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  secret_name           = "sqs-env"
  secret_string         = jsonencode({})
  ignore_secret_changes = true
}

module "secrets_client_env" {
  source = "./modules/secrets"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  secret_name = "client-env"
  secret_string = jsonencode({
    BACKEND_URL = "https://${module.alb_backend.alb_dns_name}"
  })
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

module "rds" {
  source = "./modules/rds"

  project_name = local.project_name
  environment  = local.environment

  vpc_id = module.vpc.vpc_id
  # TODO: Change to private subnets when vpn is implemented
  private_subnet_ids = module.vpc.public_subnet_ids

  # Database configuration
  db_name     = local.project_name
  db_username = "postgres"
  db_password = random_password.db_password.result

  # Security configuration
  allowed_cidr_blocks = ["0.0.0.0/0"] # For development only, should be restricted in production
  publicly_accessible = true          # For development only, should be false in production

  # Instance configuration
  instance_class = var.rds_instance_class
  engine_version = "17.4"

  # Storage configuration
  allocated_storage = var.rds_allocated_storage
  storage_type      = var.rds_storage_type

  # Backup and maintenance
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  maintenance_window      = var.rds_maintenance_window

  # High availability
  multi_az = var.rds_multi_az

  # Security
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = var.rds_skip_final_snapshot

  tags = local.common_tags
}

module "security_group" {
  source = "./modules/security_group"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  vpc_id                        = module.vpc.vpc_id
  alb_backend_security_group_id = module.alb_backend.security_group_id
  alb_backend_port              = local.server_port
  alb_sqs_security_group_id     = module.alb_sqs.security_group_id
  alb_sqs_port                  = local.sqs_port
}

module "secrets_db_credentials" {
  source = "./modules/secrets"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  secret_name = "db-env"
  secret_string = jsonencode({
    username     = module.rds.rds_db_username
    password     = module.rds.rds_db_password
    host         = module.rds.rds_instance_address
    port         = module.rds.rds_db_port
    dbname       = module.rds.rds_db_name
    identifier   = module.rds.rds_instance_identifier
    DATABASE_URL = "postgresql://${module.rds.rds_db_username}:${module.rds.rds_db_password}@${module.rds.rds_instance_address}:${module.rds.rds_db_port}/${module.rds.rds_db_name}?sslmode=require"
  })
}


module "s3" {
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  noncurrent_version_expiration_days = 30
  block_public_policy                = false
  restrict_public_buckets            = false
  allow_local_access                 = var.s3_allow_local_access
}

module "ecr" {
  source = "./modules/ecr"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
  repositories = ["server", "frontend", "sqs"]
}

module "s3_website" {
  source = "./modules/s3_website"

  project_name = local.project_name
  environment  = local.environment

  tags            = local.common_tags
  custom_domain   = local.custom_domain
  certificate_arn = var.custom_domain_certificate_arn
}


module "ecs_cluster" {
  source = "./modules/ecs_cluster"

  project_name = local.project_name
  environment  = local.environment
  region       = local.region
  tags         = local.common_tags
}

module "ecs_server" {
  source = "./modules/ecs_service"

  project_name = local.project_name
  environment  = local.environment
  service_name = "server"
  tags         = local.common_tags

  local_dev_queues   = var.local_dev_queues
  request_queue_arn  = var.request_queue_arn
  response_queue_arn = var.response_queue_arn

  # Cluster configuration
  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  execution_role_arn = module.ecs_cluster.execution_role_arn

  # Task configuration
  task_cpu           = "256"
  task_memory        = "512"
  container_port     = local.server_port
  health_check_path  = "/api/health"
  ecr_repository_url = module.ecr.repository_urls["server"]

  # Networking
  subnet_ids       = module.vpc.private_subnet_ids
  security_groups  = [module.security_group.ecs_tasks_security_group_id]
  assign_public_ip = false

  # Load balancer
  target_group_arn = module.alb_backend.target_group_arn

  # Container configuration
  container_secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = "${module.secrets_db_credentials.credentials_secret_arn}:DATABASE_URL::"
    },
    {
      name      = "JWT_SECRET"
      valueFrom = "${module.secrets_server_env.credentials_secret_arn}:JWT_SECRET::"
    },
    {
      name      = "ENCRYPTION_KEY"
      valueFrom = "${module.secrets_server_env.credentials_secret_arn}:ENCRYPTION_KEY::"
    },
    {
      name      = "MODELS_S3_BUCKET"
      valueFrom = "${module.secrets_server_env.credentials_secret_arn}:MODELS_S3_BUCKET::"
    },
    {
      name      = "MODELS_S3_KEY"
      valueFrom = "${module.secrets_server_env.credentials_secret_arn}:MODELS_S3_KEY::"
    },
    {
      name      = "POSTMARK_API_KEY"
      valueFrom = "${module.secrets_server_env.credentials_secret_arn}:POSTMARK_API_KEY::"
    },
    {
      name      = "POSTMARK_SENDER"
      valueFrom = "${module.secrets_server_env.credentials_secret_arn}:POSTMARK_SENDER::"
    },
  ]
  container_environment = [
    {
      name  = "FRONTEND_URL"
      value = "https://${local.custom_domain}"
    },
    {
      name  = "AWS_S3_BUCKET"
      value = module.s3.bucket_name
    },
    {
      name  = "SQS_BACKEND_URL"
      value = "http://${module.alb_sqs.alb_dns_name}"
    },
    {
      name  = "AWS_REGION"
      value = local.region
    },
    {
      name  = "PORT",
      value = local.server_port
    }
  ]
  region                = local.region
  log_retention_days    = 30
  service_desired_count = 2
  secret_manager_arns = [
    module.secrets_server_env.credentials_secret_arn,
    module.secrets_db_credentials.credentials_secret_arn
  ]
  enable_exec = var.ecs_enable_exec
}

module "ecs_sqs" {
  source = "./modules/ecs_service"

  project_name = local.project_name
  environment  = local.environment
  service_name = "sqs"
  tags         = local.common_tags

  local_dev_queues   = var.local_dev_queues
  request_queue_arn  = var.request_queue_arn
  response_queue_arn = var.response_queue_arn

  # Cluster configuration
  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  execution_role_arn = module.ecs_cluster.execution_role_arn

  # Task configuration
  task_cpu           = "256"
  task_memory        = "512"
  container_port     = local.sqs_port
  health_check_path  = "/health"
  ecr_repository_url = module.ecr.repository_urls["sqs"]

  # Networking
  subnet_ids       = module.vpc.private_subnet_ids
  security_groups  = [module.security_group.ecs_tasks_sqs_security_group_id]
  assign_public_ip = false

  container_secrets = [
    {
      name      = "AWS_SQS_REQUEST_QUEUE"
      valueFrom = "${module.secrets_sqs_env.credentials_secret_arn}:AWS_SQS_REQUEST_QUEUE::"
    },
    {
      name      = "AWS_SQS_RESPONSE_QUEUE"
      valueFrom = "${module.secrets_sqs_env.credentials_secret_arn}:AWS_SQS_RESPONSE_QUEUE::"
    },
  ]
  container_environment = [
    {
      name  = "BACKEND_URL"
      value = "https://api.${local.custom_domain}"
    },
    {
      name  = "AWS_REGION"
      value = local.region
    },
    {
      name  = "PORT",
      value = local.sqs_port
    }
  ]
  region                = local.region
  log_retention_days    = 30
  service_desired_count = 2
  secret_manager_arns = [
    module.secrets_sqs_env.credentials_secret_arn
  ]
  target_group_arn = module.alb_sqs.target_group_arn
  enable_exec      = var.ecs_enable_exec
}

module "ml_accesses" {
  source = "./modules/ml_accesses"

  s3_bucket_name = module.s3.bucket_name
  s3_bucket_arn  = module.s3.bucket_arn
  arns           = var.ml_arns
}



module "sqs_orchestrator" {
  count = var.use_sqs_orchestrator ? 1 : 0

  source = "./modules/lambda/sqs-orchestrator"

  region           = local.region
  project_name     = local.project_name
  environment      = local.environment
  tags             = local.common_tags
  source_queue_arn = var.sqs_orchestrator_queue_arn
}

module "sqs_dev_queues" {
  source = "./modules/sqs"

  for_each = toset(var.local_dev_queues)

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  queue_name                  = each.value
  is_fifo                     = true
  deduplication_scope         = "messageGroup"
  content_based_deduplication = false
  kms_master_key_id           = "alias/aws/sqs"
}


data "aws_iam_policy_document" "sqs_dev_queue_policy" {
  for_each = toset(var.local_dev_queues)

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [module.sqs_orchestrator[0].sqs_orchestrator_iam_role_arn]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [module.sqs_dev_queues[each.key].queue_arn]
  }
}
resource "aws_sqs_queue_policy" "dev_queue_policies" {
  for_each = toset(var.local_dev_queues)

  queue_url = module.sqs_dev_queues[each.key].queue_url
  policy    = data.aws_iam_policy_document.sqs_dev_queue_policy[each.key].json
}
