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
