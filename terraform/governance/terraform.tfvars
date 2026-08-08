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
budget_alert_emails = ["jay.withers@appvia.io"]
