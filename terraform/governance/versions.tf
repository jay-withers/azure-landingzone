terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Tenant and credentials from the `az login` session, like azurerm. Only
# main.app-registrations.tf uses it, and creating those registrations needs your
# own Entra rights: no pipeline identity has Graph permissions.
provider "azuread" {}
