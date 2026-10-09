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

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

variable "state_stores" {
  type = map(object({
    workload = string
    blob_contributors = optional(list(object({
      object_id      = string
      principal_type = string
    })), [])
  }))
  description = <<-DESCRIPTION
    One resource group and storage account per entry. Two keys are required:

    - `platform`     : state for this repo's components. Gets a `tfstate` container;
                       every component's backend.tf points here.
    - `landingzones` : state for workloads deployed into vended landing zones. Holds
                       no containers of its own — the landingzones component vends
                       one per landing zone, with a grant scoped to that container.

    `workload` names the resource group and account, and is hardcoded in backends
    (platform) or looked up by name (landingzones), so changing it means
    re-migrating state. `blob_contributors` get Storage Blob Data Contributor on the
    whole account — admins and the platform pipeline, not workload identities. It is
    needed even with Owner on the subscription: shared keys are disabled, and Owner
    grants no blob data access. principal_type is User for a person,
    ServicePrincipal for a pipeline identity.
  DESCRIPTION

  validation {
    condition     = alltrue([for k in ["platform", "landingzones"] : contains(keys(var.state_stores), k)])
    error_message = "state_stores must contain both a platform and a landingzones entry."
  }

  validation {
    condition = alltrue(flatten([
      for store in values(var.state_stores) : [
        for p in store.blob_contributors : contains(["User", "Group", "ServicePrincipal"], p.principal_type)
      ]
    ]))
    error_message = "principal_type must be one of User, Group, ServicePrincipal."
  }
}
