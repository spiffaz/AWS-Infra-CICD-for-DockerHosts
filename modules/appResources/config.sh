#!/bin/bash
# Install SSM agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Install Docker
sudo yum update -y
sudo yum install docker -y
sudo usermod -a -G docker ec2-user
sudo sudo id ec2-user
sudo newgrp docker

# Install Docker compose
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod -v +x /usr/local/bin/docker-compose
sudo systemctl enable docker.service
sudo systemctl start docker.service
docker run -d -p 5678:5678 --name http-echo spiffaz/http-echo:amd64-1.0.1

# Install Elastic agent
sudo curl -L -O https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-8.11.4-linux-x86_64.tar.gz
sudo tar xzvf elastic-agent-8.11.4-linux-x86_64.tar.gz
cd elastic-agent-8.11.4-linux-x86_64
sudo ./elastic-agent install --url=https://2ea7bbdbb927432e9174d5ec4a04790b.fleet.us-central1.gcp.cloud.es.io:443 --enrollment-token=Y1BWNkNZMEJZSnV2S3RFdWQyNTI6QUhPOXMzVXFSd1Nmam0tS1BocGlWQQ==
  
