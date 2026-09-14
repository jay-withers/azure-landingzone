variable "environment" {
  type        = string
  description = "Environment label. Used only to locate landingzones-vended identities via the naming contract — this component creates nothing suffixed by it directly."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region for identities created by this component."
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "The platform state resource group. Created by scripts/bootstrap-state.ps1, not Terraform — must match the -ResourceGroupName it was run with. Changing this means re-running the script with the new name first."
  default     = "rg-tfplatform-dev"
}

variable "storage_account_name" {
  type        = string
  description = "The platform state storage account. Created by scripts/bootstrap-state.ps1, not Terraform — must match the -StorageAccountName it was run with. Changing this means re-running the script with the new name first."
  default     = "sttfplatformdev"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

variable "state_consumers" {
  description = <<-DESCRIPTION
    One entry per consumer of the platform state storage account. The map key
    names the consumer and is also its container name — containers are
    created by scripts/bootstrap-state.ps1, so add the key to that script's
    -Containers list (and re-run it) before adding it here, or the container
    data source lookup fails.

    Exactly one of the two identity shapes must be set:
    - `existing_landing_zone` : reuse the identity landingzones already
      vended for this key in its own var.landing_zones. No new identity is
      created — this only grants the existing one access to its container.
    - `github_repo`           : no existing identity for this consumer — create
      one here and federate it to this GitHub repo. federated_subjects
      defaults the same way landingzones does (pull_request + refs/heads/main).
  DESCRIPTION

  type = map(object({
    existing_landing_zone = optional(string)
    github_repo           = optional(string)
    federated_subjects    = optional(map(string))
  }))

  default = {}

  validation {
    condition = alltrue([
      for c in var.state_consumers :
      (c.existing_landing_zone != null) != (c.github_repo != null)
    ])
    error_message = "Each state_consumers entry must set exactly one of existing_landing_zone or github_repo."
  }
}
