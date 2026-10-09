module "naming" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"

  for_each = var.state_stores

  suffix = [each.value.workload, var.environment]

  # Storage account names are global, so the plain name could collide with
  # someone else's. Seeding from the subscription ID rather than letting the
  # module draw a random string keeps name_unique deterministic: losing this
  # component's local state never produces a different account name, and the
  # literal in every backend.tf stays valid. Consumers (landingzones) reproduce
  # the name with the same seed.
  unique-seed = data.azurerm_client_config.current.subscription_id
}

module "resource_group" {
  #checkov:skip=CKV_TF_1:Registry-sourced module pinned to a version constraint; commit-hash pinning does not apply to Terraform Registry sources.
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.4"

  for_each = var.state_stores

  name     = module.naming[each.key].resource_group.name
  location = var.location
  tags     = local.tags
}

# Two accounts rather than one: platform state and workload state have different
# writers, and keeping them apart means no grant on the workload account can ever
# reach platform state, whatever scope it is given.
#
# COST, each. Standard LRS holding a few hundred KB of state plus versions — cents a
# month. Not billed by the hour, so no toggle.
#
# Entra-only: shared keys are off, so every reader and writer needs Storage Blob
# Data Contributor (below) and backends set use_azuread_auth. That, not the
# network, is the boundary — the public endpoint stays open because state is
# written from a laptop and from GitHub-hosted runners with no fixed address.
resource "azurerm_storage_account" "this" {
  for_each = var.state_stores

  #checkov:skip=CKV2_AZURE_1:Customer-managed keys need a Key Vault and its own lifecycle for a few KB of state; Microsoft-managed encryption at rest applies.
  #checkov:skip=CKV2_AZURE_33:No private endpoint — state is written from a laptop and GitHub-hosted runners; Entra-only auth is the boundary.
  #checkov:skip=CKV_AZURE_59:Public network access is required for the same reason; shared keys are disabled so the endpoint accepts Entra tokens only.
  #checkov:skip=CKV_AZURE_35:Default-deny network rules would lock out GitHub-hosted runners, which have no fixed IP range.
  #checkov:skip=CKV_AZURE_206:LRS rather than GRS — state is versioned and soft-deleted, and a region outage in a home lab is not worth the doubled cost.
  #checkov:skip=CKV_AZURE_33:Queue service is unused; the account holds blobs only.
  #checkov:skip=CKV2_AZURE_40:Shared key access is disabled (shared_access_key_enabled = false); the check does not read it.
  #checkov:skip=CKV2_AZURE_41:No SAS tokens are issued — shared keys are disabled, so account SAS cannot be signed.
  name                     = module.naming[each.key].storage_account.name_unique
  location                 = var.location
  resource_group_name      = module.resource_group[each.key].name
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false

  # Recovery for state: every write keeps the previous version, and a deleted
  # blob or container is recoverable for 30 days.
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Platform state only. Landing zone containers are vended by the landingzones
# component, one per landing zone, so each sits beside the grant scoped to it.
#
# storage_account_id rather than storage_account_name: the container is then
# created through ARM, which works with shared keys disabled and needs no blob
# data access from whoever applies this.
resource "azurerm_storage_container" "tfstate" {
  #checkov:skip=CKV2_AZURE_21:Blob read logging would land in Log Analytics against the daily cap on every plan; versioning covers the recovery case.
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.this["platform"].id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# prevent_destroy only guards against this configuration; the lock also stops a
# portal click or `az group delete`. Remove it deliberately if the account really
# has to go.
resource "azurerm_management_lock" "state" {
  for_each = azurerm_storage_account.this

  name       = "lock-${each.value.name}"
  scope      = each.value.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state. Deleting it orphans every resource that state tracks."
}

# Owner on the subscription grants no blob data access, and shared keys are off,
# so state access is this role or nothing. principal_type comes from the input
# rather than being fixed to ServicePrincipal — a person applying from a laptop
# is a User. Account-wide, so this is for admins and the platform pipeline only;
# workload identities get container-scoped grants from landingzones.
resource "azurerm_role_assignment" "state_blob_contributor" {
  for_each = local.blob_contributors

  scope                = azurerm_storage_account.this[each.value.store].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.object_id
  principal_type       = each.value.principal_type
}
