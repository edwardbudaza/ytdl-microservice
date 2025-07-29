# YTDL Microservice - Oracle Cloud Deployment

A modular Terraform deployment for the YouTube Downloader microservice on Oracle Cloud Infrastructure, configured for domain `ytdl.nibl.ink`.

## 🏗️ Architecture

```
┌─────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Internet/DNS      │────│  Oracle Cloud    │────│   AWS S3        │
│   ytdl.nibl.ink     │    │  Compute Instance│    │   Storage       │
└─────────────────────┘    └──────────────────┘    └─────────────────┘
                                    │
                           ┌─────────────────┐
                           │     Docker      │
                           │  - Nginx Proxy  │
                           │  - YTDL App     │
                           │  - SSL (Let's   │
                           │    Encrypt)     │
                           └─────────────────┘
```

## 📁 Project Structure

```
.
├── main.tf                    # Root Terraform configuration
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs
├── terraform.tfvars.example   # Example configuration
├── Makefile                   # Deployment automation
├── modules/
│   ├── network/              # VCN, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/              # EC2 instance, user data
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── cloud-init.yaml
│   └── load_balancer/        # Optional load balancer
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── scripts/
    ├── deploy.sh             # Deployment script
    └── test_auth.py          # Authentication testing
```

## 🚀 Quick Start

### 1. Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Oracle Cloud account](https://cloud.oracle.com/) with API keys configured
- [Docker](https://docker.com/) for building the application image
- Domain access to configure DNS for `ytdl.nibl.ink`

### 2. Oracle Cloud Setup

1. **Create API Key:**
   ```bash
   mkdir -p ~/.oci
   openssl genrsa -out ~/.oci/oci_api_key.pem 2048
   openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
   ```

2. **Add public key to OCI console:**
   - Go to Profile → API Keys → Add API Key
   - Copy the content of `~/.oci/oci_api_key_public.pem`

3. **Get required OCIDs:**
   - Tenancy OCID: Profile → Tenancy
   - User OCID: Profile → User Settings
   - Compartment OCID: Identity → Compartments

### 3. Initial Setup

```bash
# Clone and setup
git clone https://github.com/edwardbudaza/ytdl-microservice.git
cd ytdl-microservice-terraform

# Initial setup
make setup

# Edit configuration
nano terraform.tfvars
```

### 4. Deploy

```bash
# Build Docker image
make build

# Initialize Terraform
make init

# Plan deployment
make plan

# Deploy infrastructure
make apply

# Or deploy everything at once
make deploy
```

## ⚙️ Configuration

### terraform.tfvars

```hcl
# Oracle Cloud Configuration
tenancy_ocid     = "ocid1.tenancy.oc1..your-tenancy-ocid"
user_ocid        = "ocid1.user.oc1..your-user-ocid"
fingerprint      = "your-key-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"
compartment_id   = "ocid1.compartment.oc1..your-compartment-ocid"
availability_domain = "your-availability-domain"

# SSH Access
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."

# Application Configuration
api_key         = "your-super-secret-api-key"
aws_bucket_name = "your-s3-bucket"
aws_access_key  = "your-aws-access-key"
aws_secret_key  = "your-aws-secret-key"

# Domain
domain_name = "ytdl.nibl.ink"
```

## 🛠️ Management Commands

```bash
# Deployment
make deploy          # Build and deploy everything
make apply          # Apply Terraform changes
make destroy        # Destroy infrastructure

# Monitoring
make status         # Show deployment status  
make health         # Check service health
make logs           # View application logs
make ssh            # SSH into instance

# Testing
make test           # Test authentication
make update         # Update application

# Maintenance  
make clean          # Clean temporary files
make costs          # Show cost information
```

## 🌐 DNS Configuration

After deployment, configure your DNS:

1. **Get the instance IP:**
   ```bash
   terraform output instance_public_ip
   ```

2. **Create DNS A record:**
   - Domain: `ytdl.nibl.ink`
   - Type: `A`
   - Value: `<instance-ip>`
   - TTL: `300`

3. **Wait for propagation** (5-10 minutes)

4. **SSL will be auto-configured** via Let's Encrypt

## 🔒 Security Features

- **Bearer Token Authentication**: All endpoints require API key
- **Rate Limiting**: 100 requests per hour per token
- **SSL/TLS**: Automatic Let's Encrypt certificates
- **Firewall**: OCI Security Lists restrict access
- **Non-root containers**: Docker runs as non-privileged user

## 📊 Usage Examples

### API Testing
```bash
# Health check (no auth required)
curl https://ytdl.nibl.ink/health

# Download video (requires auth)
curl -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"youtube_url": "https://youtube.com/watch?v=dQw4w9WgXcQ"}' \
     https://ytdl.nibl.ink/download
```

### Monitoring
```bash
# Check logs
make logs

# SSH into instance
make ssh

# Check Docker status
ssh ubuntu@<instance-ip> "docker ps"

# Check Nginx status  
ssh ubuntu@<instance-ip> "sudo systemctl status nginx"
```

## 💰 Cost Estimation

**Oracle Cloud Free Tier Eligible:**
- VM.Standard.A1.Flex (1 OCPU, 6GB RAM): **Free**
- Network traffic (first 10TB): **Free**
- Public IP: **Free** (ephemeral) or ~$3/month (reserved)

**Optional costs:**
- Load Balancer: ~$17/month
- Additional storage: ~$0.0255/GB/month

## 🔧 Customization

### Instance Size
```hcl
# In terraform.tfvars
instance_shape = "VM.Standard.A1.Flex"  # Free tier
# or
instance_shape = "VM.Standard2.1"       # More performance
```

### Enable Load Balancer
```hcl
# In terraform.tfvars  
enable_load_balancer = true
```

### Multiple API Keys
```bash
# In cloud-init or after deployment
export API_KEY_1="key-for-client-1"
export API_KEY_2="key-for-client-2"
```

## 🐛 Troubleshooting

### Common Issues

1. **SSL Certificate fails:**
   ```bash
   # SSH into instance and manually run
   sudo certbot --nginx -d ytdl.nibl.ink
   ```

2. **App not starting:**
   ```bash
   # Check logs
   make logs
   # or
   ssh ubuntu@<ip> "docker logs ytdl-microservice"
   ```

3. **DNS not resolving:**
   ```bash
   # Check DNS propagation
   nslookup ytdl.nibl.ink
   dig ytdl.nibl.ink
   ```

4. **Permission issues:**
   ```bash
   # Fix Docker permissions
   ssh ubuntu@<ip> "sudo usermod -aG docker ubuntu"
   ```

### Log Locations
- Application logs: `docker logs ytdl-microservice`
- Nginx logs: `/var/log/nginx/`
- System logs: `journalctl -u ytdl-app`

## 🔄 Updates

### Application Updates
```bash
# Update application code
make update

# Or manually
ssh ubuntu@<ip> "cd /opt/ytdl-app && docker-compose pull && docker-compose up -d"
```

### Infrastructure Updates
```bash
# Modify terraform.tfvars or *.tf files
make plan
make apply
```

## 📝 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

---

**Need help?** Check the logs with `make logs` or open an issue on GitHub.