# Subscription-scoped, not management-group-scoped. With a single subscription a
# management group hierarchy adds a layer of indirection over exactly one child and
# buys nothing, so it is deliberately absent.
#
# Built-in policy definitions and compliance evaluation are free.

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations-${var.environment}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  display_name         = "Allowed locations"
  description          = "Restricts resource deployment to approved regions."

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_subscription_policy_assignment" "require_env_tag" {
  name                 = "require-env-tag-${var.environment}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  display_name         = "Require environment tag on resource groups"
  description          = "Enforces an 'environment' tag on all resource groups."

  parameters = jsonencode({
    tagName = { value = "environment" }
  })
}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activity-${var.environment}"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.management.id

  # Kept narrow on purpose: every category here is billed per GB into the
  # workspace, and the workspace has a daily cap that activity logs would
  # otherwise compete for with the things you actually want.
  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Security"
  }
}

# The backstop for a fixed monthly credit: alerts at 50%, 80% and 100% of forecast
# so overspend surfaces early rather than as resources refusing to start. A budget
# only notifies — it does not cap anything.
resource "azurerm_consumption_budget_subscription" "this" {
  count = length(var.budget_alert_emails) > 0 ? 1 : 0

  name            = "budget-${var.environment}"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = [50, 80, 100]

    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_emails = var.budget_alert_emails
    }
  }
}
