# Loaded automatically by terraform. Non-sensitive only — the subscription comes
# from ARM_SUBSCRIPTION_ID in the environment.

environment = "dev"
location    = "westeurope"

tags = {
  owner = "jay"
}

# Object IDs are not secrets.
state_stores = {
  # This repo's CI identity is granted on the tfstate container in
  # main.pipeline.tf, not here.
  platform = {
    workload = "tfstate"
    blob_contributors = [
      {
        object_id      = "b168eef0-d213-406e-a7f9-7b9198d580da" # Jay Withers (Entra user)
        principal_type = "User"
      },
    ]
  }

  # Workload identities are NOT listed here — landingzones grants each one its own
  # container only. This list is break-glass: recovering a version, breaking a lease.
  landingzones = {
    workload = "lzstate"
    blob_contributors = [
      {
        object_id      = "b168eef0-d213-406e-a7f9-7b9198d580da" # Jay Withers (Entra user)
        principal_type = "User"
      },
    ]
  }
}

# The CI apply identity's federated subject. Owner and repo IDs from
# `gh api repos/jay-withers/azure-landingzone --jq '{id, owner: .owner.id}'`;
# the environment is the one github-repos restricts to main.
pipeline_identity = {
  subject = "repo:jay-withers@288264678/azure-landingzone@1324447022:environment:apply"
}
