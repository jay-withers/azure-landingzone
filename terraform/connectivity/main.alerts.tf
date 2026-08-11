# Firewall metric alerts, gated on the same toggle as the firewall itself —
# unlike a policy-deployed alert (DeployIfNotExists never cleans up after itself),
# a plain count-gated resource is destroyed along with the firewall on
# firewall_enabled=false, so there is no orphaned-alert cost to worry about here.
# Thresholds and signals are AMBA's own recommendations for Azure Firewall.

resource "azurerm_monitor_metric_alert" "firewall_health" {
  count = var.firewall_enabled ? 1 : 0

  name                = "alert-afw-health-${var.environment}"
  resource_group_name = module.resource_group.name
  scopes              = [azurerm_firewall.this[0].id]
  description         = "Firewall health state has dropped below fully healthy."
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "FirewallHealth"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.management[0].id
  }
}

resource "azurerm_monitor_metric_alert" "firewall_snat_port_utilization" {
  count = var.firewall_enabled ? 1 : 0

  name                = "alert-afw-snat-${var.environment}"
  resource_group_name = module.resource_group.name
  scopes              = [azurerm_firewall.this[0].id]
  description         = "SNAT port utilization is running high enough to risk connection failures."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "SNATPortUtilization"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.management[0].id
  }
}
