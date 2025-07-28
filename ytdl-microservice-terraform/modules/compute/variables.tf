variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "availability_domain" {
  description = "The availability domain for the instance"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "security_list_id" {
  description = "ID of the security list"
  type        = string
}

variable "instance_shape" {
  description = "The shape of the instance"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "api_key" {
  description = "API key for the application"
  type        = string
  sensitive   = true
}

variable "aws_bucket_name" {
  description = "AWS S3 bucket name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}