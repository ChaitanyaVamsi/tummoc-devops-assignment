terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.16.0"
    }
  }

  # Remote state — S3 bucket must exist before running terraform init
  backend "s3" {
    bucket  = "cyberpunk-app-tfstate"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}
