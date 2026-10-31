# Loaded automatically by terraform. Non-sensitive only — the subscription comes
# from ARM_SUBSCRIPTION_ID in the environment.

environment       = "dev"
allowed_locations = ["westeurope", "northeurope"]
location          = "westeurope"

# Must match the management component's workload, or the workspace lookup in
# data.tf will not resolve.
management_workload = "mgmt"

# The Visual Studio credit allowance.
monthly_budget = 150

# No budget is created while this is empty.
budget_alert_emails = ["withersj888@outlook.com"]

# Must match management's alert_emails, or the action group lookup in data.tf
# will not resolve. No alerts are created while this is empty.
alert_emails = ["withersj888@outlook.com"]

# github-repos' CI apply identity. Owner and repo IDs from
# `gh api repos/jay-withers/github-repos --jq '{id, owner: .owner.id}'`; the
# environment is the one github-repos restricts to main.
github_repos_apply = {
  subject = "repo:jay-withers@288264678/github-repos@1345898182:environment:apply"
}

# The one user who can sign in through EasyAuth. Same principal as bootstrap's
# blob_contributors.
operator_object_id = "b168eef0-d213-406e-a7f9-7b9198d580da" # Jay Withers (Entra user)

# Hostnames: custom domain plus the default FQDN on cae-platform-dev
# (bravesand-91aa0544.northeurope.azurecontainerapps.io, also in the cloudflare
# repo's environments/dev.tfvars). Identities are the apps' own uai-<project>-dev.
app_auth = {
  career = {
    hostnames = ["career.jaywithers.uk", "ca-career-dev.bravesand-91aa0544.northeurope.azurecontainerapps.io"]
    identity  = { name = "uai-career-dev", resource_group_name = "rg-career-dev" }
  }
  finances = {
    hostnames = ["finances.jaywithers.uk", "ca-finances-dev.bravesand-91aa0544.northeurope.azurecontainerapps.io"]
    identity  = { name = "uai-finances-dev", resource_group_name = "rg-finances-dev" }
  }
  gymlog = {
    hostnames = ["health.jaywithers.uk", "ca-gymlog-dev.bravesand-91aa0544.northeurope.azurecontainerapps.io"]
    identity  = { name = "uai-gymlog-dev", resource_group_name = "rg-gymlog-dev" }
  }
  marketagent-api = {
    hostnames = ["ca-marketagent-dev-api.bravesand-91aa0544.northeurope.azurecontainerapps.io"]
    identity  = { name = "uai-marketagent-dev", resource_group_name = "rg-marketagent-dev" }
  }
  marketagent-dashboard = {
    hostnames = ["marketagent.jaywithers.uk", "ca-marketagent-dev-dashboard.bravesand-91aa0544.northeurope.azurecontainerapps.io"]
    identity  = { name = "uai-marketagent-dev", resource_group_name = "rg-marketagent-dev" }
  }
  observability = {
    hostnames = ["observability.jaywithers.uk", "ca-observability-dev.bravesand-91aa0544.northeurope.azurecontainerapps.io"]
    identity  = { name = "uai-observability-dev", resource_group_name = "rg-observability-dev" }
  }
}
