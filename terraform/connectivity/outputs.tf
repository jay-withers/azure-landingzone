# Spokes are expected to find these by name with data sources rather than by
# reading this component's state — see the naming contract in the repo README.
# These outputs exist for humans and for `terraform output` after an apply.

output "resource_group_name" {
  description = "Resource group holding the hub."
  value       = module.resource_group.name
}

output "vnet_name" {
  description = "Hub virtual network name. Spokes peer to this."
  value       = module.vnet.name
}

output "vnet_id" {
  description = "Resource ID of the hub virtual network."
  value       = module.vnet.resource_id
}

output "privatelink_subnet_id" {
  description = "Subnet for private endpoints hosted in the hub."
  value       = local.privatelink_subnet_id
}

output "private_dns_zone_names" {
  description = "Zones hosted here. Spokes link themselves to these."
  value       = keys(module.private_dns_zones)
}

output "spoke_route_table_name" {
  description = "Route table spokes associate to route egress through the hub. Carries a default route only while the firewall is deployed."
  value       = azurerm_route_table.spoke_egress.name
}

output "privatelink_subnet_prefix" {
  description = "Address prefix of the private endpoint subnet, for spoke NSG rules."
  value       = local.privatelink_subnet_prefix
}

output "firewall_private_ip" {
  description = "Firewall private IP, or null when firewall_enabled is false."
  value       = one(azurerm_firewall.this[*].ip_configuration[0].private_ip_address)
}

output "firewall_public_ip" {
  description = "Egress IP seen by the internet, or null when firewall_enabled is false."
  value       = one(azurerm_public_ip.firewall[*].ip_address)
}
