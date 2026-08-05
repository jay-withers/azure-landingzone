output "landing_zones" {
  description = "Per landing zone: the resource group its workload deploys into, and the identity its pipeline authenticates as."

  value = {
    for key in keys(var.landing_zones) : key => {
      resource_group_name = module.resource_group[key].name
      resource_group_id   = module.resource_group[key].resource_id
      client_id           = azurerm_user_assigned_identity.lz[key].client_id
      principal_id        = azurerm_user_assigned_identity.lz[key].principal_id
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
