# AWS Infrastructure with Terraform

This Terraform configuration deploys a highly available web application infrastructure on AWS, based on the provided architecture diagram. The setup includes a VPC with public and private subnets across two availability zones, an Application Load Balancer, web servers, and a bastion host.

## Architecture Overview

```
AWS Cloud (Tokyo Region - ap-northeast-1)
├── VPC (10.0.0.0/16)
│   ├── Availability Zone 1a
│   │   ├── Public Subnet (10.0.1.0/24)
│   │   │   ├── NAT Gateway
│   │   │   └── Bastion Server
│   │   └── Private Subnet (10.0.10.0/24)
│   │       └── WebAP Server 1
│   ├── Availability Zone 1c
│   │   ├── Public Subnet (10.0.2.0/24)
│   │   │   └── NAT Gateway
│   │   └── Private Subnet (10.0.20.0/24)
│   │       └── WebAP Server 2
│   ├── Internet Gateway
│   └── Application Load Balancer (spans both public subnets)
```

## Features

- **High Availability**: Multi-AZ deployment with redundant NAT gateways
- **Security**: Private web servers accessible only through ALB and bastion host
- **Load Balancing**: Application Load Balancer with health checks
- **Monitoring**: Comprehensive health checks and status pages
- **Automation**: Full infrastructure as code with Terraform

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **SSH Key Pair** created in AWS for EC2 access

## Quick Start

### 1. Clone and Configure

```bash
# Navigate to your project directory
cd /path/to/your/terraform/project

# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your specific values
nano terraform.tfvars
```

### 2. Update terraform.tfvars

**Required Changes:**
```hcl
# Set your AWS key pair name (create in AWS Console if needed)
key_pair_name = "your-actual-key-pair-name"

# Restrict SSH access to your IP (find your IP at whatismyip.com)
ssh_cidr_blocks = ["YOUR_PUBLIC_IP/32"]
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Access Your Application

After deployment completes (5-10 minutes), access your web application:

```bash
# Get the ALB URL from outputs
terraform output alb_url

# Example output: http://aws-infrastructure-alb-1234567890.ap-northeast-1.elb.amazonaws.com
```

Visit the URL in your browser to see the load-balanced web application!

## Web Server Features

Each web server includes:

- **Apache HTTP Server** with custom welcome page
- **Health Check Endpoint**: `/health` for ALB monitoring
- **Status Page**: `/status.html` for manual verification
- **Instance Metadata**: Dynamic server information display
- **Unique Content**: Each server shows different content to demonstrate load balancing

## Verification Steps

### 1. Test Load Balancing
```bash
# Open ALB URL in browser and refresh multiple times
# You should see different server names indicating load balancing

# Or use curl to test programmatically
ALB_URL=$(terraform output -raw alb_url)
for i in {1..10}; do
  curl -s $ALB_URL | grep "WebAP-Server"
  sleep 1
done
```

### 2. Check Health Status
```bash
# Test health check endpoint
curl $ALB_URL/health
```

### 3. SSH to Instances (via Bastion)
```bash
# Get bastion IP
BASTION_IP=$(terraform output -raw bastion_public_ip)

# SSH to bastion
ssh -i your-key.pem ec2-user@$BASTION_IP

# From bastion, SSH to web servers
ssh ec2-user@<web-server-private-ip>
```

## Monitoring and Troubleshooting

### Health Check Monitoring

The ALB performs health checks every 30 seconds:
- **Path**: `/health`
- **Expected Response**: HTTP 200
- **Healthy Threshold**: 2 consecutive successes
- **Unhealthy Threshold**: 2 consecutive failures

### Common Issues

1. **Health Checks Failing**
   - Check security group rules allow HTTP from ALB
   - Verify httpd service is running: `systemctl status httpd`
   - Check logs: `tail -f /var/log/user-data.log`

2. **Cannot SSH to Bastion**
   - Verify your IP in `ssh_cidr_blocks`
   - Check key pair name matches your AWS key pair
   - Ensure security group allows SSH on port 22

3. **Load Balancer Not Working**
   - Wait 5-10 minutes for instances to pass health checks
   - Check target group health in AWS Console
   - Verify ALB security group allows HTTP traffic

4. **Web Servers Not Responding**
   - SSH to bastion, then to web servers
   - Check httpd status: `systemctl status httpd`
   - Review user data execution: `cat /var/log/user-data.log`

### Useful Commands

```bash
# Check all outputs
terraform output

# Show current state
terraform show

# Refresh state
terraform refresh

# Destroy infrastructure (when done testing)
terraform destroy
```

## Customization

### Scaling Web Servers

To add more web servers, modify `private_subnet_cidrs` in `terraform.tfvars`:

```hcl
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
```

### Instance Types

For production workloads, consider larger instances:

```hcl
instance_type = "t3.small"          # Web servers
bastion_instance_type = "t3.nano"   # Bastion host
```

### Security Hardening

1. **Restrict ALB Access**:
   ```hcl
   allowed_cidr_blocks = ["203.0.113.0/24"]  # Your office network
   ```

2. **Specific SSH Access**:
   ```hcl
   ssh_cidr_blocks = ["203.0.113.100/32"]    # Your specific IP
   ```

## Cost Optimization

This setup runs on free tier eligible resources:
- **t3.micro instances**: Free tier eligible
- **Application Load Balancer**: ~$16/month
- **NAT Gateways**: ~$45/month per gateway (2 total)
- **Data Transfer**: Variable based on usage

**Cost Reduction Tips:**
- Use single NAT Gateway for development (reduces HA)
- Stop instances when not in use
- Use reserved instances for production

## Security Best Practices

1. **Network Security**:
   - Web servers in private subnets only
   - Security groups with minimal required access
   - SSH access only through bastion host

2. **Access Control**:
   - Restrict SSH source IPs
   - Use IAM roles for EC2 instances
   - Enable CloudTrail for audit logging

3. **Updates**:
   - Regular security patches via user data scripts
   - Consider using AWS Systems Manager for patch management

## Files Overview

- `main.tf`: Provider configuration and data sources
- `variables.tf`: Variable definitions
- `outputs.tf`: Output values after deployment
- `vpc.tf`: VPC, subnets, gateways, and routing
- `security_groups.tf`: Security group rules
- `load_balancer.tf`: ALB, target groups, and listeners
- `ec2.tf`: EC2 instances and target group attachments
- `user-data-web.sh`: Web server initialization script
- `terraform.tfvars.example`: Example variable values

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Verify AWS service limits
4. Consult Terraform and AWS documentation

## Clean Up

To avoid ongoing charges, destroy the infrastructure when done:

```bash
terraform destroy
```

**Note**: This will permanently delete all resources. Ensure you have backups of any important data. 