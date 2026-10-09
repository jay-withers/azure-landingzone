# Each landing zone's workload keeps its Terraform state in a container of its own,
# in the landing zone state account bootstrap creates — not in the platform
# account, so nothing granted here can reach this repo's state.
#
# storage_account_id rather than storage_account_name: the container is created
# through ARM, which the key-less account requires.
#
# prevent_destroy means removing a landing zone from var.landing_zones fails at
# plan until this is lifted. That is deliberate: deleting the container while the
# workload's resources still exist orphans them. Destroy the workload first, then
# lift it. Soft delete keeps a deleted container recoverable for 30 days anyway.
resource "azurerm_storage_container" "lz_state" {
  #checkov:skip=CKV2_AZURE_21:Blob read logging would land in Log Analytics against the daily cap on every plan; versioning on the account covers the recovery case.
  for_each = var.landing_zones

  name                  = each.key
  storage_account_id    = data.azurerm_storage_account.state.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# Scoped to the container, not the account — the cross-boundary grant kept
# targeted, as with the hub grants. One landing zone's identity cannot read or
# lock another's state. Contributor rather than Reader because plan takes a blob
# lease to lock state.
resource "azurerm_role_assignment" "state_blob_contributor" {
  for_each = var.landing_zones

  scope                = azurerm_storage_container.lz_state[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.lz[each.key].principal_id
  principal_type       = "ServicePrincipal"
}
