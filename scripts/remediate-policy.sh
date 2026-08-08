#!/usr/bin/env bash
# On-demand remediation for a DeployIfNotExists policy assignment.
#
# The azurerm_subscription_policy_remediation resource in Terraform is a
# one-shot snapshot: it sweeps whatever the policy engine has already marked
# non-compliant *at the moment terraform apply runs*, and does nothing on
# later applies, because nothing about its own config ever changes to trigger
# one. A freshly created assignment usually has not finished its initial
# compliance evaluation yet (up to ~30 minutes), so that first remediation
# typically finds and fixes zero resources — a "Succeeded" remediation task
# with a resource count of 0 is not a failure, just a race with the evaluator.
#
# This script is the manual top-up: force an immediate compliance scan, then
# create a fresh remediation task and wait for it to finish. Safe to re-run
# any time — a new resource showed up non-compliant, or you just want to
# re-sweep.
#
# An assignment of a policy *set* definition (an initiative, like the
# allLogs category-group initiative governance uses) cannot be remediated in
# one call — the API rejects a remediation with no --definition-reference-id,
# because an initiative bundles one constituent policy per resource type and
# remediation always targets exactly one of them. So for a set assignment this
# discovers which constituent reference IDs currently have non-compliant
# resources and creates one remediation task per reference ID found, rather
# than looping over all ~140 the initiative may contain.
#
# Requires: az CLI, logged in, and ARM_SUBSCRIPTION_ID exported (matching
# every other command in this repo).
#
# Usage:
#   ./scripts/remediate-policy.sh diag-alllogs-dev
set -euo pipefail

policy_assignment_name=${1:?"usage: $0 <policy-assignment-name>"}
: "${ARM_SUBSCRIPTION_ID:?ARM_SUBSCRIPTION_ID must be exported}"

assignment_id="/subscriptions/${ARM_SUBSCRIPTION_ID}/providers/Microsoft.Authorization/policyAssignments/${policy_assignment_name}"

wait_for_remediation() {
  local name=$1
  while :; do
    local state
    state=$(az policy remediation show --name "$name" --subscription "$ARM_SUBSCRIPTION_ID" --query provisioningState --output tsv)
    case "$state" in
    Succeeded | Failed | Canceled) break ;;
    *) sleep 10 ;;
    esac
  done
  az policy remediation show --name "$name" --subscription "$ARM_SUBSCRIPTION_ID" \
    --query "{state:provisioningState, deployed:deploymentStatus}" --output jsonc
}

create_and_wait() {
  local ref=$1
  local suffix=$2
  local remediation_name
  remediation_name="${policy_assignment_name}${suffix}-$(date +%Y%m%d%H%M%S)"

  echo "==> Creating remediation task: $remediation_name"
  if [[ -n "$ref" ]]; then
    az policy remediation create \
      --name "$remediation_name" \
      --policy-assignment "$assignment_id" \
      --definition-reference-id "$ref" \
      --subscription "$ARM_SUBSCRIPTION_ID" \
      --output none
  else
    az policy remediation create \
      --name "$remediation_name" \
      --policy-assignment "$assignment_id" \
      --subscription "$ARM_SUBSCRIPTION_ID" \
      --output none
  fi
  wait_for_remediation "$remediation_name"
}

echo "==> Triggering a compliance scan (not waiting — see below)..."
az policy state trigger-scan --subscription "$ARM_SUBSCRIPTION_ID" --no-wait

# Not --no-wait for speed alone: killing this script's local CLI call does not
# cancel the scan running server-side in Azure. A blocking trigger-scan run
# again shortly after (e.g. this script re-run after an earlier timeout) waits
# on that still-in-flight scan rather than starting a fresh one, and that wait
# can run well past what a fresh scan on this subscription normally takes.
# Remediation reads whatever compliance snapshot already exists at the moment
# it runs regardless, so there is nothing to gain from blocking here — if the
# snapshot is stale, re-run this script once the scan has had time to land.

policy_definition_id=$(az policy assignment show --name "$policy_assignment_name" --subscription "$ARM_SUBSCRIPTION_ID" --query policyDefinitionId --output tsv)

if [[ "$policy_definition_id" == *"/policySetDefinitions/"* ]]; then
  echo "==> Assignment targets a policy set definition — finding non-compliant reference IDs..."

  # Read loop rather than mapfile/readarray: matches tflint-per-component.sh's
  # own reasoning — mapfile is bash 4+, and macOS ships bash 3.2 at /bin/bash.
  refs=()
  while IFS= read -r ref; do
    [[ -n "$ref" ]] && refs+=("$ref")
  done < <(az policy state list --subscription "$ARM_SUBSCRIPTION_ID" \
    --filter "PolicyAssignmentId eq '${assignment_id}' and ComplianceState eq 'NonCompliant'" \
    --query "[].policyDefinitionReferenceId" --output tsv | sort -u)

  if [[ ${#refs[@]} -eq 0 ]]; then
    echo "No non-compliant resources found. Nothing to remediate."
    exit 0
  fi

  echo "Non-compliant reference IDs: ${refs[*]}"
  for ref in "${refs[@]}"; do
    create_and_wait "$ref" "-${ref}"
  done
else
  create_and_wait "" ""
fi
