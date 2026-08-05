# principal_type is set on every assignment below. Without it azurerm looks the
# principal up in Entra, which fails intermittently on a just-created identity that
# has not finished replicating.

# The boundary. Contributor on the landing zone's own resource group and nothing
# wider — it cannot touch another landing zone, and it cannot grant roles, so it
# cannot widen its own access.
resource "azurerm_role_assignment" "contributor" {
  for_each = var.landing_zones

  scope                = module.resource_group[each.key].resource_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.lz[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Deliberately opt-in. This is the one grant that lets a landing zone hand out
# access, so it is the one worth thinking about — but scoped to its own resource
# group it can only grant within its own boundary. Role Based Access Control
# Administrator rather than User Access Administrator: the former cannot assign
# Owner or UAA itself, so the boundary cannot be escaped.
resource "azurerm_role_assignment" "rbac_administrator" {
  for_each = local.rbac_admin_grants

  scope                = module.resource_group[each.key].resource_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.lz[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# --- Cross-boundary grants on the hub ----------------------------------------
# RG-scoped Contributor stops at the landing zone, so anything reaching into the
# hub needs an explicit grant. Vending these deliberately, per resource, is the
# whole point — granting Contributor at subscription scope to avoid the bookkeeping
# would throw the boundary away entirely.

# Network Contributor on the hub VNet would work and is what most ALZ
# implementations use, but it is far more than peering needs — it also permits
# editing subnets and NSGs. These five actions are the whole of what establishing a
# peering from the spoke side requires.
resource "azurerm_role_definition" "vnet_peering" {
  name        = "Virtual Network Peering (${var.hub_workload}-${var.environment})"
  scope       = data.azurerm_subscription.current.id
  description = "Establish and remove peerings on the hub VNet. No subnet or NSG rights."

  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/peer/action",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
    ]
    not_actions = []
  }

  assignable_scopes = [data.azurerm_virtual_network.hub.id]
}

# Peering is a write on both VNets. Without this the spoke creates its own half and
# the peering sits in Initiated/Disconnected rather than Connected.
resource "azurerm_role_assignment" "hub_peering" {
  for_each = local.peering_grants

  scope              = data.azurerm_virtual_network.hub.id
  role_definition_id = azurerm_role_definition.vnet_peering.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.lz[each.key].principal_id
  principal_type     = "ServicePrincipal"
}

# Scoped to each individual zone, not the hub resource group, so a landing zone can
# link to the zones it was granted and no others. The built-in role covers creating
# and deleting virtual network links, which is all a spoke does here — the zones
# themselves stay owned by connectivity.
resource "azurerm_role_assignment" "dns_zone_contributor" {
  for_each = local.dns_zone_grants

  scope                = each.value.zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.lz[each.value.landing_zone].principal_id
  principal_type       = "ServicePrincipal"
}
