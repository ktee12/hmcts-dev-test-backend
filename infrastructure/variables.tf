variable "service_name" {
  description = "Base name used for the service resources."
  type        = string
  default     = "hmcts-dev-test"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region in which resources are provisioned."
  type        = string
  default     = "uksouth"
}

variable "container_image" {
  description = "Fully qualified container image including an immutable tag."
  type        = string
  default     = "ghcr.io/example/hmcts-dev-test-backend:latest"
}

variable "database_name" {
  description = "Name of the PostgreSQL application database."
  type        = string
  default     = "devtest"
}

variable "database_admin_username" {
  description = "Administrator username for PostgreSQL Flexible Server."
  type        = string
  default     = "devtestadmin"
  sensitive   = true
}

variable "database_sku_name" {
  description = "SKU used by PostgreSQL Flexible Server."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "database_storage_mb" {
  description = "PostgreSQL storage allocation in megabytes."
  type        = number
  default     = 32768
}

variable "container_cpu" {
  description = "CPU allocated to the Container App"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory allocated to the Container App."
  type        = string
  default     = "1Gi"
}

variable "tags" {
  description = "Tags applied to supported Azure resources."
  type        = map(string)

  default = {
    managed-by = "terraform"
    service    = "hmcts-dev-test"
  }
}