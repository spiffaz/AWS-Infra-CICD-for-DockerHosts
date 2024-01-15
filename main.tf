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

# locals {
#   workspace_name = var.workspace_tag
# }

module "baseResources" {
  source = "./modules/baseResources"

  # organization  = "spiff-cicd"
  # workspace_tag = "dev"
}

module "appResources" {
  source          = "./modules/appResources"
  vpc_id          = module.baseResources.vpc_id
  private_subnets = module.baseResources.private_subnets
  public_subnets  = module.baseResources.public_subnets
  vpc_cidr        = module.baseResources.vpc_cidr
  containerPort   = "5678"
  hostPort        = "5678"
}
