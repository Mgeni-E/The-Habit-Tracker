# Deployment Guide for Habit Tracker on Azure

This guide walks you through deploying the Habit Tracker application to Azure using GitHub Actions and Terraform.

## Prerequisites

1. **Azure Account**: Active Azure subscription
2. **GitHub Repository**: Forked or cloned repository with admin access
3. **Domain Name** (Optional): For custom domain and SSL certificates
4. **Azure CLI**: Installed locally for initial setup

## Quick Start

### 1. Azure Service Principal Setup

Create a service principal for GitHub Actions:

```bash
# Login to Azure
az login

# Set your subscription (replace with your subscription ID)
az account set --subscription "your-subscription-id"

# Create service principal
az ad sp create-for-rbac --name "habit-tracker-github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

Copy the JSON output - you'll need it for GitHub secrets.

### 2. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Value | Required |
|-------------|-------|----------|
| `AZURE_CREDENTIALS` | JSON from service principal creation | ✅ |
| `FLASK_SECRET_KEY` | Generate with: `python -c "import secrets; print(secrets.token_hex(32))"` | ✅ |
| `DB_NAME` | `habit_tracker` | ✅ |
| `DB_USER` | `habitadmin` | ✅ |
| `DOMAIN_NAME` | Your domain (e.g., `app.yourdomain.com`) | ❌ |
| `SSL_EMAIL` | Your email for SSL certificates | ❌ |

### 3. Deploy the Application

1. **Push to main branch** or **create a pull request**:
   ```bash
   git add .
   git commit -m "Deploy to Azure"
   git push origin main
   ```

2. **Monitor the deployment**:
   - Go to GitHub → Actions tab
   - Watch the workflow progress
   - Check for any errors in the logs

3. **Access your application**:
   - The deployment will output the public IP address
   - Access via: `http://YOUR_VM_IP` or `https://YOUR_DOMAIN`

## Detailed Deployment Process

### Phase 1: Infrastructure Provisioning

The GitHub Actions workflow will:

1. **Run tests** to ensure code quality
2. **Build Docker image** and push to GitHub Container Registry
3. **Plan Terraform changes** (on pull requests)
4. **Apply Terraform configuration** (on main branch):
   - Create Azure Resource Group
   - Provision Virtual Network and Subnets
   - Create PostgreSQL Flexible Server
   - Launch Ubuntu VM with Docker and Nginx
   - Configure Network Security Groups
   - Set up Public IP address

### Phase 2: Application Deployment

After infrastructure is ready:

1. **Configure VM** with cloud-init script:
   - Install Docker, Nginx, SSL tools
   - Configure firewall and security
   - Set up log rotation and monitoring

2. **Deploy application**:
   - Pull Docker image from GitHub Container Registry
   - Start application container with production configuration
   - Configure Nginx reverse proxy
   - Set up SSL certificates (if domain configured)

### Phase 3: Health Checks

The deployment includes comprehensive health checks:

- Container health status
- Application responsiveness
- Database connectivity
- SSL certificate validation
- Security configuration

## Configuration Options

### Environment Variables

The application supports these environment variables:

```bash
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=your-secret-key

# Database Configuration
DB_HOST=your-db-host
DB_PORT=5432
DB_NAME=habit_tracker
DB_USER=habitadmin
DB_PASSWORD=your-db-password
```

### Terraform Variables

Customize your infrastructure in `terraform/environments/prod.tfvars`:

```hcl
# Virtual Machine Configuration
vm_size = "Standard_B2s"  # 2 vCPUs, 4 GB RAM

# Database Configuration
db_sku_name = "B_Standard_B1ms"  # Burstable, 1 vCore, 2 GB RAM

# Location
location = "East US"
```

### Custom Domain Setup

If you have a custom domain:

1. **Set GitHub secrets**:
   - `DOMAIN_NAME`: Your domain name
   - `SSL_EMAIL`: Email for Let's Encrypt

2. **Configure DNS**:
   - Point your domain's A record to the VM's public IP
   - Wait for DNS propagation (can take up to 24 hours)

3. **SSL will be automatically configured** during deployment

## Monitoring and Maintenance

### Application Logs

Access application logs:

```bash
# SSH to the VM
ssh -i private_key.pem azureuser@YOUR_VM_IP

# View application logs
sudo docker logs habit-tracker-app

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Health Monitoring

Run the health check script:

```bash
# On the VM
sudo /opt/habit-tracker/scripts/health-check.sh
```

### Database Management

Access the PostgreSQL database:

```bash
# From the VM
psql "postgresql://habitadmin:PASSWORD@DB_HOST:5432/habit_tracker"
```

### SSL Certificate Renewal

SSL certificates auto-renew via cron job. Manual renewal:

```bash
# On the VM
sudo certbot renew
```

## Scaling and Performance

### Vertical Scaling

Increase VM size in `terraform/environments/prod.tfvars`:

```hcl
vm_size = "Standard_B4ms"  # 4 vCPUs, 16 GB RAM
```

Then redeploy:

```bash
git commit -am "Scale up VM"
git push origin main
```

### Database Scaling

Upgrade database SKU:

```hcl
db_sku_name = "GP_Standard_D2s_v3"  # General Purpose, 2 vCores
```

### Application Scaling

Modify Docker container resources in deployment script:

```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '1.0'
```

## Backup and Recovery

### Database Backups

Azure PostgreSQL provides automatic backups:
- 7-day retention period
- Point-in-time recovery
- Geo-redundant backups (if enabled)

### Application Data Backup

Create backup script:

```bash
#!/bin/bash
# Backup application data
sudo docker exec habit-tracker-app tar czf /tmp/app-backup-$(date +%Y%m%d).tar.gz /app/instance
```

### Disaster Recovery

1. **Infrastructure**: Terraform state allows recreation
2. **Database**: Use Azure backup/restore features
3. **Application**: Docker images stored in GitHub Container Registry

## Troubleshooting

### Common Issues

#### Deployment Fails

1. **Check GitHub Actions logs**:
   - Go to Actions tab in GitHub
   - Click on the failed workflow
   - Review error messages

2. **Terraform errors**:
   - Usually related to Azure permissions
   - Check service principal permissions
   - Verify subscription quotas

3. **Application startup issues**:
   - SSH to VM and check Docker logs
   - Verify environment variables
   - Check database connectivity

#### SSL Certificate Issues

1. **Domain not resolving**:
   ```bash
   nslookup YOUR_DOMAIN
   ```

2. **Certificate generation fails**:
   ```bash
   sudo certbot --nginx -d YOUR_DOMAIN --dry-run
   ```

#### Database Connection Issues

1. **Check database status**:
   ```bash
   az postgres flexible-server show --name YOUR_DB_NAME --resource-group YOUR_RG
   ```

2. **Test connectivity**:
   ```bash
   telnet DB_HOST 5432
   ```

### Getting Help

1. **Check logs**: Always start with application and system logs
2. **GitHub Issues**: Report bugs in the repository
3. **Azure Support**: For infrastructure-related issues
4. **Documentation**: Refer to Azure and Terraform documentation

## Security Considerations

### Network Security

- VM only allows SSH, HTTP, and HTTPS traffic
- Database in private subnet
- Network Security Groups configured

### Application Security

- HTTPS enforced (with custom domain)
- Security headers configured in Nginx
- Container runs as non-root user
- Secrets managed via GitHub Secrets

### Monitoring

- Fail2ban for intrusion prevention
- UFW firewall configured
- Automatic security updates enabled

## Cost Optimization

### Development Environment

Use smaller resources for development:

```hcl
vm_size = "Standard_B1s"  # 1 vCPU, 1 GB RAM
db_sku_name = "B_Standard_B1ms"  # Burstable
```

### Production Optimization

- Use Azure Reserved Instances for long-term deployments
- Enable auto-shutdown for development VMs
- Monitor costs with Azure Cost Management

## Next Steps

1. **Set up monitoring**: Consider Azure Monitor or external monitoring
2. **Implement CI/CD improvements**: Add staging environment
3. **Add backup automation**: Automated backup scripts
4. **Performance optimization**: Application performance monitoring
5. **Security hardening**: Additional security measures

For detailed configuration options, see:
- [GitHub Secrets Guide](GITHUB_SECRETS.md)
- [Terraform Documentation](../terraform/README.md)
- [Main README](../README.md)
