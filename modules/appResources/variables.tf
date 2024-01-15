variable "region" {
  type        = string
  description = "Region AWS resources would be deployed in"
  default     = "us-east-1"
}

variable "key_name" {
  type        = string
  description = "(optional) describe your variable"
  default     = "cicd"
}

variable "middleware_server_image_id" {
  type        = string
  description = "Image id for middleware server"
  default     = "ami-022424e9634ea16d3"
}

variable "middleware_server_instance_type" {
  type        = string
  description = "Instance type for middleware server"
  default     = "t2.micro"
}

variable "middleware_server_max_no" {
  type        = number
  description = "Maximum number of middleware servers"
  default     = 2
}

variable "middleware_server_min_no" {
  type        = number
  description = "Minimum number of middleware servers"
  default     = 1
}

variable "private_subnets" {
  type        = list(string)
  description = "Subnets to create workload"
}

variable "public_subnets" {
  type        = list(string)
  description = "Subnets to create lb"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR of the VPC"
}

variable "hostPort" {
  type        = number
  description = "The external port exposed to the ECS container"
}

variable "containerPort" {
  type        = number
  description = "The internal port exposed on the ECS container"
}

variable "default_tags" {
  type        = map(string)
  description = "Map of default tags to apply to resources"
  default = {
    project = "CICD"
  }
}
