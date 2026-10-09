# bootstrap

The two storage accounts Terraform state lives in. Apply it first; nothing else
can `init` until it exists.

- **`platform`** (`sttfstatedev02d6`): one `<component>.tfstate` per component in
  this repo, in the `tfstate` container.
- **`landingzones`** (`stlzstatedev02d6`): workload state. Empty here; the
  `landingzones` component vends one container per landing zone, granted only to
  that landing zone's identity.

They are separate accounts so no grant on workload state, at any scope, can reach
platform state.

Its own state is **local** — it cannot live in the account it creates without a
destroy deleting the state it is running from. Every name here is deterministic
(the storage account's unique suffix is seeded from the subscription ID), so lost
state is recovered with `terraform import`, not by guessing.

Access is Entra-only: shared keys are disabled, so anyone running Terraform against
the other components must be in `state_stores.platform.blob_contributors`. See the root README's
*State* section for recovery and lease-breaking.

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
| [azurerm_management_lock.state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_role_assignment.state_blob_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.tfstate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label, used as the trailing element of every resource name. | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | `"westeurope"` | no |
| <a name="input_state_stores"></a> [state\_stores](#input\_state\_stores) | One resource group and storage account per entry. Two keys are required:<br/><br/>- `platform`     : state for this repo's components. Gets a `tfstate` container;<br/>                   every component's backend.tf points here.<br/>- `landingzones` : state for workloads deployed into vended landing zones. Holds<br/>                   no containers of its own — the landingzones component vends<br/>                   one per landing zone, with a grant scoped to that container.<br/><br/>`workload` names the resource group and account, and is hardcoded in backends<br/>(platform) or looked up by name (landingzones), so changing it means<br/>re-migrating state. `blob_contributors` get Storage Blob Data Contributor on the<br/>whole account — admins and the platform pipeline, not workload identities. It is<br/>needed even with Owner on the subscription: shared keys are disabled, and Owner<br/>grants no blob data access. principal\_type is User for a person,<br/>ServicePrincipal for a pipeline identity. | <pre>map(object({<br/>    workload = string<br/>    blob_contributors = optional(list(object({<br/>      object_id      = string<br/>      principal_type = string<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged onto every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_platform_container_name"></a> [platform\_container\_name](#output\_platform\_container\_name) | Container in the platform store holding one <component>.tfstate blob per component. |
| <a name="output_state_stores"></a> [state\_stores](#output\_state\_stores) | Resource group and storage account per state store. The platform values are hardcoded in every component's backend.tf — backend blocks cannot take variables. landingzones looks its store up by name. |
<!-- END_TF_DOCS -->
