output "resource_group_name" {
  description = "Resource group holding the management resources."
  value       = module.resource_group.name
}

output "log_analytics_workspace_name" {
  description = "Workspace name. Other components look the workspace up by this rather than reading it out of state."
  value       = azurerm_log_analytics_workspace.this.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the workspace."
  value       = azurerm_log_analytics_workspace.this.id
}
