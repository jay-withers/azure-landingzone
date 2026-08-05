# landingzones

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_hub_naming"></a> [hub\_naming](#module\_hub\_naming) | Azure/naming/azurerm | ~> 0.4 |
| <a name="module_naming"></a> [naming](#module\_naming) | Azure/naming/azurerm | ~> 0.4 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | Azure/avm-res-resources-resourcegroup/azurerm | ~> 0.4 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_federated_identity_credential.lz](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_role_assignment.contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.dns_zone_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.hub_peering](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.rbac_administrator](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.vnet_peering](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_user_assigned_identity.lz](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_resources.hub_dns_zones](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_virtual_network.hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label, used as the trailing element of every resource name. | `string` | `"dev"` | no |
| <a name="input_hub_workload"></a> [hub\_workload](#input\_hub\_workload) | The connectivity component's workload name. Used to locate the hub VNet and its private DNS zones — see the naming contract in the repo README. | `string` | `"hub"` | no |
| <a name="input_landing_zones"></a> [landing\_zones](#input\_landing\_zones) | One entry per landing zone. Each gets a resource group, a user-assigned identity<br/>federated to a GitHub repository, and role assignments scoped to that resource<br/>group plus targeted grants on the hub resources it is allowed to touch.<br/><br/>The map key names the landing zone and drives its resource names.<br/><br/>- `github_repo`         : "owner/repo" the identity is federated to.<br/>- `federated_subjects`  : name => OIDC subject. Defaults to a pull\_request<br/>                          credential and a refs/heads/main credential, which is<br/>                          what a plan-on-PR / apply-on-merge pipeline needs.<br/>- `rbac_administrator`  : grant Role Based Access Control Administrator on the<br/>                          landing zone's own resource group. Needed when the<br/>                          workload creates role assignments itself — AKS does,<br/>                          for its subnet and ACR grants. Contributor cannot.<br/>- `peer_to_hub`         : grant the peering role on the hub VNet. Peering is a<br/>                          write on both sides, so without this the spoke can<br/>                          create only its half and the peering stays Disconnected.<br/>- `linkable_dns_zones`  : hub zones this landing zone may link its VNet to.<br/>                          Empty means every zone the hub hosts. | <pre>map(object({<br/>    github_repo        = string<br/>    federated_subjects = optional(map(string))<br/>    rbac_administrator = optional(bool, false)<br/>    peer_to_hub        = optional(bool, true)<br/>    linkable_dns_zones = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | `"uksouth"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged onto every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_github_secrets"></a> [github\_secrets](#output\_github\_secrets) | Repository variables to set on each workload repo. None of these are secret — a client ID is useless without a federated credential matching the caller. |
| <a name="output_hub_dns_zones_granted"></a> [hub\_dns\_zones\_granted](#output\_hub\_dns\_zones\_granted) | Which hub zones each landing zone may link its VNet to. |
| <a name="output_landing_zones"></a> [landing\_zones](#output\_landing\_zones) | Per landing zone: the resource group its workload deploys into, and the identity its pipeline authenticates as. |
<!-- END_TF_DOCS -->
