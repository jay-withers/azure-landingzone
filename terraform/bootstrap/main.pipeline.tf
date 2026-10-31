# This repo's own CI apply identity: what cd-terraform and the nightly drift
# check log in as for management, governance, connectivity and landingzones.
#
# Created here, in bootstrap, because bootstrap is the one component never
# applied from CI (its state is local, by decision). So no pipeline apply can
# delete, re-federate or lose the identity it runs as. Changing it means
# `make apply C=bootstrap`, by hand.
#
# Contributor plus User Access Administrator on the subscription, effectively
# Owner: governance writes policy and role assignments at subscription scope,
# and landingzones grants RBAC Administrator and custom roles to vended
# identities. Like github-repos' apply identity (governance's
# main.github-repos.tf) this is the exception to "keep grants targeted", not a
# model for others.
#
# What keeps it to merged code: the federated credential trusts only the
# `apply` GitHub environment, which github-repos restricts to main. Pull
# requests get no credentialled plan.
resource "azurerm_user_assigned_identity" "pipeline" {
  name                = "uai-azure-landingzone-apply-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group["platform"].name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "pipeline" {
  name                = "azure-landingzone-apply"
  parent_id           = azurerm_user_assigned_identity.pipeline.id
  resource_group_name = module.resource_group["platform"].name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = var.pipeline_identity.subject
}

resource "azurerm_role_assignment" "pipeline" {
  for_each = toset(["Contributor", "User Access Administrator"])

  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = each.key
  principal_id         = azurerm_user_assigned_identity.pipeline.principal_id
  principal_type       = "ServicePrincipal"
}

# Neither role grants blob data access, and shared keys are off. The platform
# container only: landingzones creates workload containers through ARM, so it
# needs nothing on the landingzones account.
resource "azurerm_role_assignment" "pipeline_state" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.pipeline.principal_id
  principal_type       = "ServicePrincipal"
}
