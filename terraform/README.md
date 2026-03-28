# Terraform Infrastructure

This folder provisions the AWS infrastructure for the `realtime-chat-app` dev environment in `us-east-1`.

The stack includes:

- A custom VPC with public and private subnets
- An Internet Gateway and NAT Gateway
- A bastion host in the public subnet
- A private application EC2 instance
- A private Jenkins EC2 instance
- An Application Load Balancer with listeners for the app and Jenkins
- An ECR repository for frontend images
- Bootstrap scripts for Docker tooling and Jenkins installation

## Architecture

High-level layout:

- Public subnet A:
  - Bastion host
  - NAT Gateway
  - ALB
- Public subnet B:
  - ALB
- Private subnet A:
  - App EC2
  - Jenkins EC2

Traffic flow:

- Internet traffic reaches the ALB on port `80` for the app
- Internet traffic reaches the ALB on port `81` for Jenkins
- ALB forwards app traffic to the app target group
- ALB forwards Jenkins traffic to the Jenkins target group
- Bastion is used for SSH access into private instances
- Private instances use the NAT Gateway for outbound internet access

## Files

- [00-provider.tf](/i:/tummoc-devops-assignment/terraform/00-provider.tf): AWS provider and S3 backend configuration
- [10-variables.tf](/i:/tummoc-devops-assignment/terraform/10-variables.tf): input variables and defaults
- [11-locals.tf](/i:/tummoc-devops-assignment/terraform/11-locals.tf): common naming and tags
- [20-vpc.tf](/i:/tummoc-devops-assignment/terraform/20-vpc.tf): VPC, subnets, route tables, route associations
- [30-nat.tf](/i:/tummoc-devops-assignment/terraform/30-nat.tf): Elastic IP and NAT Gateway
- [40-sg.tf](/i:/tummoc-devops-assignment/terraform/40-sg.tf): security groups for ALB, bastion, app, and Jenkins
- [45-ecr.tf](/i:/tummoc-devops-assignment/terraform/45-ecr.tf): ECR repository
- [50-ec2.tf](/i:/tummoc-devops-assignment/terraform/50-ec2.tf): Ubuntu AMI lookup and EC2 instances
- [60-alb.tf](/i:/tummoc-devops-assignment/terraform/60-alb.tf): ALB, target groups, listeners, and attachments
- [docker_setup.sh](/i:/tummoc-devops-assignment/terraform/docker_setup.sh): app instance bootstrap script
- [jenkins_setup.sh](/i:/tummoc-devops-assignment/terraform/jenkins_setup.sh): Jenkins instance bootstrap script

## Provisioned Resources

### Networking

- VPC CIDR: `10.0.0.0/16`
- Public subnet A: `10.0.1.0/24`
- Public subnet B: `10.0.3.0/24`
- Private subnet A: `10.0.2.0/24`

### Compute

- Bastion:
  - Instance type: `t3.micro`
  - Public IP: enabled
  - SSH allowed from anywhere
- App server:
  - Instance type: `t3.small`
  - Private subnet only
  - Bootstraps Docker, Docker Compose, npm, Java, and AWS CLI
- Jenkins server:
  - Instance type: `t3.small`
  - Private subnet only
  - Bootstraps Jenkins on Ubuntu 24.04

### Load Balancer

- Listener `80`:
  - forwards to app target group
- Listener `81`:
  - forwards to Jenkins target group

### Container Registry

- ECR repository: `${var.project}/frontend`

## Security Model

- Bastion SG:
  - inbound `22` from `0.0.0.0/0`
- ALB SG:
  - inbound `80` from `0.0.0.0/0`
  - inbound `81` from `0.0.0.0/0`
- App SG:
  - inbound app traffic from ALB SG
  - inbound SSH from bastion SG
  - inbound SSH from Jenkins SG
- Jenkins SG:
  - inbound `22` from bastion SG
  - inbound `8080` from ALB SG

## Bootstrap Behavior

### App Instance

The app instance uses [docker_setup.sh](/i:/tummoc-devops-assignment/terraform/docker_setup.sh) as `user_data`.

It currently:

- updates and upgrades packages
- installs Docker
- installs Docker Compose v2
- adds the `ubuntu` user to the Docker group
- installs `npm`
- installs Java 21
- installs AWS CLI v2

### Jenkins Instance

The Jenkins instance uses [jenkins_setup.sh](/i:/tummoc-devops-assignment/terraform/jenkins_setup.sh) as `user_data`.

It currently:

- updates package indexes
- installs Java 21, `fontconfig`, and `wget`
- adds the Jenkins apt repository
- installs Jenkins
- enables and starts the Jenkins service

## Defaults

Current defaults from [10-variables.tf](/i:/tummoc-devops-assignment/terraform/10-variables.tf):

- `project = "realtime-chat-app"`
- `environment = "dev"`
- `region = "us-east-1"`
- `bastion_instance = "t3.micro"`
- `app_instance = "t3.small"`
- `key_pair_name = "cyberpunk-dev"`

## Backend

Remote state is configured in S3:

- bucket: `cyberpunk-app-tfstate`
- key: `dev/terraform.tfstate`
- region: `us-east-1`
- lockfile: enabled
- encryption: enabled

The S3 bucket must already exist before running `terraform init`.

## How To Deploy

Run from the `terraform` directory:

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```

To destroy:

```powershell
terraform destroy
```

## Access After Deploy

- Bastion:
  - SSH using the configured key pair
- Application:
  - access through the ALB on port `80`
- Jenkins:
  - access through the ALB on port `81`
  - direct SSH only through the bastion