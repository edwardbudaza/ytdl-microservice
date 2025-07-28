# Get the latest Ubuntu image
data "oci_core_images" "ubuntu" {
  compartment_id   = var.compartment_id
  operating_system = "Canonical Ubuntu"
  shape            = var.instance_shape

  filter {
    name   = "display_name"
    values = [".*Ubuntu-22.04.*"]
    regex  = true
  }
}

# Cloud-init script for instance setup
locals {
  cloud_init = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    api_key         = var.api_key
    aws_bucket_name = var.aws_bucket_name
    aws_region      = var.aws_region
    aws_access_key  = var.aws_access_key
    aws_secret_key  = var.aws_secret_key
    docker_image    = var.docker_image
    domain_name     = var.domain_name
  }))
}

# Compute Instance
resource "oci_core_instance" "main" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = "${var.project_name}-${var.environment}-instance"
  shape               = var.instance_shape

  # Flexible shape configuration (for A1.Flex instances)
  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  # Instance image
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  # Network configuration
  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.project_name}-${var.environment}-vnic"
    assign_public_ip = true
    hostname_label   = "ytdl"
  }

  # SSH key
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data          = local.cloud_init
  }

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  # Preserve boot volume on instance termination
  preserve_boot_volume = false
}

# Reserved Public IP (optional, for consistent IP)
resource "oci_core_public_ip" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-${var.environment}-public-ip"
  lifetime       = "RESERVED"

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach reserved IP to instance
resource "oci_core_public_ip_attachment" "main" {
  public_ip_id = oci_core_public_ip.main.id
  private_ip_id = data.oci_core_vnic.main.private_ip_id
}

# Get VNIC details
data "oci_core_vnic_attachments" "main" {
  compartment_id      = var.compartment_id
  instance_id         = oci_core_instance.main.id
}

data "oci_core_vnic" "main" {
  vnic_id = data.oci_core_vnic_attachments.main.vnic_attachments[0].vnic_id
}