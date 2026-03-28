# DevOps Assignment Submission

This repository is my submission for a DevOps practical assignment based on a team starting with no CI/CD, no containerization, and no monitoring.

I designed and implemented a minimal end-to-end DevOps setup around a sample realtime chat application, covering infrastructure provisioning, automated delivery, containerized deployment, and observability.

## Tech Stack

- `Infrastructure as Code`: Terraform, AWS
- `CI/CD`: Jenkins, GitHub webhook
- `Containerization`: Docker, Docker Compose, AWS ECR
- `Runtime / App`: Node.js, Express, Socket.IO, Nginx
- `Monitoring`: Prometheus, Grafana, `prom-client`

## Highlights

- Provisioned AWS infrastructure with Terraform
- Built a Jenkins-based CI/CD pipeline for lint, test, build, push, and deploy
- Containerized the application with Docker and deployed it with Docker Compose
- Added Prometheus metrics and Grafana-based monitoring
- Separated Jenkins and application workloads onto different EC2 instances

## What This Repository Demonstrates

- CI/CD with Jenkins
- Docker image build and deployment
- Infrastructure as Code with Terraform on AWS
- Reverse proxying with Nginx
- Monitoring with Prometheus and Grafana
- An application instrumented with Prometheus metrics

## Project Structure

```text
.
|-- README.md
|-- realtime-chat-app/
|   `-- app/
|       |-- Dockerfile
|       |-- docker-compose.yml
|       |-- Jenkinsfile
|       |-- nginx.conf
|       |-- package.json
|       |-- prometheus.yml
|       |-- server.js
|       |-- script.js
|       |-- style.css
|       `-- index.html
`-- terraform/
    |-- 00-provider.tf
    |-- 10-variables.tf
    |-- 11-locals.tf
    |-- 20-vpc.tf
    |-- 30-nat.tf
    |-- 40-sg.tf
    |-- 45-ecr.tf
    |-- 50-ec2.tf
    |-- 60-alb.tf
    |-- 70-outputs.tf
    |-- docker_setup.sh
    `-- jenkins_setup.sh
```

## Solution Overview

I used a Node.js + Socket.IO chat application as the sample workload and designed the platform around a simple but realistic AWS deployment model.

At a high level:

1. Terraform provisions the AWS infrastructure.
2. Jenkins runs on its own EC2 instance inside the private subnet.
3. The application runs on a separate EC2 instance, also in the private subnet.
4. Jenkins builds the Docker image, pushes it to AWS ECR, and deploys it to the application server using Docker Compose.
5. Prometheus scrapes application metrics and Grafana visualizes them.
6. An Application Load Balancer exposes the app and Jenkins to the outside world.

## Architecture

```text
Developer
   |
   v
GitHub repository
   |
   v
GitHub webhook
   |
   v
Jenkins pipeline
lint -> test -> docker build -> push to ECR -> deploy
   |
   v
Application EC2
Docker Compose stack:
frontend + nginx + prometheus + grafana
   |
   v
Application Load Balancer
80 -> chat app
81 -> Jenkins
```

## 1. Infrastructure as Code

Infrastructure is implemented with Terraform in the [terraform](/i:/tummoc-devops-assignment/terraform) folder.

### AWS Resources Provisioned

The Terraform code provisions:

- a custom VPC
- public and private subnets
- an Internet Gateway
- a NAT Gateway
- security groups
- a bastion host
- an application EC2 instance
- a Jenkins EC2 instance
- an Application Load Balancer
- target groups and listeners
- an AWS ECR repository for Docker images

### IaC Design

The infrastructure is intentionally split into layers:

- [00-provider.tf](/i:/tummoc-devops-assignment/terraform/00-provider.tf): provider and backend configuration
- [10-variables.tf](/i:/tummoc-devops-assignment/terraform/10-variables.tf): reusable variables
- [20-vpc.tf](/i:/tummoc-devops-assignment/terraform/20-vpc.tf): networking foundation
- [30-nat.tf](/i:/tummoc-devops-assignment/terraform/30-nat.tf): outbound internet access for private resources
- [40-sg.tf](/i:/tummoc-devops-assignment/terraform/40-sg.tf): security boundaries
- [45-ecr.tf](/i:/tummoc-devops-assignment/terraform/45-ecr.tf): image registry
- [50-ec2.tf](/i:/tummoc-devops-assignment/terraform/50-ec2.tf): compute instances
- [60-alb.tf](/i:/tummoc-devops-assignment/terraform/60-alb.tf): ingress routing

This makes the infrastructure easier to review, reason about, and extend.

### Network Layout

The network is designed as:

- public subnet A: bastion host, NAT Gateway, ALB
- public subnet B: ALB high-availability subnet
- private subnet A: application EC2 and Jenkins EC2

The private instances do not receive public IPs. Outbound access is provided through the NAT Gateway.

### Security Design

Security groups are configured so that:

- the ALB accepts internet traffic on ports `80` and `81`
- the bastion accepts SSH from the internet
- the application server accepts HTTP traffic only from the ALB
- the application server accepts SSH only from bastion and Jenkins
- the Jenkins server accepts port `8080` only from the ALB
- the Jenkins server accepts SSH only from the bastion

This reduces direct exposure of internal servers.

### Compute Design

The compute layer includes:

- bastion host for administrative access
- app EC2 instance for containerized deployment
- Jenkins EC2 instance for CI/CD execution

Bootstrap scripts are also included:

- [terraform/docker_setup.sh](/i:/tummoc-devops-assignment/terraform/docker_setup.sh): installs Docker, Docker Compose, Java, npm, and AWS CLI on the app server
- [terraform/jenkins_setup.sh](/i:/tummoc-devops-assignment/terraform/jenkins_setup.sh): installs and starts Jenkins on the Jenkins server

### Load Balancer Design

The Application Load Balancer routes:

- port `80` to the chat application target group
- port `81` to the Jenkins target group

This provides a single external entry point for both services.

### Registry Design

Terraform also creates an ECR repository for the frontend image in [terraform/45-ecr.tf](/i:/tummoc-devops-assignment/terraform/45-ecr.tf).

The Jenkins pipeline uses this repository to store versioned Docker images before deployment.

## 2. CI/CD Setup

CI/CD is implemented using Jenkins in [realtime-chat-app/app/Jenkinsfile](/i:/tummoc-devops-assignment/realtime-chat-app/app/Jenkinsfile).

The pipeline includes the required stages:

- `Install Node Dependencies`
- `Lint`
- `Test`
- `Build & Push Docker Image to AWS ECR`
- `Deploy with Docker Compose`

### Jenkins Trigger Flow

The deployment flow is:

1. Code is pushed to the GitHub repository.
2. A GitHub webhook notifies Jenkins.
3. Jenkins starts the pipeline job automatically.
4. Jenkins reads the application version from `package.json`.
5. Jenkins installs dependencies and runs lint and test steps.
6. Jenkins builds a Docker image for the application.
7. Jenkins tags and pushes the image to AWS ECR.
8. Jenkins deploys the new version on the application EC2 server using Docker Compose.

This replaces manual deployment with a repeatable release process.

### What The Jenkins Pipeline Does

The pipeline is designed to:

- read the app version dynamically from [package.json](/i:/tummoc-devops-assignment/realtime-chat-app/app/package.json)
- authenticate Docker to AWS ECR
- build the app image from [Dockerfile](/i:/tummoc-devops-assignment/realtime-chat-app/app/Dockerfile)
- push a versioned image to ECR
- export deployment variables such as `APP_VERSION`, `ACC_ID`, and `ALB_DNS`
- run `docker compose pull`
- run `docker compose up -d`

This keeps the deployed version aligned with the version defined in the application source.

### Jenkins and Application Server Design

The infrastructure separates responsibilities:

- Jenkins runs on its own private EC2 instance
- the chat application runs on a different private EC2 instance
- both instances are inside the same VPC
- the bastion host is used for controlled SSH access into private resources
- the ALB exposes only the required application endpoints

This is a stronger design than running Jenkins and the application on the same host, because CI/CD and runtime workloads are isolated.

## 3. Docker Setup

The application is containerized using Docker and deployed with Docker Compose.

Main files:

- [realtime-chat-app/app/Dockerfile](/i:/tummoc-devops-assignment/realtime-chat-app/app/Dockerfile)
- [realtime-chat-app/app/docker-compose.yml](/i:/tummoc-devops-assignment/realtime-chat-app/app/docker-compose.yml)
- [realtime-chat-app/app/nginx.conf](/i:/tummoc-devops-assignment/realtime-chat-app/app/nginx.conf)

### Dockerfile Design

The Dockerfile uses a multi-stage build:

- build stage installs dependencies and prepares the app
- runtime stage runs the app with a non-root user

This keeps the container cleaner and safer than a single-stage image running as root.

### Docker Compose Design

The Compose stack includes:

- `frontend`: the Node.js chat application
- `nginx`: reverse proxy in front of the stack
- `prometheus`: metrics scraping
- `grafana`: dashboard visualization

This creates a single deployable stack that includes both the application and its observability layer.

## 4. Monitoring

The optional monitoring section is implemented as part of the deployed stack.

Main monitoring-related files:

- [realtime-chat-app/app/server.js](/i:/tummoc-devops-assignment/realtime-chat-app/app/server.js)
- [realtime-chat-app/app/prometheus.yml](/i:/tummoc-devops-assignment/realtime-chat-app/app/prometheus.yml)
- [realtime-chat-app/app/nginx.conf](/i:/tummoc-devops-assignment/realtime-chat-app/app/nginx.conf)
- [realtime-chat-app/app/docker-compose.yml](/i:/tummoc-devops-assignment/realtime-chat-app/app/docker-compose.yml)

### Monitoring Design

Monitoring works as follows:

- the Node.js application exposes metrics on `/metrics`
- Prometheus scrapes the application metrics endpoint
- Grafana provides dashboards for visualization
- Nginx exposes the services behind a single entry point

This makes it possible to observe both user-facing HTTP traffic and realtime socket activity.

### Metrics Added In The Application

The app exports several useful metrics through `prom-client`, including:

- HTTP request duration
- total socket connections
- total socket disconnections
- total chat messages
- active socket connections
- active chat users

This shows observability at both the HTTP and realtime socket layer, which is valuable for a chat application.

## App Used

The application used for this assignment is a realtime chat app built with:

- Node.js
- Express
- Socket.IO

The app serves the frontend, handles realtime messaging, and exposes Prometheus metrics from the same service.

Main application file:

- [realtime-chat-app/app/server.js](/i:/tummoc-devops-assignment/realtime-chat-app/app/server.js)

## How To Run

### Run the app locally

From [realtime-chat-app/app](/i:/tummoc-devops-assignment/realtime-chat-app/app):

```powershell
npm install
npm run devStart
```

Then open `http://localhost:3000`.

### Run the full container stack

From [realtime-chat-app/app](/i:/tummoc-devops-assignment/realtime-chat-app/app):

```powershell
$env:APP_VERSION="1.0.0"
$env:ACC_ID="<your-aws-account-id>"
$env:ALB_DNS="<your-alb-dns>"
docker compose up -d
```

### Run Terraform

From [terraform](/i:/tummoc-devops-assignment/terraform):

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```
