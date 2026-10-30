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
