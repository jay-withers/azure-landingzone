# The cross-component contract in practice — same technique as
# governance/data.tf's worked example: drive the same naming module with
# management's suffix rather than hardcode a name, then look the resource up.
module "management_naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  suffix = [var.management_workload, var.environment]
}

# Only looked up while the firewall alerts below actually need it. Note this
# means management must have been applied with a non-empty alert_emails before
# the firewall is enabled here — same "not found until the dependency has been
# applied" contract every other cross-component lookup in this repo already has.
data "azurerm_monitor_action_group" "management" {
  count = var.firewall_enabled ? 1 : 0

  name                = module.management_naming.monitor_action_group.name
  resource_group_name = module.management_naming.resource_group.name
}
