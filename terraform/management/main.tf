module "naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  suffix = [var.workload, var.environment]
}

module "resource_group" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.4"

  name     = module.naming.resource_group.name
  location = var.location
  tags     = local.tags
}

# COST. This is the component most likely to quietly eat the monthly credit.
# Ingestion is billed per GB with no ceiling by default, and AKS control-plane and
# container logs will happily produce several GB a day once a cluster is attached.
#
# daily_quota_gb is therefore set, not left null. When the cap is hit ingestion
# stops until the next UTC day and data for the remainder of the day is lost —
# which is the correct trade in a lab and is not in production. Raise it
# deliberately rather than removing it.
resource "azurerm_log_analytics_workspace" "this" {
  name                = module.naming.log_analytics_workspace.name
  location            = var.location
  resource_group_name = module.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.daily_quota_gb
  tags                = local.tags
}
