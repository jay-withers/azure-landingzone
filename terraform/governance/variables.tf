variable "environment" {
  type        = string
  description = "Environment label, used in assignment names."
  default     = "dev"
}

variable "allowed_locations" {
  type        = list(string)
  description = "Regions the allowed-locations policy permits."
  default     = ["westeurope", "northeurope"]
}

variable "location" {
  type        = string
  description = "Azure region for the diagnostic-settings policy assignments' managed identities. Governance is otherwise region-agnostic — this exists only because a SystemAssigned identity requires one."
  default     = "westeurope"
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

variable "alert_emails" {
  type        = list(string)
  description = "Recipients for operational alerts, routed through management's shared action group. Must match management's alert_emails — an empty list here skips these assignments even if management created the action group, and a non-empty list here with an empty one in management fails to find it. Separate from budget_alert_emails — cost and ops recipients may differ."
  default     = []
}

variable "github_repos_apply" {
  type = object({
    subject              = string
    resource_group_name  = optional(string, "rg-tfstate-shared")
    storage_account_name = optional(string, "sttfsharedjw")
    container_name       = optional(string, "github-repos")
  })
  description = <<-DESCRIPTION
    The identity jay-withers/github-repos applies with from CI (main.github-repos.tf).

    `subject` is the OIDC subject of that repo's `apply` GitHub environment, in
    GitHub's immutable form: repo:<owner>@<owner id>/<repo>@<repo id>:environment:apply.
    The readable repo:<owner>/<repo> form never matches its tokens (AADSTS700213).
    The rest locate github-repos' state container in the "shared" account, and the
    resource group the identity lives in beside every other uai-<repo>-deploy-dev.
  DESCRIPTION
}
