terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # AVM network modules provision through azapi.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  # No backend block: state is local while this is applied by hand. Adding a
  # backend.tf here plus `init -migrate-state` is the whole move to remote state.
}

provider "azurerm" {
  features {}
}
