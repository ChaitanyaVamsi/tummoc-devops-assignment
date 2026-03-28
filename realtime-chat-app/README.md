# Realtime Chat App

This project contains a simple Socket.IO-based realtime chat application with containerized deployment, monitoring, and a Jenkins CI/CD pipeline.

The runnable application and deployment files live in `realtime-chat-app/app`.

## What Is Included

- Realtime chat UI served by a Node.js and Express app
- WebSocket messaging with Socket.IO
- Docker image build via `Dockerfile`
- Multi-container deployment via `docker-compose.yml`
- Reverse proxy routing with Nginx
- Metrics collection with Prometheus
- Dashboard layer with Grafana
- Jenkins pipeline for build, push, and deployment

## Project Structure

```text
realtime-chat-app/
|-- README.md
`-- app/
    |-- Dockerfile
    |-- Jenkinsfile
    |-- docker-compose.yml
    |-- nginx.conf
    |-- prometheus.yml
    |-- package.json
    |-- server.js
    |-- index.html
    |-- script.js
    `-- style.css
```

## Application Overview

The chat app is a lightweight frontend and backend bundled into a single Node.js service:

- `server.js` serves the static frontend files
- Socket.IO handles realtime communication between connected users
- The application exposes Prometheus metrics at `/metrics`
- The app listens on port `3000`

## Container Architecture

`docker-compose.yml` defines four services on a shared `monitoring` network:

- `frontend`: the chat application container, served on port `3000` internally
- `nginx`: reverse proxy exposed on port `80`
- `prometheus`: scrapes application metrics
- `grafana`: visualizes metrics dashboards

Named Docker volumes are used for persistent monitoring data:

- `prometheus-data`
- `grafana-data`

## Reverse Proxy Routes

Nginx is configured to expose all services from a single entrypoint:

- `/` -> chat application
- `/prometheus/` -> Prometheus UI
- `/grafana/` -> Grafana UI

This makes the stack easy to expose behind a single load balancer or public DNS name.

## Monitoring Setup

Monitoring is built into the application and compose stack.

### Application Metrics

The Node.js app uses `prom-client` to expose metrics at:

```text
/metrics
```

### Prometheus

Prometheus is configured in `prometheus.yml` to scrape:

```text
frontend:3000
```

with:

- `scrape_interval: 5s`
- `metrics_path: /metrics`

### Grafana

Grafana runs behind Nginx and is configured to work from the `/grafana/` subpath using:

- `GF_SERVER_ROOT_URL`
- `GF_SERVER_SERVE_FROM_SUB_PATH=true`
- `GF_SERVER_DOMAIN`

## Docker Build

The `Dockerfile` uses a two-stage build:

1. Build stage based on `node:20.19.5-alpine3.22`
2. Runtime stage based on the same image, running as a non-root user

The container starts with:

```bash
npm run devStart
```

and exposes:

```text
3000
```

## Docker Compose Deployment

The compose setup expects these environment variables:

- `APP_VERSION`
- `ACC_ID`
- `ALB_DNS`

They are used for:

- pulling the frontend image from AWS ECR
- generating Prometheus external URLs
- generating Grafana root URLs

Run the stack from `realtime-chat-app/app`:

```powershell
$env:APP_VERSION="1.0.0"
$env:ACC_ID="471112667143"
$env:ALB_DNS="your-alb-dns-name"
docker compose up -d
```

To stop it:

```powershell
docker compose down
```

## Jenkins Pipeline

The `Jenkinsfile` automates the full delivery flow.

### Pipeline Stages

1. Read the application version from `package.json`
2. Install Node dependencies with `npm install`
3. Run lint checks
4. Run tests
5. Build a Docker image
6. Tag and push the image to AWS ECR
7. Deploy the latest version with Docker Compose

### Jenkins Environment Values

The pipeline currently defines:

- `ACC_ID = 471112667143`
- `PROJECT = realtime-chat-app`
- `COMPONENT = frontend`
- `ALB_DNS = realtime-chat-app-dev-alb-18324781.us-east-1.elb.amazonaws.com`

### Deployment Behavior

During deployment, Jenkins exports:

- `APP_VERSION`
- `ACC_ID`
- `ALB_DNS`

Then it runs:

```bash
docker compose pull
docker compose up -d
docker compose ps
```

This means the deployed frontend image version always matches the version defined in `package.json`.

## Prerequisites

To run or deploy this project, you should have:

- Docker and Docker Compose
- Node.js and npm
- Jenkins
- AWS CLI
- Access to an AWS ECR repository

## Local Development

From `realtime-chat-app/app`:

```powershell
npm install
npm run devStart
```

Then open:

```text
http://localhost:3000
```

## Access URLs

When deployed behind Nginx or an ALB:

- Chat app: `http://<host>/`
- Prometheus: `http://<host>/prometheus/`
- Grafana: `http://<host>/grafana/`

## Notes

- The pipeline uses placeholder lint and test commands from `package.json`
- The frontend image is pulled from AWS ECR, not built by Docker Compose
- `ALB_DNS` is important for correct Prometheus and Grafana subpath URLs
- The monitoring stack is designed to sit behind a single public endpoint
