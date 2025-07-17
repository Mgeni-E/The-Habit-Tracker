# Azure Infrastructure Overview

This document provides an overview of the Azure infrastructure provisioned for the Habit Tracker application.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                Virtual Network (10.0.0.0/16)           │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ │ │
│  │  │   Web Subnet    │    │     Database Subnet         │ │ │
│  │  │  (10.0.1.0/24)  │    │     (10.0.2.0/24)          │ │ │
│  │  │                 │    │                             │ │ │
│  │  │  ┌───────────┐  │    │  ┌─────────────────────────┐ │ │ │
│  │  │  │    VM     │  │    │  │   PostgreSQL Flexible  │ │ │ │
│  │  │  │  Ubuntu   │  │    │  │       Server           │ │ │ │
│  │  │  │  Docker   │  │    │  │                         │ │ │ │
│  │  │  │  Nginx    │  │    │  └─────────────────────────┘ │ │ │
│  │  │  └───────────┘  │    │                             │ │ │
│  │  └─────────────────┘    └─────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────┐    ┌─────────────────────────────────┐   │
│  │   Public IP     │    │    Network Security Groups     │   │
│  │   (Static)      │    │    (Firewall Rules)            │   │
│  └─────────────────┘    └─────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Infrastructure Components

### 1. Resource Group
- **Name**: `habit-tracker-prod-rg`
- **Location**: East US (configurable)
- **Purpose**: Container for all related resources

### 2. Virtual Network
- **Name**: `habit-tracker-prod-vnet`
- **Address Space**: `10.0.0.0/16`
- **Subnets**:
  - **Web Subnet**: `10.0.1.0/24` (for VM)
  - **Database Subnet**: `10.0.2.0/24` (for PostgreSQL)

### 3. Virtual Machine
- **Name**: `habit-tracker-prod-vm`
- **Size**: `Standard_B2s` (2 vCPUs, 4 GB RAM)
- **OS**: Ubuntu 22.04 LTS
- **Storage**: Premium SSD (managed disk)
- **Software**:
  - Docker & Docker Compose
  - Nginx (reverse proxy)
  - Certbot (SSL certificates)
  - UFW Firewall
  - Fail2ban (intrusion prevention)

### 4. PostgreSQL Database
- **Type**: Azure Database for PostgreSQL Flexible Server
- **Name**: `habit-tracker-prod-postgres`
- **Version**: PostgreSQL 15
- **SKU**: `B_Standard_B1ms` (1 vCore, 2 GB RAM)
- **Storage**: 32 GB with auto-grow
- **Backup**: 7-day retention
- **High Availability**: Zone-redundant

### 5. Network Security
- **Network Security Group**: Controls inbound/outbound traffic
- **Allowed Ports**:
  - SSH (22) - for administration
  - HTTP (80) - redirects to HTTPS
  - HTTPS (443) - application access
- **Private DNS Zone**: For database connectivity

### 6. Public IP
- **Type**: Static IP address
- **SKU**: Standard
- **Purpose**: External access to the application

## Security Features

### Network Security
- **Private Database**: Database in isolated subnet
- **Firewall Rules**: Only necessary ports open
- **Network Segmentation**: Separate subnets for different tiers

### Application Security
- **HTTPS Enforcement**: HTTP redirects to HTTPS
- **SSL Certificates**: Let's Encrypt certificates
- **Security Headers**: Configured in Nginx
- **Container Security**: Non-root user, security options

### System Security
- **UFW Firewall**: Host-based firewall
- **Fail2ban**: Intrusion prevention
- **Automatic Updates**: Security patches
- **SSH Key Authentication**: No password authentication

## Monitoring and Logging

### Application Monitoring
- **Docker Health Checks**: Container health monitoring
- **Nginx Logs**: Access and error logs
- **Application Logs**: Centralized logging

### System Monitoring
- **Azure Monitor**: Basic VM metrics
- **Log Rotation**: Automated log management
- **Health Check Script**: Comprehensive system checks

## Backup and Recovery

### Database Backups
- **Automatic Backups**: 7-day retention
- **Point-in-time Recovery**: Available
- **Backup Storage**: Geo-redundant (optional)

### Application Backups
- **Container Images**: Stored in GitHub Container Registry
- **Application Data**: Persistent volumes
- **Configuration**: Infrastructure as Code (Terraform)

## Scalability

### Vertical Scaling
- **VM Scaling**: Change VM size in Terraform
- **Database Scaling**: Upgrade PostgreSQL SKU
- **Storage Scaling**: Auto-grow enabled

### Horizontal Scaling (Future)
- **Load Balancer**: Azure Load Balancer
- **Multiple VMs**: Scale set configuration
- **Database Read Replicas**: For read scaling

## Cost Optimization

### Current Configuration
- **VM**: ~$30-50/month (Standard_B2s)
- **Database**: ~$20-30/month (B_Standard_B1ms)
- **Storage**: ~$5-10/month
- **Network**: ~$5/month
- **Total**: ~$60-95/month

### Cost Reduction Options
- **Development**: Use smaller VM sizes
- **Reserved Instances**: Long-term discounts
- **Auto-shutdown**: For non-production environments

## Deployment Process

### Infrastructure Provisioning
1. **Terraform Init**: Initialize Terraform state
2. **Terraform Plan**: Preview changes
3. **Terraform Apply**: Create/update infrastructure
4. **Output Values**: Get connection details

### Application Deployment
1. **VM Configuration**: Cloud-init script execution
2. **Docker Setup**: Container runtime installation
3. **Application Deployment**: Container deployment
4. **SSL Configuration**: Certificate provisioning
5. **Health Checks**: Verify deployment

## Maintenance

### Regular Tasks
- **Security Updates**: Automatic via unattended-upgrades
- **SSL Renewal**: Automatic via certbot cron job
- **Log Rotation**: Automatic via logrotate
- **Health Monitoring**: Manual or automated checks

### Periodic Tasks
- **Backup Verification**: Test restore procedures
- **Security Audit**: Review configurations
- **Performance Review**: Monitor metrics
- **Cost Review**: Optimize resources

## Disaster Recovery

### Recovery Time Objective (RTO)
- **Infrastructure**: 15-30 minutes (Terraform)
- **Application**: 5-10 minutes (Docker deployment)
- **Database**: Depends on backup size

### Recovery Point Objective (RPO)
- **Database**: Up to 1 hour (backup frequency)
- **Application**: Near zero (stateless containers)

### Recovery Procedures
1. **Infrastructure**: Re-run Terraform
2. **Database**: Restore from backup
3. **Application**: Deploy latest container image
4. **DNS**: Update if IP changes

## Compliance and Governance

### Security Standards
- **Encryption**: Data encrypted at rest and in transit
- **Access Control**: Role-based access
- **Audit Logging**: Activity monitoring
- **Network Security**: Segmentation and firewalls

### Governance
- **Tagging**: Resource organization
- **Naming Convention**: Consistent naming
- **Documentation**: Comprehensive documentation
- **Version Control**: Infrastructure as Code

## Troubleshooting

### Common Issues
1. **VM Access**: SSH key or network issues
2. **Database Connection**: Network or credential issues
3. **SSL Certificates**: DNS or domain issues
4. **Application Errors**: Container or configuration issues

### Diagnostic Tools
- **Azure Portal**: Resource monitoring
- **SSH Access**: Direct VM access
- **Docker Logs**: Container diagnostics
- **Health Check Script**: System validation

## Future Enhancements

### Short Term
- **Monitoring Dashboard**: Azure Monitor setup
- **Automated Backups**: Scripted backup procedures
- **Staging Environment**: Development/testing infrastructure

### Long Term
- **Multi-region Deployment**: Geographic distribution
- **Container Orchestration**: Azure Container Instances/AKS
- **CDN Integration**: Azure CDN for static content
- **Advanced Monitoring**: Application Insights integration

For implementation details, see:
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [GitHub Secrets Configuration](GITHUB_SECRETS.md)
- [Terraform Documentation](../terraform/README.md)
