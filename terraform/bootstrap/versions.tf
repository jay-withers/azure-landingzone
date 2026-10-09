terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # No backend block, deliberately: this component creates the storage account
  # every other component keeps its state in, so it cannot keep its own there
  # without a bootstrap-destroy deleting the state it is running from. Its state
  # is a handful of resources with deterministic names — losing it costs one
  # `terraform import` per resource, not an outage.
}

provider "azurerm" {
  features {}

  # The accounts have shared keys disabled, and after creating one the provider
  # polls its blob endpoint before it reports success — with an account key unless
  # told otherwise, which fails with KeyBasedAuthenticationNotPermitted.
  storage_use_azuread = true
}
