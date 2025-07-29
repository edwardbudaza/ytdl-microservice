variable "app_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_bucket_name" {
  type      = string
  sensitive = true
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "dockerhub_username" {
  type = string
}

variable "dockerhub_password" {
  type      = string
  sensitive = true
}
