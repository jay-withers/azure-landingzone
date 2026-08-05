# A landing zone here is a resource group, not a subscription. Real ALZ vends a
# subscription per landing zone; with one subscription the resource group is the
# boundary instead. What that keeps: an RBAC boundary, per-landing-zone policy
# (azurerm_resource_group_policy_assignment scopes fine), cost grouping, and
# `az group delete` as a teardown primitive. What it loses: quota isolation, since
# vCPU and public IP limits are subscription-wide.
module "naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  for_each = var.landing_zones

  suffix = [each.key, var.environment]
}

# The landing zone. Note the workload deploying into this does NOT create it — it
# looks the group up and deploys into it, because the group is the thing being
# vended and its identity has no rights to create resource groups.
module "resource_group" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.4"

  for_each = var.landing_zones

  name     = module.naming[each.key].resource_group.name
  location = var.location

  tags = merge(local.tags, {
    landing-zone = each.key
  })
}

# A user-assigned managed identity rather than an app registration: no Entra
# app-registration rights are needed to create one, and it is an ordinary Azure
# resource so azurerm manages it and its federated credentials directly.
#
# Identities, federated credentials, role assignments and custom role definitions
# are all free.
resource "azurerm_user_assigned_identity" "lz" {
  for_each = var.landing_zones

  name                = module.naming[each.key].user_assigned_identity.name
  location            = var.location
  resource_group_name = module.resource_group[each.key].name
  tags                = local.tags
}

# Federating to GitHub means the workload pipeline holds no secret — it exchanges
# an Actions OIDC token for an Azure token. The subject pins which repo and which
# ref may do so.
resource "azurerm_federated_identity_credential" "lz" {
  for_each = local.federated_credentials

  name      = each.key
  parent_id = azurerm_user_assigned_identity.lz[each.value.landing_zone].id

  resource_group_name = module.resource_group[each.value.landing_zone].name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = each.value.subject
}
