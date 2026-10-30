# The one pipeline identity with subscription-wide rights, granted here rather
# than by github-repos itself so the repo can never widen, or lose, its own
# access in an apply. Changing it means an apply of this component, by hand.
#
# github-repos creates every other repo's identity, resource groups and role
# assignments, including Role Based Access Control Administrator and a custom
# role at subscription scope. That needs Contributor plus User Access
# Administrator on the subscription: the conditioned RBAC Administrator the app
# repos get can't assign RBAC Administrator, and neither it nor Contributor can
# write role definitions. Effectively Owner, so this is the exception to "keep
# grants targeted", not a model for others.
#
# What keeps it to merged code: the federated credential trusts only the
# `apply` GitHub environment, which github-repos restricts to main. Pull
# request plans run in `dev` as the repo's ordinary state consumer identity,
# with Reader.
#
# principal_type is set on every assignment: without it azurerm looks the
# principal up in Entra, which fails intermittently on a just-created identity.
resource "azurerm_user_assigned_identity" "github_repos_apply" {
  name                = "uai-github-repos-apply-${var.environment}"
  location            = data.azurerm_resource_group.github_repos_state.location
  resource_group_name = data.azurerm_resource_group.github_repos_state.name
  tags = {
    owner     = "jay"
    component = "identity"
  }
}

resource "azurerm_federated_identity_credential" "github_repos_apply" {
  name                = "github-repos-apply"
  parent_id           = azurerm_user_assigned_identity.github_repos_apply.id
  resource_group_name = data.azurerm_resource_group.github_repos_state.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = var.github_repos_apply.subject
}

resource "azurerm_role_assignment" "github_repos_apply" {
  for_each = toset(["Contributor", "User Access Administrator"])

  scope                = data.azurerm_subscription.current.id
  role_definition_name = each.key
  principal_id         = azurerm_user_assigned_identity.github_repos_apply.principal_id
  principal_type       = "ServicePrincipal"
}

# Owner and User Access Administrator grant no blob data access, and the
# account has shared keys off. Its own container only.
resource "azurerm_role_assignment" "github_repos_apply_state" {
  scope                = data.azurerm_storage_container.github_repos_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github_repos_apply.principal_id
  principal_type       = "ServicePrincipal"
}
