# Resource-level diagnostic settings at scale, via DeployIfNotExists policy. A
# diagnostic setting is a child extension resource — there is nothing on the
# parent resource to Deny at create time — so DINE is the only effect that can
# reach in after the fact and create one. That drags in what DINE always needs:
# a managed identity on the assignment, rights for that identity on the
# destination workspace, and a remediation task for resources that already
# exist (DINE only fires on create/update, not retroactively).
#
# One assignment: the built-in "allLogs" category-group initiative, covering
# ~120 resource types generically — one initiative instead of one
# hand-maintained policy per service, and it picks up new categories as Azure
# adds them.
#
# AKS is deliberately not covered here, in either sense: it is not one of the
# ~120 types this initiative supports (its diagnostic categories predate the
# category-group mechanism), and even if it were, it lives in its own repo
# (terraform-root-aks) with its own vended identity — the same reason that repo
# runs its own free Developer bastion instead of governance providing one. It
# sets its own azurerm_monitor_diagnostic_setting directly, with kube-audit off
# (every API server request including reads — the one AKS category that can
# realistically outrun the $150 credit) and kube-audit-admin on (writes only,
# the standard lower-volume substitute). What that repo needs from here is one
# targeted grant, not a policy assignment: see landingzones' log_analytics_contributor
# flag.
#
# The role assignment below is subscription-scoped, unlike landingzones'
# per-resource workload grants. That's not a "stay targeted" violation: Log
# Analytics Contributor's Microsoft.Insights/diagnosticSettings/* action is
# evaluated at the scope of the *target* resource getting the setting, not the
# workspace it points to — and the target is "any resource in the
# subscription", by design, since that's what a subscription-wide DINE
# remediates. Scoping the assignment to the workspace's resource group would
# only let the identity write diagnostic settings on things inside that RG and
# silently do nothing everywhere else.

resource "azurerm_subscription_policy_assignment" "diag_all_logs" {
  name                 = "diag-alllogs-${var.environment}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
  display_name         = "Enable allLogs category group diagnostic settings to Log Analytics"
  description          = "Deploys a diagnostic setting streaming the allLogs category group to the management workspace, for every resource type the initiative supports."
  location             = var.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalytics = { value = data.azurerm_log_analytics_workspace.management.id }
  })
}

resource "azurerm_role_assignment" "diag_all_logs" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_subscription_policy_assignment.diag_all_logs.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_subscription_policy_remediation" "diag_all_logs" {
  name                 = "diag-alllogs-${var.environment}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_assignment_id = azurerm_subscription_policy_assignment.diag_all_logs.id

  depends_on = [azurerm_role_assignment.diag_all_logs]
}
