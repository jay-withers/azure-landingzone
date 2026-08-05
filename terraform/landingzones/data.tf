data "azurerm_subscription" "current" {}

# The hub, located by name rather than by reading connectivity's state — the naming
# contract. See the repo README for why this is a data source and not
# terraform_remote_state.
module "hub_naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  suffix = [var.hub_workload, var.environment]
}

data "azurerm_virtual_network" "hub" {
  name                = module.hub_naming.virtual_network.name
  resource_group_name = module.hub_naming.resource_group.name
}

# Discovered rather than declared. Listing the zones here would duplicate
# connectivity's private_dns_zones variable and let the two drift; this way the hub
# stays the single source of truth for which zones exist.
data "azurerm_resources" "hub_dns_zones" {
  resource_group_name = module.hub_naming.resource_group.name
  type                = "Microsoft.Network/privateDnsZones"
}
