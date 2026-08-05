variable "environment" {
  type        = string
  description = "Environment label, used as the trailing element of every resource name."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "uksouth"
}

variable "hub_workload" {
  type        = string
  description = "The connectivity component's workload name. Used to locate the hub VNet and its private DNS zones — see the naming contract in the repo README."
  default     = "hub"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

variable "landing_zones" {
  description = <<-DESCRIPTION
    One entry per landing zone. Each gets a resource group, a user-assigned identity
    federated to a GitHub repository, and role assignments scoped to that resource
    group plus targeted grants on the hub resources it is allowed to touch.

    The map key names the landing zone and drives its resource names.

    - `github_repo`         : "owner/repo" the identity is federated to.
    - `federated_subjects`  : name => OIDC subject. Defaults to a pull_request
                              credential and a refs/heads/main credential, which is
                              what a plan-on-PR / apply-on-merge pipeline needs.
    - `rbac_administrator`  : grant Role Based Access Control Administrator on the
                              landing zone's own resource group. Needed when the
                              workload creates role assignments itself — AKS does,
                              for its subnet and ACR grants. Contributor cannot.
    - `peer_to_hub`         : grant the peering role on the hub VNet. Peering is a
                              write on both sides, so without this the spoke can
                              create only its half and the peering stays Disconnected.
    - `linkable_dns_zones`  : hub zones this landing zone may link its VNet to.
                              Empty means every zone the hub hosts.
  DESCRIPTION

  type = map(object({
    github_repo        = string
    federated_subjects = optional(map(string))
    rbac_administrator = optional(bool, false)
    peer_to_hub        = optional(bool, true)
    linkable_dns_zones = optional(list(string), [])
  }))

  default = {}

  validation {
    condition     = alltrue([for lz in var.landing_zones : can(regex("^[^/]+/[^/]+$", lz.github_repo))])
    error_message = "github_repo must be in owner/repo form."
  }
}
