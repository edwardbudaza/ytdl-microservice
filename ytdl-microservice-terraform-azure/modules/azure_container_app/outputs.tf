output "container_app_fqdn" {
  value       = "https://${azurerm_container_app.main.latest_revision_fqdn}"
  description = "The FQDN of the Container App"
}

output "dockerhub_image" {
  value       = "${var.dockerhub_username}/${var.app_name}:latest"
  description = "Docker Hub image reference"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource Group"
}
