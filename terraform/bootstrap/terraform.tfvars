# Loaded automatically by terraform. Non-sensitive only — the subscription comes
# from ARM_SUBSCRIPTION_ID in the environment.

environment = "dev"
location    = "westeurope"

tags = {
  owner = "jay"
}

# Object IDs are not secrets.
state_stores = {
  # Add this repo's CI identity here, as ServicePrincipal, once the AZURE_CLIENT_ID
  # repository variable is set — ci-terraform's plan job takes a blob lease to lock
  # state, so it needs Contributor, not Reader.
  platform = {
    workload = "tfstate"
    blob_contributors = [
      {
        object_id      = "b168eef0-d213-406e-a7f9-7b9198d580da" # jay.withers@appvia.io
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
        object_id      = "b168eef0-d213-406e-a7f9-7b9198d580da" # jay.withers@appvia.io
        principal_type = "User"
      },
    ]
  }
}
