# =============================================================================
# Terraform Variables for Habit Tracker Infrastructure
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "habit-tracker"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps Team"
}

# =============================================================================
# Virtual Machine Variables
# =============================================================================

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"
}

# =============================================================================
# Database Variables - Using Docker PostgreSQL
# =============================================================================
# Note: Database variables removed - using Docker PostgreSQL instead

# =============================================================================
# Application Variables
# =============================================================================

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "ssl_email" {
  description = "Email address for Let's Encrypt SSL certificate"
  type        = string
  default     = ""
}

# =============================================================================
# Container Registry Variables
# =============================================================================

variable "container_registry_url" {
  description = "Container registry URL"
  type        = string
  default     = "ghcr.io"
}

variable "container_image_name" {
  description = "Container image name"
  type        = string
  default     = ""
}

# =============================================================================
# Application Configuration Variables
# =============================================================================

variable "flask_secret_key" {
  description = "Flask secret key for session management"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_token" {
  description = "GitHub token for container registry access"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_username" {
  description = "GitHub username for container registry access"
  type        = string
  default     = ""
}
