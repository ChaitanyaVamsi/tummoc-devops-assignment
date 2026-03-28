#!/bin/bash
set -e

# NOTE:
# user_data runs very early in EC2 boot (cloud-init phase).
# Package installation (apt-get) can fail due to:
# - network not ready
# - DNS issues
# - apt/dpkg lock contention
# To avoid flaky Jenkins installs, we:
#   - wait for system readiness (sleep)
#   - retry critical commands

# Wait for system + network to stabilize
#sleep 60

# Fix dpkg lock issues (very common)
 apt-get update -y
 apt-get install -y fontconfig openjdk-21-jre wget

# Ensure keyrings directory exists
mkdir -p /etc/apt/keyrings

# Add Jenkins key
 wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Add Jenkins repo
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

# Update again with retry
apt-get update -y

# Install Jenkins
apt-get install -y jenkins

# Enable + start Jenkins
systemctl enable jenkins
systemctl start jenkins