output "repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
  }
  description = "The URLs of the ECR repositories"
}

output "repository_arns" {
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.arn
  }
  description = "The ARNs of the ECR repositories"
} 