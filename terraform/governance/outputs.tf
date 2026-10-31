output "subscription_id" {
  description = "Subscription these assignments apply to."
  value       = data.azurerm_subscription.current.subscription_id
}

output "budget_name" {
  description = "Consumption budget name, or null when no alert emails are configured."
  value       = one(azurerm_consumption_budget_subscription.this[*].name)
}

output "github_repos_apply_client_id" {
  description = "Client ID of github-repos' apply identity. github-repos looks the identity up by name and sets this on its apply environment itself."
  value       = azurerm_user_assigned_identity.github_repos_apply.client_id
}

output "app_auth_client_ids" {
  description = "EasyAuth client ID per app. Not secret: each app repo sets it as auth_client_id in environments/dev.tfvars."
  value       = { for key, app in azuread_application.app_auth : key => app.client_id }
}
