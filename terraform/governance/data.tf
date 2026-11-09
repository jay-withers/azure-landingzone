data "azurerm_subscription" "current" {}

# The cross-component contract in practice. Rather than hardcode "log-mgmt-dev",
# this drives the same naming module the management component does, with
# management's suffix — so the two cannot drift apart.
module "management_naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  suffix = [var.management_workload, var.environment]
}

# Resolves the management workspace by its deterministic name instead of reading
# management's state. The lookup is identical whether state is local or remote, and
# whether the two components are applied by hand or by separate pipelines — which
# is why this is a data source and not terraform_remote_state.
#
# Consequence: management must be applied first, and this fails with a clear
# "not found" if it has not been.
data "azurerm_log_analytics_workspace" "management" {
  name                = module.management_naming.log_analytics_workspace.name
  resource_group_name = module.management_naming.resource_group.name
}

# Same lookup, for the shared action group management creates when its own
# alert_emails is non-empty. Count-gated on this component's own alert_emails so
# plan doesn't fail with "not found" for someone who hasn't opted into alerting at
# all — see main.alerts.tf.
data "azurerm_monitor_action_group" "management" {
  count = length(var.alert_emails) > 0 ? 1 : 0

  name                = module.management_naming.monitor_action_group.name
  resource_group_name = module.management_naming.resource_group.name
}
