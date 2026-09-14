# bootstrap

Grants access to the platform's Terraform remote-state storage account — it
does not create the account itself. `scripts/bootstrap-state.ps1` (repo root)
does that: an idempotent, stateless script, run by hand, that creates the
resource group, the storage account (no shared keys — RBAC only), blob
versioning/soft-delete, and one container per consumer. See that script's
header comment for why this is deliberately not Terraform.

This component only looks the account up (`data.tf`) and manages who can
reach it: a container-scoped `Storage Blob Data Contributor` grant per
consumer, reusing `landingzones`' existing vended identity where one already
exists (`terraform-root-aks`) rather than creating a duplicate, and a new
identity + federated credential where none exists yet (this repo's own
future CI pipeline).

Applies last, after `landingzones` — the `terraform-root-aks` reuse case
looks landingzones' identity up by name, which fails at plan time if
`landingzones` hasn't run yet.

Adding a consumer: add its container name to `scripts/bootstrap-state.ps1`'s
`-Containers` list and re-run it (idempotent — existing containers are left
alone), then add an entry to `state_consumers` here and apply.

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
| <a name="module_consumer_naming"></a> [consumer\_naming](#module\_consumer\_naming) | Azure/naming/azurerm | ~> 0.4 |
| <a name="module_landingzones_naming"></a> [landingzones\_naming](#module\_landingzones\_naming) | Azure/naming/azurerm | ~> 0.4 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_federated_identity_credential.new](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_role_assignment.state_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.new](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_resource_group.state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [azurerm_storage_container.consumer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_container) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_user_assigned_identity.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label. Used only to locate landingzones-vended identities via the naming contract — this component creates nothing suffixed by it directly. | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for identities created by this component. | `string` | `"westeurope"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The platform state resource group. Created by scripts/bootstrap-state.ps1, not Terraform — must match the -ResourceGroupName it was run with. Changing this means re-running the script with the new name first. | `string` | `"rg-tfplatform-dev"` | no |
| <a name="input_state_consumers"></a> [state\_consumers](#input\_state\_consumers) | One entry per consumer of the platform state storage account. The map key<br/>names the consumer and is also its container name — containers are<br/>created by scripts/bootstrap-state.ps1, so add the key to that script's<br/>-Containers list (and re-run it) before adding it here, or the container<br/>data source lookup fails.<br/><br/>Exactly one of the two identity shapes must be set:<br/>- `existing_landing_zone` : reuse the identity landingzones already<br/>  vended for this key in its own var.landing\_zones. No new identity is<br/>  created — this only grants the existing one access to its container.<br/>- `github_repo`           : no existing identity for this consumer — create<br/>  one here and federate it to this GitHub repo. federated\_subjects<br/>  defaults the same way landingzones does (pull\_request + refs/heads/main). | <pre>map(object({<br/>    existing_landing_zone = optional(string)<br/>    github_repo           = optional(string)<br/>    federated_subjects    = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The platform state storage account. Created by scripts/bootstrap-state.ps1, not Terraform — must match the -StorageAccountName it was run with. Changing this means re-running the script with the new name first. | `string` | `"sttfplatformdev"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged onto every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | Per consumer: the azurerm backend block values for its own backend.tf. |
| <a name="output_github_secrets"></a> [github\_secrets](#output\_github\_secrets) | Repository variables to set on each new-identity consumer's repo. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The platform state storage account's resource group. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The platform state storage account's name. |
<!-- END_TF_DOCS -->
