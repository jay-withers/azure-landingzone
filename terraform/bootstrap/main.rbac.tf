# principal_type is set on every assignment below. Without it azurerm looks
# the principal up in Entra, which fails intermittently on a just-created
# identity that has not finished replicating — same reasoning as
# landingzones/main.rbac.tf.

# Container-scoped, not account-scoped — each consumer can read and write
# only its own state, never another consumer's. The account-wide grant that
# `terraform init`/`apply` itself needs to run at all is created by
# scripts/bootstrap-state.ps1 for the human operator, not here.
resource "azurerm_role_assignment" "state_access" {
  for_each = var.state_consumers

  scope                = data.azurerm_storage_container.consumer[each.key].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.consumer_principal_ids[each.key]
  principal_type       = "ServicePrincipal"
}
