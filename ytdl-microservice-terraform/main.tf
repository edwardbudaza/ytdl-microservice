# Network module
module "network" {
  source = "./modules/network"
  
  compartment_id = var.compartment_id
  project_name   = var.project_name
  environment    = var.environment
}

# Compute module
module "compute" {
  source = "./modules/compute"
  
  compartment_id    = var.compartment_id
  project_name      = var.project_name
  environment       = var.environment
  availability_domain = var.availability_domain
  
  # Network dependencies
  subnet_id         = module.network.public_subnet_id
  security_list_id  = module.network.security_list_id
  
  # Instance config
  instance_shape    = var.instance_shape
  ssh_public_key    = var.ssh_public_key
  
  # Application config
  docker_image      = var.docker_image
  api_key          = var.api_key
  aws_bucket_name  = var.aws_bucket_name
  aws_region       = var.aws_region
  aws_access_key   = var.aws_access_key
  aws_secret_key   = var.aws_secret_key
  domain_name      = var.domain_name
}

# Load balancer module (optional, for production)
module "load_balancer" {
  count  = var.enable_load_balancer ? 1 : 0
  source = "./modules/load_balancer"
  
  compartment_id    = var.compartment_id
  project_name      = var.project_name
  environment       = var.environment
  
  subnet_id         = module.network.public_subnet_id
  instance_id       = module.compute.instance_id
  
  ssl_certificate   = var.ssl_certificate
  ssl_private_key   = var.ssl_private_key
}