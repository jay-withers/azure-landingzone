locals {
  # Key: alert name segment. Value: the ARM operation it watches.
  privilege_change_operations = {
    roleassignment-write    = "Microsoft.Authorization/roleAssignments/write"
    roleassignment-delete   = "Microsoft.Authorization/roleAssignments/delete"
    roledefinition-write    = "Microsoft.Authorization/roleDefinitions/write"
    roledefinition-delete   = "Microsoft.Authorization/roleDefinitions/delete"
    policyassignment-delete = "Microsoft.Authorization/policyAssignments/delete"
    policyexemption-write   = "Microsoft.Authorization/policyExemptions/write"
    federatedcred-write     = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write"
    keyvault-delete         = "Microsoft.KeyVault/vaults/delete"
  }

  # Built-in definitions guarding settings every repo already gets right, so a
  # new one can't quietly regress them. IDs from Azure/azure-policy's
  # built-in-policies/policyDefinitions. Each accepts Audit, Deny or Disabled.
  #
  # Only secure transfer denies: no storage account in any repo turns HTTPS-only
  # off, and there is no case for one. The rest audit first; move one to Deny
  # once its compliance report is clean.
  baseline_policies = {
    storage-secure-transfer = {
      display_name = "Secure transfer to storage accounts should be enabled"
      id           = "404c3081-a854-4457-ae30-26a93ef643f9"
      effect       = "Deny"
    }
    storage-no-shared-key = {
      display_name = "Storage accounts should prevent shared key access"
      id           = "8c6a50c6-9ffd-4ae7-986f-5fa6111f9a54"
      effect       = "Audit"
    }
    keyvault-rbac = {
      display_name = "Azure Key Vault should use RBAC permission model"
      id           = "12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5"
      effect       = "Audit"
    }
    containerapps-https = {
      display_name = "Container Apps should only be accessible over HTTPS"
      id           = "0e80e269-43a4-4ae9-b5bc-178126b8a5cb"
      effect       = "Audit"
    }
    containerapps-identity = {
      display_name = "Managed Identity should be enabled for Container Apps"
      id           = "b874ab2d-72dd-47f1-8cb5-4a306478a4e7"
      effect       = "Audit"
    }
  }

  # Microsoft Graph and its delegated User.Read scope: the one permission an
  # EasyAuth sign-in needs to read the signed-in user's profile.
  graph_app_id       = "00000003-0000-0000-c000-000000000000"
  graph_user_read_id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
  # The default access app role every service principal has. Assigning it is
  # what lets a user sign in once app_role_assignment_required is on.
  default_access_role_id = "00000000-0000-0000-0000-000000000000"
}
