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

# Only here so this apply can destroy the EasyAuth app registrations still in
# state (main.app-registrations.tf was removed: no Entra sign-in for users,
# by decision). Delete it and the requirement above once that apply is done.
provider "azuread" {}
