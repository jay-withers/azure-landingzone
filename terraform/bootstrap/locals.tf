locals {
  # environment is not decoration: governance assigns the built-in "Require a tag on
  # resource groups" policy with effect Deny, keyed on `environment`. Drop this key
  # and every resource group creation in the subscription fails.
  tags = merge({
    environment = var.environment
    component   = "bootstrap"
    managed-by  = "terraform"
  }, var.tags)

  blob_contributors = merge([
    for store_key, store in var.state_stores : {
      for p in store.blob_contributors : "${store_key}--${p.object_id}" => merge(p, {
        store = store_key
      })
    }
  ]...)
}
