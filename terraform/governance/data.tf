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
