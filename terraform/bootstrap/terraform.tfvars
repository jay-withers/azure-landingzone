# Loaded automatically by terraform. Non-sensitive only.

environment = "dev"
location    = "westeurope"

# Both created by scripts/bootstrap-state.ps1, not Terraform — see that
# script's header comment. Changing either means re-running it with the new
# value first.
resource_group_name  = "rg-tfplatform-dev"
storage_account_name = "sttfplatformdev"

state_consumers = {
  # This repo's own future CI pipeline. No existing identity to reuse, so
  # this creates one, federated to azure-landingzone.
  "azure-landingzone" = {
    github_repo = "jay-withers/azure-landingzone"
  }

  # Reuses the identity landingzones already vended for the aks landing zone
  # — see terraform/landingzones/terraform.tfvars. Never a second identity.
  "terraform-root-aks" = {
    existing_landing_zone = "aks"
  }
}

tags = {
  owner = "jay"
}
