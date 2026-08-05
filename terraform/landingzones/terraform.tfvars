# Loaded automatically by terraform. Non-sensitive only — the subscription comes
# from ARM_SUBSCRIPTION_ID in the environment.

environment = "dev"
location    = "uksouth"

# Must match the connectivity component's workload, or the hub lookups in data.tf
# will not resolve.
hub_workload = "hub"

landing_zones = {
  # The AKS cluster. rbac_administrator is on because the cluster creates its own
  # role assignments — subnet grants for its identity, and ACR pull for the kubelet.
  # Contributor alone cannot do that and the apply fails on AuthorizationFailed.
  aks = {
    github_repo        = "jay-withers/terraform-root-aks"
    rbac_administrator = true
    peer_to_hub        = true

    # Empty would grant every hub zone. The cluster only needs the vault zone today.
    linkable_dns_zones = ["privatelink.vaultcore.azure.net"]
  }
}

tags = {
  owner = "jay"
}
