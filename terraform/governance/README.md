# governance

## Alerting

Two broad subscription-wide activity log alerts, routed to the shared action group
`management` creates (set `alert_emails` there first, then here — same value in
both). Service Health covers Azure incidents/maintenance; the other is a broad
net on failed administrative operations, not a precise "policy denial" signal —
the activity log's `Policy` category covers changes to policy objects, not the
resource operation a Deny effect actually blocks. That blocked operation surfaces
under `Administrative`/`Error` instead, which is what this alerts on.

Plus one alert per privilege or guardrail change (`local.privilege_change_operations`):
role assignment and role definition writes and deletes, policy assignment deletes,
policy exemption writes, federated credential writes, and Key Vault deletes. They
aren't filtered by caller, so the pipelines' own role assignments email you too.
That's rare, and it's the record you'd want.

## Defender for Cloud and baseline policy

`main.defender.tf` declares foundational CSPM (`CloudPosture`, `Free`) and a
security contact on `alert_emails`. Every paid Defender plan stays off.

`local.baseline_policies` assigns five built-in definitions: secure transfer on
storage (**Deny**), plus Audit on shared-key storage, Key Vault RBAC, HTTPS-only
container apps and managed identity on container apps. Each guards something
every repo already does. Move one to Deny once its compliance report is clean.

## EasyAuth app registrations

`main.app-registrations.tf` creates an Entra app registration for each public
container app in `app_auth`, for Container Apps' built-in authentication.
They live here because no pipeline identity has Microsoft Graph rights. Each one:

- has a redirect URI per hostname (`https://<host>/.auth/login/aad/callback`);
- requires app role assignment, and assigns only `operator_object_id`, so no
  other user in the tenant can sign in;
- has **no client secret**: a federated credential trusts the app's own
  user-assigned identity, which the authConfig uses in place of a secret.

Applying it needs your own Entra rights to create app registrations, and the
apps' identities must already exist. Copy each client ID from
`terraform output app_auth_client_ids` into that app repo's
`environments/dev.tfvars` as `auth_client_id`. A new hostname (say, a custom
domain) goes in `app_auth` here first, or sign-in on it fails with AADSTS50011.

## github-repos' apply identity

`main.github-repos.tf` creates `uai-github-repos-apply-dev` (in
`rg-tfstate-shared`, beside every other `uai-<repo>-deploy-dev`) and grants it
Contributor and User Access Administrator on the subscription, plus Storage
Blob Data Contributor on github-repos' state container. github-repos'
`cd-terraform` applies with it. That repo creates every other pipeline's
identity, resource groups and role assignments, so it needs this much.

It lives here, not in github-repos, so no github-repos apply can change its
own rights. Its federated credential trusts only github-repos' `apply` GitHub
environment, which that repo restricts to `main`. Apply this component by hand
before github-repos first applies from CI.

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
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 3.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_management_naming"></a> [management\_naming](#module\_management\_naming) | Azure/naming/azurerm | ~> 0.4 |

## Resources

| Name | Type |
| ---- | ---- |
| [azuread_app_role_assignment.app_auth_operator](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.app_auth](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_federated_identity_credential.app_auth](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_service_principal.app_auth](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_consumption_budget_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/consumption_budget_subscription) | resource |
| [azurerm_federated_identity_credential.github_repos_apply](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_monitor_activity_log_alert.admin_failures](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.privilege_change](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.service_health](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_diagnostic_setting.activity_log](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_role_assignment.diag_all_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.github_repos_apply](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.github_repos_apply_state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_security_center_contact.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_contact) | resource |
| [azurerm_security_center_subscription_pricing.cloud_posture](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_subscription_pricing) | resource |
| [azurerm_subscription_policy_assignment.allowed_locations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.baseline](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.diag_all_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.require_env_tag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_remediation.diag_all_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_remediation) | resource |
| [azurerm_user_assigned_identity.github_repos_apply](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azurerm_log_analytics_workspace.management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_monitor_action_group.management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_action_group) | data source |
| [azurerm_resource_group.github_repos_state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.github_repos_state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [azurerm_storage_container.github_repos_state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_container) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_user_assigned_identity.app_auth](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alert_emails"></a> [alert\_emails](#input\_alert\_emails) | Recipients for operational alerts, routed through management's shared action group. Must match management's alert\_emails — an empty list here skips these assignments even if management created the action group, and a non-empty list here with an empty one in management fails to find it. Separate from budget\_alert\_emails — cost and ops recipients may differ. | `list(string)` | `[]` | no |
| <a name="input_allowed_locations"></a> [allowed\_locations](#input\_allowed\_locations) | Regions the allowed-locations policy permits. | `list(string)` | <pre>[<br/>  "westeurope",<br/>  "northeurope"<br/>]</pre> | no |
| <a name="input_app_auth"></a> [app\_auth](#input\_app\_auth) | Public container apps that get an Entra app registration for EasyAuth, keyed by<br/>a short name that becomes part of the registration's display name.<br/><br/>`hostnames` are every host the app is reached on: its custom domain and its<br/>default *.azurecontainerapps.io FQDN. Each gets a redirect URI, and a sign-in<br/>from a host not listed fails with AADSTS50011. `identity` is the app's existing<br/>user-assigned identity, which stands in for a client secret. | <pre>map(object({<br/>    hostnames = list(string)<br/>    identity = object({<br/>      name                = string<br/>      resource_group_name = string<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_budget_alert_emails"></a> [budget\_alert\_emails](#input\_budget\_alert\_emails) | Recipients for budget threshold alerts. No alert is created when empty. | `list(string)` | n/a | yes |
| <a name="input_budget_start_date"></a> [budget\_start\_date](#input\_budget\_start\_date) | First of a month, RFC3339. Azure rejects a start date more than three months in the past. | `string` | `"2026-09-01T00:00:00Z"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label, used in assignment names. | `string` | `"dev"` | no |
| <a name="input_github_repos_apply"></a> [github\_repos\_apply](#input\_github\_repos\_apply) | The identity jay-withers/github-repos applies with from CI (main.github-repos.tf).<br/><br/>`subject` is the OIDC subject of that repo's `apply` GitHub environment, in<br/>GitHub's immutable form: repo:<owner>@<owner id>/<repo>@<repo id>:environment:apply.<br/>The readable repo:<owner>/<repo> form never matches its tokens (AADSTS700213).<br/>The rest locate github-repos' state container in the "shared" account, and the<br/>resource group the identity lives in beside every other uai-<repo>-deploy-dev. | <pre>object({<br/>    subject              = string<br/>    resource_group_name  = optional(string, "rg-tfstate-shared")<br/>    storage_account_name = optional(string, "sttfsharedjw")<br/>    container_name       = optional(string, "github-repos")<br/>  })</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the diagnostic-settings policy assignments' managed identities. Governance is otherwise region-agnostic — this exists only because a SystemAssigned identity requires one. | `string` | `"westeurope"` | no |
| <a name="input_management_workload"></a> [management\_workload](#input\_management\_workload) | The management component's workload name. Used to locate its Log Analytics workspace — see the naming contract in the repo README. | `string` | `"mgmt"` | no |
| <a name="input_monthly_budget"></a> [monthly\_budget](#input\_monthly\_budget) | Monthly spend the budget alerts against, in the subscription's billing currency. Set to the credit allowance so alerts fire before it runs out. | `number` | `150` | no |
| <a name="input_operator_object_id"></a> [operator\_object\_id](#input\_operator\_object\_id) | Entra object ID of the one user assigned to every EasyAuth app registration (main.app-registrations.tf), and so the only one who can sign in to them. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_app_auth_client_ids"></a> [app\_auth\_client\_ids](#output\_app\_auth\_client\_ids) | EasyAuth client ID per app. Not secret: each app repo sets it as auth\_client\_id in environments/dev.tfvars. |
| <a name="output_budget_name"></a> [budget\_name](#output\_budget\_name) | Consumption budget name, or null when no alert emails are configured. |
| <a name="output_github_repos_apply_client_id"></a> [github\_repos\_apply\_client\_id](#output\_github\_repos\_apply\_client\_id) | Client ID of github-repos' apply identity. github-repos looks the identity up by name and sets this on its apply environment itself. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription these assignments apply to. |
<!-- END_TF_DOCS -->
