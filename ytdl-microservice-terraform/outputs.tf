output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = module.compute.instance_public_ip
}

output "instance_ssh_command" {
  description = "SSH command to connect to the instance"
  value       = module.compute.ssh_command
}

output "application_url" {
  description = "URL to access the application"
  value       = var.enable_load_balancer ? "http://${module.load_balancer[0].load_balancer_ip}" : "http://${module.compute.instance_public_ip}:8000"
}

output "domain_url" {
  description = "Domain URL (configure DNS to point to the IP)"
  value       = "http://${var.domain_name}"
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = var.enable_load_balancer ? "http://${module.load_balancer[0].load_balancer_ip}/health" : "http://${module.compute.instance_public_ip}:8000/health"
}

output "dns_configuration" {
  description = "DNS configuration instructions"
  value = {
    domain = var.domain_name
    type   = "A"
    value  = var.enable_load_balancer ? module.load_balancer[0].load_balancer_ip : module.compute.instance_public_ip
    ttl    = 300
  }
}

output "deployment_info" {
  description = "Important deployment information"
  value = {
    instance_ip     = module.compute.instance_public_ip
    ssh_command     = module.compute.ssh_command
    app_logs        = "docker logs ytdl-microservice"
    service_status  = "systemctl status ytdl-app"
    nginx_config    = "/etc/nginx/sites-available/${var.domain_name}"
    ssl_setup       = "certbot --nginx -d ${var.domain_name}"
  }
}