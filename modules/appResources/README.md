# Terraform AWS App Resources Module

This Terraform module is designed to create application resources on Amazon Web Services (AWS). The module provisions infrastructure components such as a load balancer, security groups, IAM roles, Auto Scaling Group (ASG), and associated resources. The application resources are configured to follow best practices, including security group rules, IAM role policies, and more.

## Architecture

The architecture created by this module consists of the following key components:

- **Load Balancer Security Group:** A security group specifically for the application load balancer is created. This security group allows incoming traffic on port 80 from any IP address.

- **Load Balancer:** An application load balancer is set up to distribute incoming traffic across multiple targets. It is configured to use security groups, subnets, and has a listener on port 80.

- **Target Group:** A target group is associated with the load balancer, specifying the targets (instances) that will receive traffic from the load balancer.

- **IAM Roles:** IAM roles are created for managing Systems Manager (SSM) and managing instances. These roles are attached to an instance profile.

- **Security Group for Auto Scaling Group (ASG):** A security group is created for the Auto Scaling Group, controlling inbound and outbound traffic.

- **Security Group Rules:** Security group rules are defined to control traffic between different components, ensuring a secure communication setup.

- **Launch Configuration:** A launch configuration is set up, defining the instance details for the ASG, including the image ID, instance type, and user data to start a Docker container.

- **Auto Scaling Group (ASG):** An ASG is configured to automatically adjust the number of instances in response to changes in demand. It is associated with the launch configuration, target group, and VPC.

## Prerequisites

Before using this module, ensure you have:

- Terraform installed (version 1.5 or higher)
- AWS credentials configured
- Configured Terraform Cloud as the remote backend, with workspaces set up for different environments, allowing you to use the same configuration for multiple environments.

## Features

- **Load Balancer:** Creates an application load balancer with specified configurations.
- **IAM Roles:** Creates IAM roles and policies for managing SSM and managing instances.
- **Security Groups:** Sets up security groups for the load balancer, ASG, and communication between components.
- **Auto Scaling Group:** Configures an ASG for automatic scaling based on demand.
- **Launch Configuration:** Defines a launch configuration for instances in the ASG.

## Systems Manager (SSM) Installation

To expedite the setup time of the Auto Scaling Groups, a curated Amazon Machine Image (AMI) is utilized. This base image includes Docker and the Elastic Agent for monitoring pre-installed. The SSM agent is also installed on instances to enable seamless management and maintenance.

## User Data File

The user data file used to configure instances is included in the module. This file, named `config.sh`, is responsible for installing necessary components such as the SSM agent, Docker, Docker Compose, and Elastic Agent. Additionally, it starts a sample Docker container (`http-echo`) to illustrate the Docker setup.

Feel free to customize the `config.sh` file to meet your specific requirements or to include additional setup steps.

## Usage

```hcl
module "my_app_resources" {
  source = "path/to/terraform-aws-app-resources"

  region                       = "us-east-1"
  default_tags                 = {
    project = "MyProject"
  }
  vpc_id                       = "vpc-12345678"
  vpc_cidr                     = "10.255.0.0/20"
  public_subnets               = ["subnet-abcdef", "subnet-ghijklm", "subnet-nopqrst"]
  private_subnets              = ["subnet-uvwxyz1", "subnet-uvwxyz2", "subnet-uvwxyz3"]
  hostPort                     = 80
  containerPort                = 8080
  middleware_server_image_id   = "ami-022424e9634ea16d3"
  middleware_server_instance_type = "t2.micro"
  middleware_server_max_no     = 2
  middleware_server_min_no     = 1
}
```

