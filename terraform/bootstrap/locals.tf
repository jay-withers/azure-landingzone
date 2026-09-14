locals {
  tags = merge({
    environment = var.environment
    component   = "bootstrap"
    managed-by  = "terraform"
  }, var.tags)

  existing_consumers = { for k, c in var.state_consumers : k => c if c.existing_landing_zone != null }
  new_consumers      = { for k, c in var.state_consumers : k => c if c.github_repo != null }

  # Federated credential names must be unique per identity and cannot contain
  # the ":" and "/" that appear in a subject, so the map key supplies the name
  # and the value supplies the subject. Same shape as landingzones/locals.tf.
  federated_credentials = merge([
    for key, c in local.new_consumers : {
      for name, subject in coalesce(c.federated_subjects, {
        "pull-request" = "repo:${c.github_repo}:pull_request"
        "main"         = "repo:${c.github_repo}:ref:refs/heads/main"
        }) : "${key}--${name}" => {
        consumer = key
        subject  = subject
      }
    }
  ]...)

  consumer_principal_ids = merge(
    { for k, v in local.existing_consumers : k => data.azurerm_user_assigned_identity.existing[k].principal_id },
    { for k, v in local.new_consumers : k => azurerm_user_assigned_identity.new[k].principal_id },
  )
}
