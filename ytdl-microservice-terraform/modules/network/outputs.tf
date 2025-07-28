output "vcn_id" {
  description = "ID of the VCN"
  value       = oci_core_vcn.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = oci_core_subnet.public.id
}

output "security_list_id" {
  description = "ID of the security list"
  value       = oci_core_security_list.public.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = oci_core_internet_gateway.main.id
}