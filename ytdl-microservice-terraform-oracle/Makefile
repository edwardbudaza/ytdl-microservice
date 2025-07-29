# YTDL Microservice - Terraform Deployment

.PHONY: help init plan apply destroy clean build test ssh logs

# Default target
help:
	@echo "YTDL Microservice - Available Commands:"
	@echo "========================================"
	@echo "setup     - Initial setup (copy config files)"
	@echo "build     - Build Docker image"
	@echo "init      - Initialize Terraform"
	@echo "plan      - Plan Terraform deployment"
	@echo "apply     - Apply Terraform deployment"
	@echo "destroy   - Destroy infrastructure"
	@echo "ssh       - SSH into the instance"
	@echo "logs      - View application logs"
	@echo "test      - Test the deployed application"
	@echo "clean     - Clean up temporary files"
	@echo "status    - Show deployment status"

# Initial setup
setup:
	@echo "Setting up YTDL Microservice deployment..."
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "✅ Created terraform.tfvars - Please edit with your values"; \
	else \
		echo "⚠️  terraform.tfvars already exists"; \
	fi
	@mkdir -p logs
	@chmod +x scripts/*.sh
	@echo "✅ Setup completed!"

# Build Docker image
build:
	@echo "Building Docker image..."
	@docker build -t ytdl-microservice:latest .
	@echo "✅ Docker image built successfully"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	@terraform init
	@echo "✅ Terraform initialized"

# Plan deployment
plan:
	@echo "Planning Terraform deployment..."
	@terraform plan -out=tfplan
	@echo "✅ Plan created - review above and run 'make apply' to deploy"

# Apply deployment
apply:
	@echo "Applying Terraform deployment..."
	@terraform apply tfplan
	@rm -f tfplan
	@echo "✅ Deployment completed!"
	@$(MAKE) status

# Deploy with auto-approval (use with caution)
deploy:
	@echo "Building and deploying..."
	@$(MAKE) build
	@$(MAKE) init
	@terraform plan -out=tfplan
	@terraform apply -auto-approve tfplan
	@rm -f tfplan
	@$(MAKE) status

# Destroy infrastructure
destroy:
	@echo "⚠️  This will destroy all infrastructure!"
	@echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
	@sleep 10
	@terraform destroy
	@echo "✅ Infrastructure destroyed"

# SSH into instance
ssh:
	@echo "Connecting to instance..."
	@$(shell terraform output -raw instance_ssh_command)

# View application logs
logs:
	@echo "Fetching application logs..."
	@ssh -o StrictHostKeyChecking=no ubuntu@$(shell terraform output -raw instance_public_ip) \
		"docker logs ytdl-microservice --tail 100 -f"

# Test the deployed application
test:
	@echo "Testing deployed application..."
	@python3 scripts/test_auth.py \
		--url $(shell terraform output -raw application_url) \
		--api-key $(shell grep "api_key" terraform.tfvars | cut -d'"' -f2)

# Show deployment status
status:
	@echo "Deployment Status:"
	@echo "=================="
	@terraform output -json | jq -r '
		"Instance IP: " + .instance_public_ip.value,
		"SSH Command: " + .instance_ssh_command.value,
		"Application URL: " + .application_url.value,
		"Domain URL: " + .domain_url.value,
		"Health Check: " + .health_check_url.value
	'
	@echo ""
	@echo "DNS Configuration:"
	@terraform output -json | jq -r '.dns_configuration.value | 
		"Domain: " + .domain,
		"Type: " + .type, 
		"Value: " + .value,
		"TTL: " + (.ttl | tostring)
	'

# Clean up temporary files
clean:
	@echo "Cleaning up temporary files..."
	@rm -f tfplan
	@rm -rf .terraform/
	@rm -f terraform.tfstate.backup
	@echo "✅ Cleanup completed"

# Check health of deployed service
health:
	@echo "Checking service health..."
	@curl -s $(shell terraform output -raw health_check_url) | jq '.' || echo "❌ Service not responding"

# Update application (rebuild and redeploy)
update:
	@echo "Updating application..."
	@$(MAKE) build
	@ssh -o StrictHostKeyChecking=no ubuntu@$(shell terraform output -raw instance_public_ip) \
		"cd /opt/ytdl-app && docker-compose pull && docker-compose up -d"
	@echo "✅ Application updated"

# Show resource costs (if using OCI cost management)
costs:
	@echo "Resource costs information:"
	@echo "VM.Standard.A1.Flex (1 OCPU, 6GB RAM): Free tier eligible"
	@echo "Network traffic: First 10TB free per month"
	@echo "Load balancer: ~$17/month (if enabled)"
	@echo "Public IP: ~$3/month for reserved IP"