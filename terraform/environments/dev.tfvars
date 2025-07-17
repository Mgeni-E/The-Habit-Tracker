# =============================================================================
# Development Environment Variables for Habit Tracker
# =============================================================================

# Project Configuration
project_name = "habit-tracker"
environment  = "dev"
location     = "South Africa North"
owner        = "Development Team"

# Virtual Machine Configuration
vm_size        = "Standard_B1s"  # 1 vCPU, 1 GB RAM (cost-effective for dev)
admin_username = "azureuser"

# Database Configuration
db_admin_username = "habitadmin"
db_name          = "habit_tracker_dev"
db_sku_name      = "B_Standard_B1ms"  # Burstable, 1 vCore, 2 GB RAM

# Application Configuration
# Note: These should be set via environment variables or GitHub secrets
# domain_name = "dev.your-domain.com"
# ssl_email = "dev@your-domain.com"
# flask_secret_key = "dev-secret-key"
# github_token = "your-github-token"
# github_username = "your-github-username"
# container_image_name = "your-org/habit-tracker"
