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

output "action_group_id" {
  description = "Shared action group ID, or null when alert_emails is empty. Other components look this up by name via the naming module rather than reading this output — see governance/data.tf's worked example for the workspace."
  value       = one(azurerm_monitor_action_group.this[*].id)
}
