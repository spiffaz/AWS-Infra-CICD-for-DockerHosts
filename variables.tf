variable "organization" {
  type        = string
  description = "Terraform cloud organization"
}

variable "workspace_tag" {
  type        = string
  description = "Name of terraform environment cloud tag. All created resources share this"
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
    project = "Microservice"
  }
}

variable "TF_API_TOKEN" {
  type        = string
  description = "Region AWS resources would be deployed in"
}
