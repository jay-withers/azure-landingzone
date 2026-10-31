# One Entra app registration per public container app, for Container Apps'
# built-in authentication (EasyAuth). Each app repo configures its own
# authConfig with the client ID output below; it can't create the registration
# itself, because no pipeline identity holds Microsoft Graph rights, and
# granting one Application.ReadWrite would reach every app in the tenant.
# So they live here, applied by hand like the rest of governance.
#
# Two choices keep these safe to leave public:
#
# - **Sign-in is limited to assigned users.** app_role_assignment_required on
#   the service principal means a tenant user with no assignment is refused at
#   Entra, before the app sees a request. Only the operator is assigned.
# - **No client secret exists.** Each registration trusts the app's own
#   user-assigned identity through a federated credential, and the authConfig
#   presents that identity's token in place of a secret (the documented
#   `OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID` setting). Nothing expires and
#   nothing can leak.

data "azuread_client_config" "current" {}

# The identities each app already runs as. Looked up by name, like every other
# cross-component reference here: they belong to the app repos.
data "azurerm_user_assigned_identity" "app_auth" {
  for_each = var.app_auth

  name                = each.value.identity.name
  resource_group_name = each.value.identity.resource_group_name
}

resource "azuread_application" "app_auth" {
  for_each = var.app_auth

  display_name     = "easyauth-${each.key}-${var.environment}"
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]

  web {
    redirect_uris = [for host in each.value.hostnames : "https://${host}/.auth/login/aad/callback"]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }

  required_resource_access {
    resource_app_id = local.graph_app_id

    resource_access {
      id   = local.graph_user_read_id
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "app_auth" {
  for_each = var.app_auth

  client_id                    = azuread_application.app_auth[each.key].client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_app_role_assignment" "app_auth_operator" {
  for_each = var.app_auth

  app_role_id         = local.default_access_role_id
  principal_object_id = var.operator_object_id
  resource_object_id  = azuread_service_principal.app_auth[each.key].object_id
}

resource "azuread_application_federated_identity_credential" "app_auth" {
  #checkov:skip=CKV_AZURE_249:Not a GitHub Actions trust. The issuer is Entra itself and the subject is one managed identity's principal ID, with no wildcard or repo pattern to tighten.
  for_each = var.app_auth

  application_id = azuread_application.app_auth[each.key].id
  display_name   = "easyauth-${each.key}-managed-identity"
  description    = "Lets ${each.value.identity.name} stand in for a client secret in EasyAuth's code exchange."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
  subject        = data.azurerm_user_assigned_identity.app_auth[each.key].principal_id
}
