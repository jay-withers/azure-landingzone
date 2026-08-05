# management

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
| <a name="module_naming"></a> [naming](#module\_naming) | Azure/naming/azurerm | ~> 0.4 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | Azure/avm-res-resources-resourcegroup/azurerm | ~> 0.4 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_daily_quota_gb"></a> [daily\_quota\_gb](#input\_daily\_quota\_gb) | Hard ingestion cap per day. Ingestion is billed per GB and is the least predictable cost in the subscription, so this is set rather than left unlimited — see the note in main.tf. | `number` | `1` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label, used as the trailing element of every resource name. | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | `"westeurope"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Workspace retention. 30 is the floor and is included in the per-GB price; beyond it you pay for retention separately. | `number` | `30` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged onto every resource. | `map(string)` | `{}` | no |
| <a name="input_workload"></a> [workload](#input\_workload) | Names this component's resources. Other components find the workspace from this and environment, so changing it is a breaking change to every consumer. | `string` | `"mgmt"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Resource ID of the workspace. |
| <a name="output_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#output\_log\_analytics\_workspace\_name) | Workspace name. Other components look the workspace up by this rather than reading it out of state. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group holding the management resources. |
<!-- END_TF_DOCS -->
