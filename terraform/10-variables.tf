variable "project" {
  type = string
  default = "realtime-chatApp"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type=string
  default = "10.0.1.0/24"
}


variable "private_subnet_cidr" {
  type=string
  default = "10.0.2.0/24"
}
variable "bastion_instance" {
  type = string
  default = "t3.micro"
}
variable "app_instance" {
  type = string
  default = "t3.small"
}
variable "key_pair_name" {
  type = string
  default     = "cyberpunk-dev"
}