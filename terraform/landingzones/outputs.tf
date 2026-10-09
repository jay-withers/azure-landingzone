output "landing_zones" {
  description = "Per landing zone: the resource group its workload deploys into, and the identity its pipeline authenticates as."

  value = {
    for key in keys(var.landing_zones) : key => {
      resource_group_name = module.resource_group[key].name
      resource_group_id   = module.resource_group[key].resource_id
      client_id           = azurerm_user_assigned_identity.lz[key].client_id
      principal_id        = azurerm_user_assigned_identity.lz[key].principal_id
      state_container     = azurerm_storage_container.lz_state[key].name
    }
  }
}

# The three values a workload repo's GitHub Actions workflow needs. Tenant and
# subscription are the same for every landing zone; only the client ID differs.
output "github_secrets" {
  description = "Repository variables to set on each workload repo. None of these are secret — a client ID is useless without a federated credential matching the caller."

  value = {
    for key, lz in var.landing_zones : lz.github_repo => {
      AZURE_CLIENT_ID       = azurerm_user_assigned_identity.lz[key].client_id
      AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
      AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
    }
  }
}

output "hub_dns_zones_granted" {
  description = "Which hub zones each landing zone may link its VNet to."

  value = {
    for key in keys(var.landing_zones) : key => [
      for grant_key, grant in local.dns_zone_grants : reverse(split("--", grant_key))[0]
      if grant.landing_zone == key
    ]
  }
}

# What a workload repo's backend.tf needs. No resource_group_name: with Entra auth
# the backend talks to the blob endpoint directly, and the identity has no rights
# on the state account's resource group to look anything up with anyway.
output "backend_config" {
  description = "Per workload repo, the azurerm backend block to commit. The pipeline must also set ARM_USE_AZUREAD=true — shared keys are disabled on the account."

  value = {
    for key, lz in var.landing_zones : lz.github_repo => {
      storage_account_name = data.azurerm_storage_account.state.name
      container_name       = azurerm_storage_container.lz_state[key].name
      key                  = "terraform.tfstate"
      use_azuread_auth     = true
    }
  }
}
