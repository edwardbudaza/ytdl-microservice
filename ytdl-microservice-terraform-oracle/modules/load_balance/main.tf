# Load Balancer (Optional - for production high availability)
resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-${var.environment}-lb"
  shape          = "flexible"
  
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }

  subnet_ids = [var.subnet_id]

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Backend Set
resource "oci_load_balancer_backend_set" "main" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "${var.project_name}-${var.environment}-backend-set"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    interval_ms       = 30000
    port              = 8000
    url_path          = "/health"
    return_code       = 200
    timeout_in_millis = 10000
    retries           = 3
  }
}

# Backend (Instance)
resource "oci_load_balancer_backend" "main" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  ip_address       = var.instance_private_ip
  port             = 8000
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

# Rule Set for HTTP to HTTPS redirect
resource "oci_load_balancer_rule_set" "redirect_to_https" {
  count            = var.ssl_certificate != "" ? 1 : 0
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "${var.project_name}-${var.environment}-redirect-to-https"

  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "FORCE_LONGEST_PREFIX_MATCH"
    }
    redirect_uri {
      protocol = "HTTPS"
      host     = "{host}"
      port     = 443
      path     = "{path}"
      query    = "{query}"
    }
    response_code = 301
  }
}

# SSL Certificate
resource "oci_load_balancer_certificate" "main" {
  count            = var.ssl_certificate != "" ? 1 : 0
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  certificate_name = "${var.project_name}-${var.environment}-ssl-cert"
  
  certificate_content = var.ssl_certificate
  private_key_content = var.ssl_private_key
}

# HTTP Listener (with optional redirect to HTTPS)
resource "oci_load_balancer_listener" "http" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "${var.project_name}-${var.environment}-http-listener"
  default_backend_set_name = var.ssl_certificate != "" ? null : oci_load_balancer_backend_set.main.name
  port                     = 80
  protocol                 = "HTTP"

  rule_set_names = var.ssl_certificate != "" ? [oci_load_balancer_rule_set.redirect_to_https[0].name] : []
}

# HTTPS Listener (if SSL certificate is provided)
resource "oci_load_balancer_listener" "https" {
  count                    = var.ssl_certificate != "" ? 1 : 0
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "${var.project_name}-${var.environment}-https-listener"
  default_backend_set_name = oci_load_balancer_backend_set.main.name
  port                     = 443
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.main[0].certificate_name
    verify_peer_certificate = false
  }
}