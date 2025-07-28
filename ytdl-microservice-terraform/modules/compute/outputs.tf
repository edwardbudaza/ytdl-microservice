output "instance_id" {
  description = "ID of the compute instance"
  value       = oci_core_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = oci_core_public_ip.main.ip_address
}

output "instance_private_ip" {
  description = "Private IP of the instance"
  value       = data.oci_core_vnic.main.private_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${oci_core_public_ip.main.ip_address}"
}