data "azurerm_subscription" "current" {}

# The storage account and its containers are created by
# scripts/bootstrap-state.ps1, not Terraform — see that script's header
# comment for why. This component only ever looks them up.
data "azurerm_resource_group" "state" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "state" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.state.name
}

data "azurerm_storage_container" "consumer" {
  for_each = var.state_consumers

  name               = each.key
  storage_account_id = data.azurerm_storage_account.state.id
}

# Re-derive the identity landingzones already vended, the same "components
# find each other by name" pattern used in governance/data.tf — never a
# second identity for a consumer that already has one.
module "landingzones_naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  for_each = local.existing_consumers

  suffix = [each.value.existing_landing_zone, var.environment]
}

data "azurerm_user_assigned_identity" "existing" {
  for_each = local.existing_consumers

  name                = module.landingzones_naming[each.key].user_assigned_identity.name
  resource_group_name = module.landingzones_naming[each.key].resource_group.name
}
