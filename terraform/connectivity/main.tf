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
