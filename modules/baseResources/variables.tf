# Calculate cidr rage based on number of subnets selected
locals {
  public_cidr_blocks  = [for i in range(var.public_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_cidr_blocks = [for i in range(var.private_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i + var.public_subnet_count)]
}

data "aws_availability_zones" "availabile" {
  state = "available"
}

variable "region" {
  type        = string
  description = "Region AWS resources would be deployed in"
  default     = "us-east-1"
}

variable "default_tags" {
  type        = map(string)
  description = "Map of default tags to apply to resources"
  default = {
    project = "CICD"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.255.0.0/20"
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets to create"
  default     = 3
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets to create"
  default     = 3
}
