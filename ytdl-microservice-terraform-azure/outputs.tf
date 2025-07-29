output "container_app_fqdn" {
  value       = module.azure_container_app.container_app_fqdn
  description = "The FQDN of the Container App"
}

output "dockerhub_image" {
  value       = module.azure_container_app.dockerhub_image
  description = "The Docker Hub image"
}

output "resource_group_name" {
  value       = module.azure_container_app.resource_group_name
  description = "Azure Resource Group name"
}
