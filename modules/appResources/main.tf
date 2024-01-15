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

# Load balancer security group in public subnet
# Allow traffic from everywhere over the internet to the load balancer security group
resource "aws_security_group" "public_lb" {
  name        = "${terraform.workspace}-${var.default_tags.project}-public-lb"
  description = "security group for application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#tfsec:ignore:aws-elb-alb-not-public
# This is ignoring the vulnerability picked in my precommit config of exposing load balancer to the public
# Note: should implement WAF in front of load balancer
resource "aws_lb" "public_lb" {
  name                       = "${terraform.workspace}-${var.default_tags.project}-public-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.public_lb.id]
  subnets                    = var.public_subnets
  idle_timeout               = 60
  ip_address_type            = "ipv4"
  drop_invalid_header_fields = true
  tags = {
    "Environmant" = "${terraform.workspace}"
  }
  #   enable_deletion_protection = true  #  Should be uncommented in production, but I want to be able to delete in my test env without hassle
}

# Target group for load balancer
resource "aws_lb_target_group" "workload_targets" {
  name                 = "${terraform.workspace}-${var.default_tags.project}-public-lb-tg"
  port                 = var.containerPort
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 60
    protocol            = "HTTP"
  }

  tags = { "Name" = "${terraform.workspace}-${var.default_tags.project}-workload-tg" }
}

# LB listener
resource "aws_lb_listener" "public_lb" {
  load_balancer_arn = aws_lb.public_lb.arn
  port              = "80"
  #   change to https to enable encryption in transit. Also requires a certficate and registered domain name
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.workload_targets.arn
  }
}

# IAM configuration to create and attach role to ASG
resource "aws_iam_role" "ssm_full_access" {
  name = "SSMFullAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  # Attach policies for SSMFullAccess
  inline_policy {
    name   = "SSMFullAccessPolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ssm:*",
      "Resource": "*"
    }
  ]
}
EOF
  }
}

resource "aws_iam_role" "ssm_managed_instance_core" {
  name = "SSMManagedInstanceCoreRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Principal = {
        Service = "ssm.amazonaws.com"
      }
    }]
  })


  inline_policy {
    name   = "SSMManagedInstanceCorePolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ssm:UpdateInstanceInformation",
      "Resource": "*"
    }
  ]
}
EOF
  }
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_managed_instance_core.name
}

resource "aws_iam_role_policy_attachment" "ssm-policy" {
  role       = aws_iam_role.ssm_managed_instance_core.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Security group for ASG
resource "aws_security_group" "workload" {
  name_prefix = "${terraform.workspace}-${var.default_tags.project}-private-workload"
  description = "Workload service security group."
  vpc_id      = var.vpc_id
}

# Allow ONLY traffic from the LB security group on a specified port
resource "aws_security_group_rule" "workload_allow" {
  security_group_id        = aws_security_group.workload.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.hostPort
  to_port                  = var.hostPort
  source_security_group_id = aws_security_group.public_lb.id
  #   cidr_blocks              = [var.vpc_cidr]
  description = "Allow incoming traffic from the LB to the service port."
}

# Allow port 80 from the vpc into the security group to allow the use of ssm
resource "aws_security_group_rule" "workload_allow_ssm_80" {
  security_group_id = aws_security_group.workload.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow incoming traffic from ssm."
}

# Allow port 443 from the vpc into the security group to allow the use of ssm
resource "aws_security_group_rule" "workload_allow_ssm_443" {
  security_group_id = aws_security_group.workload.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow incoming traffic from ssm."
}

resource "aws_security_group_rule" "workload_allow_outbound" {
  security_group_id = aws_security_group.workload.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  # cidr_blocks       = ["0.0.0.0/0"]
  source_security_group_id = aws_security_group.public_lb.id
  description              = "Allow all outbound traffic."
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_configuration" "workload" {
  name     = "${terraform.workspace}-${var.default_tags.project}-instance"
  image_id = var.middleware_server_image_id # Built a base image with monitoring configuration built in, it is the default image in the variable declaration
  #   image_id             = data.aws_ami.amazon_linux_2.id   # Amazon Linux 2 image, if you prefer to start from scratch
  instance_type        = var.middleware_server_instance_type
  key_name             = var.key_name # Comment out in your implementation, we will be connecting to the instances via session manager
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  metadata_options {
    http_tokens = "required"
  }
  #   Encryption at rest
  root_block_device {
    encrypted = true
  }

  security_groups = [aws_security_group.workload.id]
  lifecycle {
    create_before_destroy = true
  }
  user_data = <<EOF
#!/bin/bash
docker start http-echo
EOF
  #   user_data = "${file("${path.module}/config.sh")}" # If starting from the Amaxon Linux 2 image, this is the user data to build
}

resource "aws_autoscaling_group" "workload" {
  name_prefix          = "${terraform.workspace}-"
  launch_configuration = aws_launch_configuration.workload.name
  max_size             = var.middleware_server_max_no
  min_size             = var.middleware_server_min_no
  vpc_zone_identifier  = var.private_subnets
  target_group_arns    = [aws_lb_target_group.workload_targets.arn]
  health_check_type    = "ELB"

  tag {
    key                 = "Name"
    value               = "${terraform.workspace}-${var.default_tags.project}-asg"
    propagate_at_launch = true
  }
}
