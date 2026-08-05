# connectivity

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_naming"></a> [naming](#module\_naming) | Azure/naming/azurerm | ~> 0.4 |
| <a name="module_nsg_privatelink"></a> [nsg\_privatelink](#module\_nsg\_privatelink) | Azure/avm-res-network-networksecuritygroup/azurerm | ~> 0.5 |
| <a name="module_private_dns_zones"></a> [private\_dns\_zones](#module\_private\_dns\_zones) | Azure/avm-res-network-privatednszone/azurerm | ~> 0.5 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | Azure/avm-res-resources-resourcegroup/azurerm | ~> 0.4 |
| <a name="module_vnet"></a> [vnet](#module\_vnet) | Azure/avm-res-network-virtualnetwork/azurerm | ~> 0.20 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_firewall.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) | resource |
| [azurerm_firewall_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) | resource |
| [azurerm_firewall_policy_rule_collection_group.egress](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_public_ip.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.firewall_management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_route.spoke_default_via_firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route_table.spoke_egress](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label, used as the trailing element of every resource name. | `string` | `"dev"` | no |
| <a name="input_firewall_allowed_fqdns"></a> [firewall\_allowed\_fqdns](#input\_firewall\_allowed\_fqdns) | Destinations spokes may reach over HTTPS when the firewall is the egress path. | `list(string)` | <pre>[<br/>  "*.ubuntu.com",<br/>  "*.docker.io",<br/>  "*.ghcr.io",<br/>  "*.azurecr.io"<br/>]</pre> | no |
| <a name="input_firewall_enabled"></a> [firewall\_enabled](#input\_firewall\_enabled) | Deploy the Azure Firewall. The policy and its rules persist when false, so flipping this back on restores the same configuration. | `bool` | `false` | no |
| <a name="input_firewall_sku_tier"></a> [firewall\_sku\_tier](#input\_firewall\_sku\_tier) | Basic is roughly a third the hourly cost of Standard but mandates a management subnet and second public IP. | `string` | `"Basic"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | `"westeurope"` | no |
| <a name="input_private_dns_zones"></a> [private\_dns\_zones](#input\_private\_dns\_zones) | Private DNS zones hosted in the hub and linked to it. Spokes link themselves to these by name. | `list(string)` | <pre>[<br/>  "privatelink.vaultcore.azure.net",<br/>  "privatelink.blob.core.windows.net",<br/>  "privatelink.azurecr.io"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged onto every resource. | `map(string)` | `{}` | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Hub address space. Subnet prefixes are carved from it, so it must be at least a /22. | `string` | `"10.0.0.0/22"` | no |
| <a name="input_workload"></a> [workload](#input\_workload) | Names this component's resources. Spokes reconstruct hub names from this and environment, so changing it is a breaking change to every consumer. | `string` | `"hub"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_firewall_private_ip"></a> [firewall\_private\_ip](#output\_firewall\_private\_ip) | Firewall private IP, or null when firewall\_enabled is false. |
| <a name="output_firewall_public_ip"></a> [firewall\_public\_ip](#output\_firewall\_public\_ip) | Egress IP seen by the internet, or null when firewall\_enabled is false. |
| <a name="output_private_dns_zone_names"></a> [private\_dns\_zone\_names](#output\_private\_dns\_zone\_names) | Zones hosted here. Spokes link themselves to these. |
| <a name="output_privatelink_subnet_id"></a> [privatelink\_subnet\_id](#output\_privatelink\_subnet\_id) | Subnet for private endpoints hosted in the hub. |
| <a name="output_privatelink_subnet_prefix"></a> [privatelink\_subnet\_prefix](#output\_privatelink\_subnet\_prefix) | Address prefix of the private endpoint subnet, for spoke NSG rules. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group holding the hub. |
| <a name="output_spoke_route_table_name"></a> [spoke\_route\_table\_name](#output\_spoke\_route\_table\_name) | Route table spokes associate to route egress through the hub. Carries a default route only while the firewall is deployed. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | Resource ID of the hub virtual network. |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | Hub virtual network name. Spokes peer to this. |
<!-- END_TF_DOCS -->
