terraform {
  required_version = ">= 1.9"

  # Present from this component's very first commit. scripts/bootstrap-state.ps1
  # creates the account and container this points at before Terraform ever runs
  # here, so there is no local-state-then-migrate step for bootstrap itself —
  # unlike a component that already has real state to carry over (e.g.
  # github-repos, migrating its existing GitHub-management resources into the
  # "shared" account).
  backend "azurerm" {
    resource_group_name  = "rg-tfplatform-dev"
    storage_account_name = "sttfplatformdev"
    container_name       = "azure-landingzone"
    key                  = "bootstrap.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
