# governance

## Remediation

The DeployIfNotExists diagnostic-settings policy only reaches resources created
or updated *after* it exists. Its `azurerm_subscription_policy_remediation` is
a one-shot sweep taken at apply time — usually before the policy engine has
finished its initial compliance evaluation, so it typically remediates 0
resources. Run `make remediate POLICY=diag-alllogs-dev` any time you want to
force a fresh compliance scan and sweep again (safe to re-run).

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
| <a name="module_management_naming"></a> [management\_naming](#module\_management\_naming) | Azure/naming/azurerm | ~> 0.4 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_consumption_budget_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/consumption_budget_subscription) | resource |
| [azurerm_monitor_diagnostic_setting.activity_log](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_role_assignment.diag_all_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subscription_policy_assignment.allowed_locations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.diag_all_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.require_env_tag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_remediation.diag_all_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_remediation) | resource |
| [azurerm_log_analytics_workspace.management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_locations"></a> [allowed\_locations](#input\_allowed\_locations) | Regions the allowed-locations policy permits. | `list(string)` | <pre>[<br/>  "westeurope",<br/>  "northeurope"<br/>]</pre> | no |
| <a name="input_budget_alert_emails"></a> [budget\_alert\_emails](#input\_budget\_alert\_emails) | Recipients for budget threshold alerts. No alert is created when empty. | `list(string)` | n/a | yes |
| <a name="input_budget_start_date"></a> [budget\_start\_date](#input\_budget\_start\_date) | First of a month, RFC3339. Azure rejects a start date more than three months in the past. | `string` | `"2026-09-01T00:00:00Z"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label, used in assignment names. | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the diagnostic-settings policy assignments' managed identities. Governance is otherwise region-agnostic — this exists only because a SystemAssigned identity requires one. | `string` | `"westeurope"` | no |
| <a name="input_management_workload"></a> [management\_workload](#input\_management\_workload) | The management component's workload name. Used to locate its Log Analytics workspace — see the naming contract in the repo README. | `string` | `"mgmt"` | no |
| <a name="input_monthly_budget"></a> [monthly\_budget](#input\_monthly\_budget) | Monthly spend the budget alerts against, in the subscription's billing currency. Set to the credit allowance so alerts fire before it runs out. | `number` | `150` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_budget_name"></a> [budget\_name](#output\_budget\_name) | Consumption budget name, or null when no alert emails are configured. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription these assignments apply to. |
<!-- END_TF_DOCS -->
