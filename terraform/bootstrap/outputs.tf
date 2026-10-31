output "state_stores" {
  description = "Resource group and storage account per state store. The platform values are hardcoded in every component's backend.tf — backend blocks cannot take variables. landingzones looks its store up by name."
  value = {
    for key, sa in azurerm_storage_account.this : key => {
      resource_group_name  = module.resource_group[key].name
      storage_account_name = sa.name
    }
  }
}

output "platform_container_name" {
  description = "Container in the platform store holding one <component>.tfstate blob per component."
  value       = azurerm_storage_container.tfstate.name
}

output "pipeline_identity" {
  description = "This repo's CI apply identity. github-repos looks it up by name and sets AZURE_CLIENT_ID on the `apply` environment."
  value = {
    name                = azurerm_user_assigned_identity.pipeline.name
    resource_group_name = azurerm_user_assigned_identity.pipeline.resource_group_name
    client_id           = azurerm_user_assigned_identity.pipeline.client_id
    principal_id        = azurerm_user_assigned_identity.pipeline.principal_id
  }
}
