output "storage_account_name" {
  description = "The platform state storage account's name."
  value       = data.azurerm_storage_account.state.name
}

output "resource_group_name" {
  description = "The platform state storage account's resource group."
  value       = data.azurerm_resource_group.state.name
}

# The values a consumer's own backend.tf needs. None of these are secret.
output "backend_config" {
  description = "Per consumer: the azurerm backend block values for its own backend.tf."

  value = {
    for key in keys(var.state_consumers) : key => {
      resource_group_name  = data.azurerm_resource_group.state.name
      storage_account_name = data.azurerm_storage_account.state.name
      container_name       = key
      use_azuread_auth     = true
    }
  }
}

# The three values a new-identity consumer's GitHub Actions workflow needs —
# mirrors landingzones' github_secrets output. existing_landing_zone
# consumers already have this from landingzones' own output; it isn't
# repeated here.
output "github_secrets" {
  description = "Repository variables to set on each new-identity consumer's repo."

  value = {
    for key, c in local.new_consumers : c.github_repo => {
      AZURE_CLIENT_ID       = azurerm_user_assigned_identity.new[key].client_id
      AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
      AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
    }
  }
}
