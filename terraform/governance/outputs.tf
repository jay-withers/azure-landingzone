output "subscription_id" {
  description = "Subscription these assignments apply to."
  value       = data.azurerm_subscription.current.subscription_id
}

output "budget_name" {
  description = "Consumption budget name, or null when no alert emails are configured."
  value       = one(azurerm_consumption_budget_subscription.this[*].name)
}
