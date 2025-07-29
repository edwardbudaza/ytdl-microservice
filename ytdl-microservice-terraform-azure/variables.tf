variable "app_name" {
  type        = string
  description = "Application name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "aws_bucket_name" {
  type        = string
  sensitive   = true
}

variable "aws_access_key_id" {
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  type        = string
  sensitive   = true
}

variable "api_key" {
  type        = string
  sensitive   = true
}

variable "dockerhub_username" {
  type        = string
  description = "Docker Hub username"
}

variable "dockerhub_password" {
  type        = string
  description = "Docker Hub password"
  sensitive   = true
}
