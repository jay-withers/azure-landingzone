# State lives in bootstrap's platform state account. Backend blocks cannot take
# variables, so these are literals from bootstrap's state_stores output; the
# account name is seeded from the subscription ID so it does not change.
# Entra-only: shared keys are disabled on the account, so whoever runs this needs
# Storage Blob Data Contributor there (bootstrap's
# state_stores.platform.blob_contributors).
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstatedev02d6"
    container_name       = "tfstate"
    key                  = "landingzones.tfstate"
    use_azuread_auth     = true
  }
}
