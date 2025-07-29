module "azure_container_app" {
  source = "./modules/azure_container_app"

  app_name               = var.app_name
  location               = var.location
  environment            = var.environment
  aws_bucket_name        = var.aws_bucket_name
  aws_access_key_id      = var.aws_access_key_id
  aws_secret_access_key  = var.aws_secret_access_key
  api_key                = var.api_key
  dockerhub_username     = var.dockerhub_username
  dockerhub_password     = var.dockerhub_password
}
