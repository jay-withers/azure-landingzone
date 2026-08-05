# Ruleless. Azure's defaults already deny inbound from the internet and allow
# intra-VNet traffic, which is the whole posture a private endpoint subnet wants.
# Note it governs the subnet, not the endpoints in it: private endpoint traffic
# bypasses NSG rules while privateEndpointNetworkPolicies stays disabled.
module "nsg_privatelink" {
  #checkov:skip=CKV_TF_1:Registry-sourced AVM module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  name                = "${module.naming.network_security_group.name}-privatelink"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

module "vnet" {
  #checkov:skip=CKV_TF_1:Registry-sourced AVM module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.20"

  name          = module.naming.virtual_network.name
  location      = var.location
  parent_id     = module.resource_group.resource_id
  address_space = [var.vnet_address_space]
  subnets       = local.subnets
  tags          = local.tags
}

# Spokes associate their subnets to this table to send egress through the hub.
# The default route only exists while the firewall does — see main.firewall.tf.
resource "azurerm_route_table" "spoke_egress" {
  name                = "${module.naming.route_table.name}-spoke"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}
