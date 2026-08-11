# The shared notification channel for every alert this repo creates — not just
# management's own. It lives here rather than in governance because apply order
# is management -> governance -> connectivity, and management is first precisely
# because it has no dependencies (see CLAUDE.md). governance and connectivity look
# this up by name via the naming module, the same way governance already looks up
# the workspace in data.tf — no new cross-component mechanism.
resource "azurerm_monitor_action_group" "this" {
  count = length(var.alert_emails) > 0 ? 1 : 0

  name                = module.naming.monitor_action_group.name
  resource_group_name = module.resource_group.name
  short_name          = "alerts"
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = { for idx, email in var.alert_emails : idx => email }

    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

# The daily cap being hit is not exposed as a resource metric — Azure records it as
# an Operation event in the workspace's own _LogOperation table (Category
# "Ingestion", Detail containing "Data collection"), so a log query alert is the
# only way to catch it. This is the single highest-value alert in the set: see the
# COST note on the workspace resource in main.tf for why.
# https://learn.microsoft.com/azure/azure-monitor/logs/daily-cap
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "law_daily_cap" {
  count = length(var.alert_emails) > 0 ? 1 : 0

  name                = "alert-law-dailycap-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags

  scopes               = [azurerm_log_analytics_workspace.this.id]
  severity             = 1
  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"

  criteria {
    query                   = <<-QUERY
      _LogOperation
      | where Category == "Ingestion"
      | where Detail has "Data collection"
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this[0].id]
  }
}
