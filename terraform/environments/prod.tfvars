# =============================================================================
# Production Environment Variables for Habit Tracker
# =============================================================================

# Project Configuration
project_name = "habit-tracker"
environment  = "prod"
location     = "South Africa North"
owner        = "DevOps Team"

# Virtual Machine Configuration
vm_size        = "Standard_B2s"  # 2 vCPUs, 4 GB RAM
admin_username = "azureuser"

# Database Configuration
db_admin_username = "habitadmin"
db_name          = "habit_tracker"
db_sku_name      = "B_Standard_B1ms"  # Burstable, 1 vCore, 2 GB RAM

# Application Configuration
# Note: These should be set via environment variables or GitHub secrets
# domain_name = "your-domain.com"
# ssl_email = "admin@your-domain.com"
# flask_secret_key = "your-production-secret-key"
# github_token = "your-github-token"
# github_username = "your-github-username"
# container_image_name = "your-org/habit-tracker"
