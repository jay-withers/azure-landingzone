variable "environment" {
  type        = string
  description = "Environment label, used as the trailing element of every resource name."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "westeurope"
}

variable "workload" {
  type        = string
  description = "Names this component's resources. Other components find the workspace from this and environment, so changing it is a breaking change to every consumer."
  default     = "mgmt"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "Workspace retention. 30 is the floor and is included in the per-GB price; beyond it you pay for retention separately."
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  type        = number
  description = "Hard ingestion cap per day. Ingestion is billed per GB and is the least predictable cost in the subscription, so this is set rather than left unlimited — see the note in main.tf."
  default     = 1
}
