locals {
  # environment is not decoration: governance assigns the built-in "Require a tag on
  # resource groups" policy with effect Deny, keyed on `environment`. Drop this key
  # and every resource group creation in the subscription fails.
  tags = merge({
    environment = var.environment
    component   = "management"
    managed-by  = "terraform"
  }, var.tags)
}
