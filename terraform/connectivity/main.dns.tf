# Hosted in the hub because zone lifecycle outlives the workloads that resolve
# against them: binning a spoke must not take the zone with it. ~$0.50/zone/month
# plus query charges, so keeping them standing is negligible.
#
# The hub link is registration-disabled — nothing in the hub should auto-register
# an A record. Spokes create their own links, so a spoke teardown removes only its
# own link.
module "private_dns_zones" {
  #checkov:skip=CKV_TF_1:Registry-sourced AVM module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.5"

  for_each = toset(var.private_dns_zones)

  domain_name = each.value
  parent_id   = module.resource_group.resource_id
  tags        = local.tags

  virtual_network_links = {
    hub = {
      name                 = "link-${var.workload}"
      vnetid               = module.vnet.resource_id
      registration_enabled = false
    }
  }
}
