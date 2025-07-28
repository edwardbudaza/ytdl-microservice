# Oracle Cloud Infrastructure Variables
variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the public key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "The availability domain for the instance"
  type        = string
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ytdl-microservice"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "ytdl.nibl.ink"
}

# Compute Configuration
variable "instance_shape" {
  description = "The shape of the instance"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
  default     = "ytdl-microservice:latest"
}

# Application Configuration
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
  default     = "us-east-1"
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

# Optional Features
variable "enable_load_balancer" {
  description = "Enable load balancer"
  type        = bool
  default     = false
}

variable "ssl_certificate" {
  description = "SSL certificate content"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssl_private_key" {
  description = "SSL private key content"
  type        = string
  default     = ""
  sensitive   = true
}