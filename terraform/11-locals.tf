locals {
  common_name = "${var.project}-${var.environment}"
  common_tags = {
    Project = var.project
    Environment = var.environment
    Terraform = true
  }
}