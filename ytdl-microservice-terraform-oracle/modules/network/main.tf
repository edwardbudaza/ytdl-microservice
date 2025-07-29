# VCN (Virtual Cloud Network)
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "${var.project_name}-${var.environment}-vcn"
  dns_label      = "ytdlvcn"

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-${var.environment}-igw"
  enabled        = true

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route Table
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-${var.environment}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security List
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-${var.environment}-public-sl"

  # Allow outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Application port (8000)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8000
      max = 8000
    }
  }

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Public Subnet
resource "oci_core_subnet" "public" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.main.id
  cidr_block          = "10.0.1.0/24"
  display_name        = "${var.project_name}-${var.environment}-public-subnet"
  dns_label           = "public"
  route_table_id      = oci_core_route_table.public.id
  security_list_ids   = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}