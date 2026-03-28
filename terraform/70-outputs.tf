output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_alb.main.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host."
  value       = aws_instance.bastion.public_ip
}

output "app_private_ip" {
  description = "Private IP address of the application instance."
  value       = aws_instance.app.private_ip
}

output "jenkins_private_ip" {
  description = "Private IP address of the Jenkins instance."
  value       = aws_instance.jenkins.private_ip
}

output "ecr_repository_url" {
  description = "Repository URL for the frontend ECR repository."
  value       = aws_ecr_repository.catalogue.repository_url
}
