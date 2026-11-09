# github-repos' apply identity (uai-github-repos-apply-dev) used to be created
# and granted here. github-repos' own bootstrap (`make bootstrap`, run by hand
# as an Owner of the subscription) now owns it, so the platform estate can be
# rebuilt without this landing zone. Its rights still never come from an apply
# that runs as the identity itself.
#
# These blocks drop the identity, its federated credential and its grants from
# this component's state without destroying them. The live identity keeps
# working throughout. Delete this file once every state that held them has
# been applied with it.
removed {
  from = azurerm_user_assigned_identity.github_repos_apply

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_federated_identity_credential.github_repos_apply

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_role_assignment.github_repos_apply

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_role_assignment.github_repos_apply_state

  lifecycle {
    destroy = false
  }
}
