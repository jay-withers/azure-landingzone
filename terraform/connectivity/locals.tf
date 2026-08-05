locals {
  # environment is not decoration: governance assigns the built-in "Require a tag on
  # resource groups" policy with effect Deny, keyed on `environment`. Drop this key
  # and every resource group creation in the subscription fails.
  tags = merge({
    environment = var.environment
    component   = "connectivity"
    managed-by  = "terraform"
  }, var.tags)

  # Basic mandates a management NIC on its own subnet; Standard and Premium do not.
  firewall_management_required = var.firewall_sku_tier == "Basic"

  # Two /26s out of the first /24, then a /24 for private endpoints. The gateway
  # subnet slot is deliberately unused — no VPN or ExpressRoute here.
  firewall_subnet_prefix            = cidrsubnet(var.vnet_address_space, 4, 0)
  firewall_management_subnet_prefix = cidrsubnet(var.vnet_address_space, 4, 1)
  privatelink_subnet_prefix         = cidrsubnet(var.vnet_address_space, 2, 1)

  # Both firewall subnets exist unconditionally, even though the firewall itself is
  # toggled. Subnets are free, so making them follow firewall_enabled would mutate
  # the VNet on every toggle — slower and more failure-prone than cycling just the
  # billable resources — for no saving. Same reasoning for keeping the management
  # subnet regardless of tier: it costs nothing when unused, and this way switching
  # Basic/Standard does not reshape the VNet.
  #
  # The two firewall subnet names are fixed by Azure — the service locates its
  # subnet by name, not by reference, and rejects anything else. Neither carries an
  # NSG: Azure Firewall manages its own subnet and an NSG there is unsupported.
  subnets = {
    privatelink = {
      name                              = "snet-privatelink"
      address_prefix                    = local.privatelink_subnet_prefix
      private_endpoint_network_policies = "Disabled"
      network_security_group            = { id = module.nsg_privatelink.resource_id }

      # A private endpoint originates nothing.
      default_outbound_access_enabled = false
    }

    firewall = {
      name                            = "AzureFirewallSubnet"
      address_prefix                  = local.firewall_subnet_prefix
      default_outbound_access_enabled = false
    }

    firewall_management = {
      name                            = "AzureFirewallManagementSubnet"
      address_prefix                  = local.firewall_management_subnet_prefix
      default_outbound_access_enabled = false
    }
  }

  # one() over a filtered map yields null rather than failing on an absent key.
  firewall_subnet_id            = one([for k, s in module.vnet.subnets : s.resource_id if k == "firewall"])
  firewall_management_subnet_id = one([for k, s in module.vnet.subnets : s.resource_id if k == "firewall_management"])
  privatelink_subnet_id         = one([for k, s in module.vnet.subnets : s.resource_id if k == "privatelink"])
}
