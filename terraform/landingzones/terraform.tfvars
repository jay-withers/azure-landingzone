# Loaded automatically by terraform. Non-sensitive only — the subscription comes
# from ARM_SUBSCRIPTION_ID in the environment.

environment = "dev"
location    = "westeurope"

# Must match the connectivity component's workload, or the hub lookups in data.tf
# will not resolve.
hub_workload = "hub"

# Must match the management component's workload, or the log_analytics_contributor
# grant's workspace lookup in data.tf will not resolve.
management_workload = "mgmt"

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

    # The cluster sets its own diagnostic settings against the management
    # workspace directly, rather than governance reaching in via policy — see
    # governance/main.diagnostics.tf for why.
    log_analytics_contributor = true
  }
}

tags = {
  owner = "jay"
}
