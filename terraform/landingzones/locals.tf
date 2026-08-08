locals {
  # environment is not decoration: governance assigns the built-in "Require a tag on
  # resource groups" policy with effect Deny, keyed on `environment`. Drop this key
  # and every landing zone's resource group is refused at creation.
  tags = merge({
    environment = var.environment
    component   = "landingzones"
    managed-by  = "terraform"
  }, var.tags)

  hub_dns_zones = { for z in data.azurerm_resources.hub_dns_zones.resources : z.name => z.id }

  # Federated credential names must be unique per identity and cannot contain the
  # ":" and "/" that appear in a subject, so the map key supplies the name and the
  # value supplies the subject.
  #
  # Defaults cover a plan-on-PR / apply-on-merge pipeline. Note the pull_request
  # subject carries no branch: it matches a PR from any branch in that repo, which
  # is the point — but it means anyone who can open a PR can run a plan as this
  # identity. Plan needs only read access; keep apply on the main credential.
  federated_credentials = merge([
    for key, lz in var.landing_zones : {
      for name, subject in coalesce(lz.federated_subjects, {
        "pull-request" = "repo:${lz.github_repo}:pull_request"
        "main"         = "repo:${lz.github_repo}:ref:refs/heads/main"
        }) : "${key}--${name}" => {
        landing_zone = key
        subject      = subject
      }
    }
  ]...)

  # An empty linkable_dns_zones means every zone the hub hosts.
  dns_zone_grants = merge([
    for key, lz in var.landing_zones : {
      for zone_name, zone_id in local.hub_dns_zones :
      "${key}--${zone_name}" => {
        landing_zone = key
        zone_id      = zone_id
      }
      if length(lz.linkable_dns_zones) == 0 || contains(lz.linkable_dns_zones, zone_name)
    }
  ]...)

  peering_grants = { for key, lz in var.landing_zones : key => lz if lz.peer_to_hub }

  rbac_admin_grants = { for key, lz in var.landing_zones : key => lz if lz.rbac_administrator }

  log_analytics_contributor_grants = { for key, lz in var.landing_zones : key => lz if lz.log_analytics_contributor }
}
