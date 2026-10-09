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
