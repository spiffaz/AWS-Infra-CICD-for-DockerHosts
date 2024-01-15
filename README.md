# Project README

Welcome to the project! This repository contains Terraform modules to set up the infrastructure for a containerized application on AWS cloud using Terraform Cloud for remote state management and Elastic Cloud for monitoring. A separate repository was cloned and contains the CICD pipeline for the application deployment. The CICD pipeline was written using GitHub Actions.

The components used (AWS, Terraform, Terraform Cloud, GitHub Actions and Elastic cloud) were chosen for this project to reduce the overhead of setting up multiple servers for monitoring, application and CICD stack. The components chosen can easily be adapted to any deployment format (web server, serverless, containers, ECS and Kubernetes) with a few tweaks.

For the application CICD, I used GitHub Actions, Dockerhub for the container registry, Trivy and AWS tools.

## Project Structure

- `modules/baseResources`: Terraform module to create VPC, subnets, security groups, and other foundational resources.
- `modules/appResources`: Terraform module to deploy an AWS application, including a load balancer and autoscaling group.

The following were adopted as part of the infrastructure design:

• High availability - Auto scaling groups were used to ensure high availability.

• Fault tolerance - Scaling policies were setup to ensure that the system is fault tolerant.

• Load balancing - An application load balancer was used to distribute traffic to members of the auto-scaling group.

• Network Security (security groups/Firewall or ACLs) - Best practices were followed by limiting access to security groups. Also went a step further to implement security group chaining to implement least privilege access.

• Encryption of data in transit and at rest (If applicatble) - Data was encrypted at rest on the EBS volumes attached to the instances. Also, all Cloudwatch logs were encrypted at rest.

• Backup and recovery mechanisms - A third workspace can be created in a different region (DR) with the same or a scaled-down architecture.

### CI/CD Integration

### Application Repository and CI/CD Pipeline

Following best practices, the infrastructure repo is separated from the application repo, including the CI/CD pipeline. The application repo can be found at [https://github.com/spiffaz/http-echo](https://github.com/spiffaz/http-echo), and the CI/CD pipeline can be found at `.github/workflows/build.yml`.

A GitHub Action was already in place for the build and unit testing of the project by the maintainers. The pipeline ended at the production of artefacts.

The GitHub action was modified to include:

• Scans & checks
• Deployment to staging environment.
• Automated deployment to production environment

## SSM Installation

A curated image is being used to reduce the setup time of the autoscaling groups. The base image has Docker and the Elastic agent installed for monitoring. The user data file for setting up the image is included in the `config.sh` file.

### Application and Infrastructure monitoring

Monitoring was implemented on both the infrastructure and application level.
Cloudwatch logs were implemented on the VPC to capture VPC flow logs.
Elastic cloud is used to capture and visualize logs and metrics from the EC2 hosts, it is also used to capture Load balancer, NAT and VPC logs from Cloudwatch.
Application logs are also captured on Elastic.

![image](https://github.com/spiffaz/AWS-Infra-CICD-for-DockerHosts/assets/35563797/d7231b51-9c5a-4d6d-aeb1-0147cd563f62)

![image](https://github.com/spiffaz/AWS-Infra-CICD-for-DockerHosts/assets/35563797/9402e93a-80d3-4855-91c2-daa6674b3ba4)

![image](https://github.com/spiffaz/AWS-Infra-CICD-for-DockerHosts/assets/35563797/94237002-0415-4cbf-bb82-b4aaf51ec671)


## How to Use

### Infrastructure Setup

1. **Configure Terraform Cloud Backend:**

   - Ensure you have a Terraform Cloud account.
   - Create an organization and replace my organization name "spiff-cicd in the code."
   - Update the `backend` configuration in the `main.tf` files with your organization details.
   - Update the terraform.tfvars file with your Terraform api key.
   - Obtain your AWS keys from the console or your admin, and configure the credentials as secrets in your Terraform cloud project.

     ```hcl
     backend "remote" {
       organization = "spiff-cicd"
       workspaces {
         prefix = "my-app-"
       }
     }
     ```

2. **Local Workspace Configuration:**

   - Create two separate workspaces for dev and prod.

     ```bash
     terraform workspace new dev
     terraform workspace new prod
     ```

### Dev Environment Deployment

1. **Configure Variables:**

   - Modify `variables.tf` in each module (`baseResources` and `appResources`) to include dev-specific variables.

2. **Deploy to Dev Workspace:**

   ```bash
   terraform workspace select dev
   terraform apply -auto-approve
   ```

### Prod Environment Deployment

1. **Configure Variables:**

   - Modify `variables.tf` in each module (`baseResources` and `appResources`) to include prod-specific variables.

2. **Deploy to Prod Workspace:**

   ```bash
   terraform workspace select prod
   terraform apply -auto-approve
   ```

This will create resources in 2 separate VPCs with the prefix dev and prod for ease of separation.

### Application CICD
I chose to build the image from source as the beginning of the CI process, I skipped unit tests as the developers would have to provide their tests for me to integrate to the pipeline.
There is also an image scan before the image is pushed to the container registry.
The image is pulled from the repository and deployed directly to the AWS instances using AWS Session manager. This will reduce the amount of keys that needs to be managed and is also secure.

### Application CICD steps

1. **Clone/Fork the GitHub Repository:**
2. **Create the secrets as GitHub Secrets:**
![image](https://github.com/spiffaz/AWS-Infra-CICD-for-DockerHosts/assets/35563797/b7ca3f5b-333a-4939-806f-bc831125d0c4)

3. **Enable the GitHub Action from the Actions tab**
4. **Make a change to the configuration. The pipeline will be triggered on push**

### Possible Improvements

Architecture
1. Implement WAF in front of the load balancer. Load balancers should ideally not be exposed.
2. Implement encryption in transit by using HTTPS on the load balancer.
3. Implement CICD and tests for infrastructure
4. Use AWS organizations or separate accounts for dev and prod
5. Properly implement Pre-commit hooks.

CICD
1. Implement branching strategies.
2. Implement more tests outside the maintainers tests.
3. Enable notifications to inform on status and share relevant artefacts.
4. Implement a deployment strategy other than rolling updates.
5. Implement automated rollbacks in the case where a rollback is needed.

Feel free to reach out if you have any questions or need further assistance!
