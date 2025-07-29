#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars not found!"
    print_status "Please copy terraform.tfvars.example to terraform.tfvars and fill in your values"
    exit 1
fi

# Check if required tools are installed
command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed. Aborting."; exit 1; }
command -v docker >/dev/null 2>&1 || { print_error "Docker is required but not installed. Aborting."; exit 1; }

print_status "Starting deployment of YTDL Microservice..."

# Build Docker image if Dockerfile exists
if [ -f "Dockerfile" ]; then
    print_status "Building Docker image..."
    docker build -t ytdl-microservice:latest .
    print_success "Docker image built successfully"
    
    # Optional: Push to registry
    if [ "$PUSH_TO_REGISTRY" = "true" ] && [ -n "$DOCKER_REGISTRY" ]; then
        print_status "Pushing image to registry..."
        docker tag ytdl-microservice:latest $DOCKER_REGISTRY/ytdl-microservice:latest
        docker push $DOCKER_REGISTRY/ytdl-microservice:latest
        print_success "Image pushed to registry"
    fi
else
    print_warning "No Dockerfile found, skipping image build"
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan deployment
print_status "Planning deployment..."
terraform plan -out=tfplan

# Apply deployment
print_status "Applying deployment..."
if [ "$AUTO_APPROVE" = "true" ]; then
    terraform apply -auto-approve tfplan
else
    terraform apply tfplan
fi

# Clean up plan file
rm -f tfplan

print_success "Deployment completed!"

# Get outputs
print_status "Deployment Information:"
echo "=========================="
terraform output -json | jq -r '
  "Instance IP: " + .instance_public_ip.value,
  "SSH Command: " + .instance_ssh_command.value,
  "Application URL: " + .application_url.value,
  "Domain URL: " + .domain_url.value,
  "Health Check: " + .health_check_url.value
'

print_status "DNS Configuration:"
terraform output -json | jq -r '.dns_configuration.value | 
  "Domain: " + .domain,
  "Type: " + .type,
  "Value: " + .value,
  "TTL: " + (.ttl | tostring)
'

print_status "Next Steps:"
echo "1. Configure your DNS to point ${domain_name} to the instance IP"
echo "2. Wait for DNS propagation (5-10 minutes)"
echo "3. SSL certificate will be automatically configured via Let's Encrypt"
echo "4. Test your API with: curl -H 'Authorization: Bearer YOUR_API_KEY' http://ytdl.nibl.ink/health"

print_success "YTDL Microservice is now deployed! 🚀"