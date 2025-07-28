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

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "instance_id" {
  description = "ID of the compute instance"
  type        = string
}

variable "instance_private_ip" {
  description = "Private IP of the instance"
  type        = string
  default     = ""
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