environment = "qa"
region      = "eu-west-1"

# RDS plan.
rds_instance_class          = "db.t4g.micro"
rds_allocated_storage       = 20
rds_storage_type            = "gp3"
rds_backup_retention_period = 3
rds_backup_window           = "03:00-04:00"
rds_maintenance_window      = "Mon:04:00-Mon:05:00"
rds_multi_az                = false
rds_deletion_protection     = false
rds_skip_final_snapshot     = true

# S3
s3_allow_local_access = true

# ECS 
ecs_task_min_count = 1
ecs_task_max_count = 2
ecs_enable_exec    = true


# ML Accesses
ml_arns = [
  "arn:aws:iam::018489564711:role/criusaiml-qa-ecs-execution-role",
  "arn:aws:iam::018489564711:role/criusaiml-qa-ecs-task-role"
]

# SQS Orchestrator
use_sqs_orchestrator = true
local_dev_queues     = ["indy", "service"]
request_queue_arn    = "arn:aws:sqs:eu-west-1:018489564711:criusaiml-qa-request-ml-task.fifo"
response_queue_arn   = "arn:aws:sqs:eu-west-1:018489564711:criusaiml-qa-response-ml-task.fifo"
