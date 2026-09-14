# New identities for consumers with no existing landingzones identity —
# azure-landingzone's own future CI pipeline today, per the README's "Not
# built yet" note that this repo's own pipeline needs its own identity.
# Placed in the state resource group scripts/bootstrap-state.ps1 created,
# rather than a new one of their own — they exist purely to access this
# account, so they live alongside it.
module "consumer_naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  for_each = local.new_consumers

  suffix = [each.key, "state", var.environment]
}

# A user-assigned managed identity rather than an app registration — see
# landingzones/main.tf for why. Identities, federated credentials and role
# assignments are all free.
resource "azurerm_user_assigned_identity" "new" {
  for_each = local.new_consumers

  name                = module.consumer_naming[each.key].user_assigned_identity.name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.state.name
  tags                = local.tags
}

# Federating to GitHub means the consumer's pipeline holds no secret — it
# exchanges an Actions OIDC token for an Azure token. The subject pins which
# repo and which ref may do so. Same shape as landingzones/main.tf.
resource "azurerm_federated_identity_credential" "new" {
  for_each = local.federated_credentials

  name      = each.key
  parent_id = azurerm_user_assigned_identity.new[each.value.consumer].id

  resource_group_name = data.azurerm_resource_group.state.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = each.value.subject
}
