# Subscription-wide activity log alerts, routed to management's shared action
# group rather than one created here — see the comment on that resource in
# management/main.alerts.tf for why the action group lives there. Global rather
# than region-specific: activity log alerts are region-agnostic subscription
# resources, conventionally deployed to "global".

resource "azurerm_monitor_activity_log_alert" "service_health" {
  count = length(var.alert_emails) > 0 ? 1 : 0

  name                = "alert-servicehealth-${var.environment}"
  resource_group_name = module.management_naming.resource_group.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Azure incidents, maintenance, security advisories and action-required notices affecting this subscription."

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Incident", "Maintenance", "ActionRequired", "Security"]
    }
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.management[0].id
  }
}

# A broad net, not a precise "policy denial" alert: the activity log's own
# "Policy" category covers changes to policy objects themselves (assignments,
# definitions, compliance state) — not the resource operation a Deny effect
# actually blocks. That blocked operation surfaces here instead, under
# Administrative with an Error level, alongside any other failed administrative
# operation in the subscription. In this repo the common cause is the
# require_env_tag or allowed_locations assignment above blocking a create.
resource "azurerm_monitor_activity_log_alert" "admin_failures" {
  count = length(var.alert_emails) > 0 ? 1 : 0

  name                = "alert-adminfailures-${var.environment}"
  resource_group_name = module.management_naming.resource_group.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Any failed administrative operation at subscription scope — most often a Deny-effect policy blocking a deploy."

  criteria {
    category = "Administrative"
    level    = "Error"
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.management[0].id
  }
}
