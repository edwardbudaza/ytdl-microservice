output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = oci_load_balancer_load_balancer.main.id
}

output "load_balancer_ip" {
  description = "Public IP of the load balancer"
  value       = oci_load_balancer_load_balancer.main.ip_address_details[0].ip_address
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${oci_load_balancer_load_balancer.main.ip_address_details[0].ip_address}"
}