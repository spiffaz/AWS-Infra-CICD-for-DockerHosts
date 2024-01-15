terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17"
    }
  }

  backend "remote" {
    organization = "spiff-cicd"
    workspaces {
      prefix = "my-app-"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.default_tags
  }
}

# Create VPC for AWS resources
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-vpc"
  }
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"
  assign_generated_ipv6_cidr_block = "false"
  instance_tenancy                 = "default"
}

# To restrict all traffic to the default security group in the VPC (Best practice)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# Create VPC flow log to capture information about the IP traffic going to and from network interfaces
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_iam.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-vpc-flow-log"
  }
}

# Create an IAM role for access to the logs
resource "aws_iam_role" "vpc_iam" {
  name               = "${terraform.workspace}-${var.default_tags.project}-vpc-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create a cloudwatch log group for the VPC logs (This is also shipped to Elastic)
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "${terraform.workspace}-${var.default_tags.project}-vpc-flow-log-group"
  depends_on        = [aws_kms_key.vpc_log_group_key, aws_kms_key_policy.vpc_logs_key_policy]
  retention_in_days = 365
  kms_key_id        = aws_kms_key.vpc_log_group_key.arn
}

# KMS key to encrypt the log data at rest, will be used for all at rest encryption 
resource "aws_kms_key" "vpc_log_group_key" {
  description             = "KMS key for CloudWatch Log Group encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-vpc-flow-log-group-key"
  }
}

# Policy for the kms key, if not defined, you will not be able to delete or make changes to the key after creation`
resource "aws_kms_key_policy" "vpc_logs_key_policy" {
  key_id = aws_kms_key.vpc_log_group_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs use of key"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Enable IAM User Permissions to logs"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "logs:*"
        Resource = "*"
      },
    ]
  })
}

# Public Subnets to be used by the load balancer. Workloads will be in a private subnet not directly assessible to the internet
resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidr_blocks[count.index]
  map_public_ip_on_launch = false
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-public-${data.aws_availability_zones.availabile.names[count.index]}"
  }
  availability_zone = data.aws_availability_zones.availabile.names[count.index]
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-internet-gateway"
  }
}

# Public Route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-public-route-table"
  }
}

# Make public route table public by associating an internet gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Add subnet to route table
resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnet where workloads will be deployed
resource "aws_subnet" "private" {
  count      = var.private_subnet_count
  vpc_id     = aws_vpc.main.id
  cidr_block = local.private_cidr_blocks[count.index]
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-private-${data.aws_availability_zones.availabile.names[count.index]}"
  }
  availability_zone = data.aws_availability_zones.availabile.names[count.index]
}

# Private Route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-private-route-table"
  }
}

# eip for NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    "Name" = "${terraform.workspace}-${var.default_tags.project}-nat"
  }
  depends_on = [aws_eip.nat, aws_internet_gateway.gw]
}

# Allow access to the internet from private subnets
resource "aws_route" "private_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Add subnet to private route table
resource "aws_route_table_association" "private" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
