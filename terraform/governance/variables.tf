variable "environment" {
  type        = string
  description = "Environment label, used in assignment names."
  default     = "dev"
}

variable "allowed_locations" {
  type        = list(string)
  description = "Regions the allowed-locations policy permits."
  default     = ["uksouth", "ukwest"]
}

variable "management_workload" {
  type        = string
  description = "The management component's workload name. Used to locate its Log Analytics workspace — see the naming contract in the repo README."
  default     = "mgmt"
}

variable "monthly_budget" {
  type        = number
  description = "Monthly spend the budget alerts against, in the subscription's billing currency. Set to the credit allowance so alerts fire before it runs out."
  default     = 150
}

variable "budget_start_date" {
  type        = string
  description = "First of a month, RFC3339. Azure rejects a start date more than three months in the past."
  default     = "2026-09-01T00:00:00Z"
}

variable "budget_alert_emails" {
  type        = list(string)
  description = "Recipients for budget threshold alerts. No alert is created when empty."
}
