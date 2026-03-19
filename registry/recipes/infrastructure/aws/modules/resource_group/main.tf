terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_resourcegroups_group" "environment_resources" {
  name = "${var.project_name}-${var.environment}-resources"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Environment"
          Values = [var.environment]
        },
        {
          Key    = "Project"
          Values = [var.project_name]
        }
      ]
    })
    type = "TAG_FILTERS_1_0"
  }

  tags = var.tags
}