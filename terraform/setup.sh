#!/bin/bash
    set -euo pipefail

    # Update system
    apt-get update -y
    apt-get upgrade -y

    # Install Docker
    curl -fsSL https://get.docker.com | sh

    # Add ubuntu user to docker group so you don't need sudo
    usermod -aG docker ubuntu

    # Enable Docker to start on boot
    systemctl enable docker
    systemctl start docker

    # Install Docker Compose v2
    curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    echo "Bootstrap complete" >> /var/log/user-data.log