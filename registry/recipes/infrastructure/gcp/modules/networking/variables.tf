variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for VPC and related resource names"
  type        = string
}

variable "vpc_connector_min_throughput" {
  description = "Minimum throughput (Mbps) for the VPC Access Connector"
  type        = number
}

variable "vpc_connector_max_throughput" {
  description = "Maximum throughput (Mbps) for the VPC Access Connector"
  type        = number
}

