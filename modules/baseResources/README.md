# Terraform AWS VPC Module

This Terraform module is designed to create a Virtual Private Cloud (VPC) on Amazon Web Services (AWS). The module provisions the necessary infrastructure components, including public and private subnets, internet gateway, NAT gateway, IAM roles, CloudWatch logs, and more. The VPC is configured with best practices, such as flow logs for monitoring and secure key management for encryption.

## Architecture

The architecture created by this module follows best practices for deploying applications on AWS. Here is an overview of the key components:

- **VPC Configuration:** The module creates a VPC with a specified CIDR block, enabling DNS support and configuring instance tenancy to default settings.

- **Flow Logs:** VPC flow logs are established to capture information about IP traffic going to and from network interfaces. This information is valuable for monitoring and troubleshooting network activity.

- **IAM Role:** An IAM role is created to provide access to VPC logs. This role allows the necessary permissions for CloudWatch Logs and facilitates secure access for monitoring purposes.

- **CloudWatch Logs:** The module sets up a CloudWatch log group for storing VPC logs. The log data is encrypted at rest using a Key Management Service (KMS) key, providing an additional layer of security.

- **Public and Private Subnets:** The VPC is divided into public and private subnets. Public subnets are associated with an internet gateway, allowing resources within these subnets to communicate with the internet. Private subnets, on the other hand, host workloads that are not directly accessible from the internet.

- **Internet Gateway:** An internet gateway is created for public subnets, enabling communication between resources in the VPC and the internet.

- **Route Tables:** Separate route tables are set up for public and private subnets. The public route table is associated with the internet gateway, while the private route table allows outbound traffic through a NAT gateway.

- **NAT Gateway:** A NAT gateway is established in a public subnet, providing private subnets with access to the internet for outbound traffic.

## Prerequisites

Before using this module, ensure you have:

- Terraform installed (version 1.5 or higher)
- AWS credentials configured
- Configured Terraform Cloud as the remote backend, with workspaces set up for different environments, allowing you to use the same configuration for multiple environments.

## Usage

```hcl
module "my_vpc" {
  source = "path/to/terraform-aws-vpc"

  region                = "us-east-1"
  default_tags          = {
    project = "MyProject"
  }
  vpc_cidr              = "10.255.0.0/20"
  public_subnet_count   = 3
  private_subnet_count  = 3
}
```

## Inputs

- `region` (string): AWS region where resources will be deployed.
- `default_tags` (map(string)): Default tags to apply to resources.
- `vpc_cidr` (string): CIDR block for the VPC.
- `public_subnet_count` (number): Number of public subnets to create.
- `private_subnet_count` (number): Number of private subnets to create.

## Outputs

- `kms_key_arn` (string): KMS key ARN used for CloudWatch logs encryption.
- `vpc_id` (string): ID of the created VPC.
- `vpc_cidr` (string): CIDR block of the created VPC.
- `private_subnets` (list(string)): IDs of private subnets.
- `public_subnets` (list(string)): IDs of public subnets.

## Features

- **VPC Configuration:** Creates a VPC with specified CIDR block, DNS support, and instance tenancy.
- **Flow Logs:** Sets up VPC flow logs for monitoring and captures traffic information.
- **IAM Role:** Creates an IAM role for accessing logs.
- **CloudWatch Logs:** Creates a CloudWatch log group for storing VPC logs with encrypted data at rest.
- **Public and Private Subnets:** Creates public and private subnets with specified counts.
- **Internet Gateway:** Creates an internet gateway for public subnets.
- **Route Tables:** Sets up route tables for public and private subnets with associations.
- **NAT Gateway:** Creates a NAT gateway for private subnets.

## Notes

- Ensure the AWS provider and version meet the specified requirements.
- Adjust the input variables according to your specific requirements.
