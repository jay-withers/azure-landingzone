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
  description = "Names this component's resources. Spokes reconstruct hub names from this and environment, so changing it is a breaking change to every consumer."
  default     = "hub"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

variable "vnet_address_space" {
  type        = string
  description = "Hub address space. Subnet prefixes are carved from it, so it must be at least a /22."
  default     = "10.0.0.0/22"

  validation {
    condition     = tonumber(split("/", var.vnet_address_space)[1]) <= 22
    error_message = "vnet_address_space must be /22 or larger to fit the firewall, firewall management and private link subnets."
  }
}

variable "private_dns_zones" {
  type        = list(string)
  description = "Private DNS zones hosted in the hub and linked to it. Spokes link themselves to these by name."

  default = [
    "privatelink.vaultcore.azure.net",
    "privatelink.blob.core.windows.net",
    "privatelink.azurecr.io",
  ]
}

# --- Cost toggles -------------------------------------------------------------
# Everything below is off or minimal by default. See README for what each costs.

variable "firewall_enabled" {
  type        = bool
  description = "Deploy the Azure Firewall. The policy and its rules persist when false, so flipping this back on restores the same configuration."
  default     = false
}

variable "firewall_sku_tier" {
  type        = string
  description = "Basic is roughly a third the hourly cost of Standard but mandates a management subnet and second public IP."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be Basic, Standard or Premium."
  }
}

variable "firewall_allowed_fqdns" {
  type        = list(string)
  description = "Destinations spokes may reach over HTTPS when the firewall is the egress path."
  default     = ["*.ubuntu.com", "*.docker.io", "*.ghcr.io", "*.azurecr.io"]
}

# No bastion here, deliberately. The free Developer SKU cannot reach peered
# VNets, so a hub bastion would have to be Basic at ~$140/month — near enough the
# whole credit. Each spoke runs its own free Developer bastion next to its VM
# instead. See components/workloads/README.md.
