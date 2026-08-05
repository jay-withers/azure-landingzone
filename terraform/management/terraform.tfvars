# Loaded automatically by terraform. Non-sensitive only — the subscription comes
# from ARM_SUBSCRIPTION_ID in the environment.

environment = "dev"
location    = "westeurope"
workload    = "mgmt"

log_retention_days = 30

# 1 GB/day is roughly $2.80/day at the ceiling, so the worst case is bounded at
# well under the monthly credit. Raise it if you are actually chasing something.
daily_quota_gb = 1

tags = {
  owner = "jay"
}
