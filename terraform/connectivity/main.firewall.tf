# Native azurerm rather than AVM here: the policy is deliberately decoupled from
# the firewall's lifecycle and the count-toggle below reads more plainly on the
# bare resources than through a module.
#
# COST. The firewall is the most expensive thing in this repo by an order of
# magnitude — Basic ~$0.40/hr, Standard ~$1.25/hr, before data processing. On a
# $150/month credit it cannot stand permanently: Basic alone would consume the
# whole allowance in about 16 days. Treat it as a per-session resource. A
# three-hour session on Standard is a few dollars.
#
#   make apply C=connectivity TFARGS='-var firewall_enabled=true'
#   make apply C=connectivity          # back off, policy retained
#
# The policy and its rule collections are NOT counted. Azure bills firewall
# policies only when they are shared across multiple firewalls, so a single-firewall
# policy is free to leave standing — which is the point: rules survive the
# firewall being destroyed, and flipping it back on restores this exact config
# without a rewrite.
resource "azurerm_firewall_policy" "this" {
  # IDPS is a Premium-only feature, so this check cannot be satisfied at Basic or
  # Standard. Premium is ~$1.75/hr — roughly $1,280/month against a $150 credit —
  # so the tier is the constraint, not the policy setting. Revisit if the tier
  # ever moves to Premium.
  #checkov:skip=CKV_AZURE_220:Requires firewall_sku_tier = Premium, which the monthly credit cannot fund.
  name                = "afwp-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  sku                 = var.firewall_sku_tier
  tags                = local.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "egress" {
  name               = "egress"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 500

  application_rule_collection {
    name     = "allowed-fqdns"
    priority = 500
    action   = "Allow"

    rule {
      name              = "https"
      source_addresses  = [var.vnet_address_space]
      destination_fqdns = var.firewall_allowed_fqdns

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # AKS needs these regardless of what the workload itself talks to. Without them
  # nodes fail to register and images never pull.
  network_rule_collection {
    name     = "aks-required"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "dns"
      protocols             = ["UDP"]
      source_addresses      = [var.vnet_address_space]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "azure-services"
      protocols             = ["TCP"]
      source_addresses      = [var.vnet_address_space]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "9000"]
    }
  }
}

resource "azurerm_public_ip" "firewall" {
  count = var.firewall_enabled ? 1 : 0

  name                = "${module.naming.public_ip.name}-afw"
  location            = var.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# Basic mandates a second, management-only NIC and public IP. Standard and
# Premium do not — this is the hidden cost of the cheaper tier.
resource "azurerm_public_ip" "firewall_management" {
  count = var.firewall_enabled && local.firewall_management_required ? 1 : 0

  name                = "${module.naming.public_ip.name}-afw-mgmt"
  location            = var.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall" "this" {
  count = var.firewall_enabled ? 1 : 0

  name                = module.naming.firewall.name
  location            = var.location
  resource_group_name = module.resource_group.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = local.tags

  ip_configuration {
    name                 = "primary"
    subnet_id            = local.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  dynamic "management_ip_configuration" {
    for_each = local.firewall_management_required ? [1] : []

    content {
      name                 = "management"
      subnet_id            = local.firewall_management_subnet_id
      public_ip_address_id = azurerm_public_ip.firewall_management[0].id
    }
  }
}

# The route that makes the firewall the egress path, and the reason the toggle
# needs care: with the firewall gone this route's next hop does not exist and all
# spoke egress black-holes. Tying it to the same variable means "firewall off"
# falls back to Azure's default outbound rather than breaking the spokes.
resource "azurerm_route" "spoke_default_via_firewall" {
  count = var.firewall_enabled ? 1 : 0

  name                   = "default-via-firewall"
  resource_group_name    = module.resource_group.name
  route_table_name       = azurerm_route_table.spoke_egress.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.this[0].ip_configuration[0].private_ip_address
}
