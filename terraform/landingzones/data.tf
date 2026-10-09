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

# Located the same way as governance's own lookup of this workspace — see the
# naming contract in the repo README. Only read here to scope the
# log_analytics_contributor grant; nothing in this component writes to it.
module "management_naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  suffix = [var.management_workload, var.environment]
}

data "azurerm_log_analytics_workspace" "management" {
  name                = module.management_naming.log_analytics_workspace.name
  resource_group_name = module.management_naming.resource_group.name
}

# The landing zone state store bootstrap creates, located by name like the hub.
# bootstrap seeds the naming module's unique suffix with the subscription ID
# because storage account names are global; doing the same here reproduces the
# exact name. Fails with "not found" until bootstrap has been applied.
module "state_naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  suffix      = [var.state_workload, var.environment]
  unique-seed = data.azurerm_subscription.current.subscription_id
}

data "azurerm_storage_account" "state" {
  name                = module.state_naming.storage_account.name_unique
  resource_group_name = module.state_naming.resource_group.name
}
