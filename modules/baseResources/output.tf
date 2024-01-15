output "kms_key_arn" {
  description = "KMS key to be used for Cloudwatch logs"
  value       = aws_kms_key.vpc_log_group_key.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC ID"
  value       = aws_vpc.main.cidr_block
}

output "private_subnets" {
  description = "Subnets for ECS workloads"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "Subnets for ECS workloads"
  value       = aws_subnet.public[*].id
}
