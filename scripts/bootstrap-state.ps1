#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Idempotently creates (or corrects) a Terraform remote-state storage
    account: resource group, storage account, blob versioning/soft-delete,
    one container per consumer, and the operator's own data-plane RBAC grant.

.DESCRIPTION
    This is deliberately NOT Terraform. With shared storage-account keys
    disabled, a Terraform-created storage account needs the applier's own
    identity to already hold a data-plane role on the account before it can
    create anything inside it (a container, a role assignment written via
    `terraform init`'s state write) — but the account doesn't exist yet, so
    there's nothing to hold a role on. A stateless, idempotent script sidesteps
    that entirely: it has no backend of its own to bootstrap, and every step
    below checks what already exists before creating anything, so it's safe
    to re-run whenever a consumer is added.

    Containers are created via New-AzRmStorageContainer (the ARM/control-plane
    cmdlet), not the data-plane storage cmdlets — Contributor covers control
    plane, so no RBAC grant is needed just to create a container. This is the
    same mechanism Terraform's own AVM storage-account module uses internally
    for the same reason.

    Once this script has run, Terraform only needs to *look up* the account
    (a data source), never create it — see terraform/bootstrap/data.tf in this
    repo, or terraform/data.tf in github-repos, for the consuming side.

.PARAMETER ResourceGroupName
    Resource group the storage account lives in. Created if missing.

.PARAMETER StorageAccountName
    Must match the literal constant the consuming Terraform's variables.tf
    documents — changing this here without changing it there breaks the data
    source lookup.

.PARAMETER Location
    Azure region.

.PARAMETER Containers
    One container per state consumer. Re-run with an extended list to add a
    consumer later; existing containers are left untouched.

.PARAMETER OperatorPrincipalId
    Object ID to grant Storage Blob Data Contributor at account scope, so the
    signed-in operator can run `terraform init`/`apply` against this backend
    at all — without storage keys, everything (including Terraform's own
    state writes) goes through RBAC. Defaults to the signed-in account.

.EXAMPLE
    # azure-landingzone: the "platform" account
    ./scripts/bootstrap-state.ps1 -ResourceGroupName rg-tfplatform-dev -StorageAccountName sttfplatformdev `
        -Location westeurope -Containers azure-landingzone, terraform-root-aks

.EXAMPLE
    # github-repos: the "shared" account (copied verbatim into that repo)
    ./scripts/bootstrap-state.ps1 -ResourceGroupName rg-tfstate-shared -StorageAccountName sttfstateshared `
        -Location westeurope -Containers github-repos
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$StorageAccountName,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory)]
    [string[]]$Containers,

    [string]$OperatorPrincipalId = (Get-AzContext).Account.Id
)

$ErrorActionPreference = "Stop"

# 1. Resource group.
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Creating resource group $ResourceGroupName..."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
}
else {
    Write-Host "Resource group $ResourceGroupName already exists."
}

# 2. Storage account. No shared keys, TLS 1.2 minimum, no public blob access —
# RBAC is the only door in, matching Loki's storage account in
# terraform-root-aks/terraform/main.loki.tf. Public NETWORK access stays
# enabled: GitHub-hosted runners have no static egress and there's no
# self-hosted runner in this lab, so there is no private-networking option
# here — AAD-only auth plus per-container RBAC is the security boundary.
$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
if (-not $sa) {
    Write-Host "Creating storage account $StorageAccountName..."
    $sa = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName `
        -Location $Location -SkuName Standard_LRS -Kind StorageV2 -MinimumTlsVersion TLS1_2 `
        -AllowSharedKeyAccess $false -AllowBlobPublicAccess $false
}
else {
    Write-Host "Storage account $StorageAccountName already exists — checking for drift..."
    if ($sa.AllowSharedKeyAccess -ne $false -or $sa.MinimumTlsVersion -ne "TLS1_2") {
        Write-Host "Correcting drift on $StorageAccountName (shared keys / TLS version)..."
        Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName `
            -AllowSharedKeyAccess $false -MinimumTlsVersion TLS1_2 | Out-Null
    }
}

# 3. Blob versioning + soft delete. State files are exactly the case where
# this earns its keep — cheap (a handful of small JSON blobs), and the actual
# defence against losing state, not account replication.
Write-Host "Ensuring blob versioning and soft-delete retention on $StorageAccountName..."
Update-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName `
    -IsVersioningEnabled $true -DeleteRetentionPolicyDays 30 -RestorePolicyDays 0 | Out-Null

# 4. Containers, one per consumer — via the ARM-based cmdlet, control plane
# only, so ordinary Contributor is enough to create them.
foreach ($container in $Containers) {
    $existing = Get-AzRmStorageContainer -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName `
        -Name $container -ErrorAction SilentlyContinue
    if (-not $existing) {
        Write-Host "Creating container $container..."
        New-AzRmStorageContainer -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName `
            -Name $container -PublicAccess None | Out-Null
    }
    else {
        Write-Host "Container $container already exists."
    }
}

# 5. Operator RBAC. Without this, `terraform init`/`apply` against this
# backend cannot write the state blob at all — there are no keys, so this
# grant is the only way in for the human running Terraform.
$scope = $sa.Id
$existingAssignment = Get-AzRoleAssignment -ObjectId $OperatorPrincipalId -RoleDefinitionName "Storage Blob Data Contributor" `
    -Scope $scope -ErrorAction SilentlyContinue
if (-not $existingAssignment) {
    Write-Host "Granting Storage Blob Data Contributor to $OperatorPrincipalId on $StorageAccountName..."
    New-AzRoleAssignment -ObjectId $OperatorPrincipalId -RoleDefinitionName "Storage Blob Data Contributor" `
        -Scope $scope | Out-Null
}
else {
    Write-Host "$OperatorPrincipalId already has Storage Blob Data Contributor on $StorageAccountName."
}

Write-Host "Done. $StorageAccountName is ready with containers: $($Containers -join ', ')"
