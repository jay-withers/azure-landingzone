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
# Requires: az CLI, logged in, and ARM_SUBSCRIPTION_ID exported (matching
# every other command in this repo).
#
# Usage:
#   ./scripts/remediate-policy.sh diag-alllogs-dev
set -euo pipefail

policy_assignment_name=${1:?"usage: $0 <policy-assignment-name>"}
: "${ARM_SUBSCRIPTION_ID:?ARM_SUBSCRIPTION_ID must be exported}"

assignment_id="/subscriptions/${ARM_SUBSCRIPTION_ID}/providers/Microsoft.Authorization/policyAssignments/${policy_assignment_name}"
remediation_name="${policy_assignment_name}-$(date +%Y%m%d%H%M%S)"

echo "==> Triggering a compliance scan (can take a few minutes on a large subscription)..."
az policy state trigger-scan --subscription "$ARM_SUBSCRIPTION_ID"

echo "==> Creating remediation task: $remediation_name"
az policy remediation create \
  --name "$remediation_name" \
  --policy-assignment "$assignment_id" \
  --subscription "$ARM_SUBSCRIPTION_ID" \
  --output none

echo "==> Waiting for it to finish..."
while :; do
  state=$(az policy remediation show --name "$remediation_name" --subscription "$ARM_SUBSCRIPTION_ID" --query provisioningState --output tsv)
  case "$state" in
  Succeeded | Failed | Canceled) break ;;
  *) sleep 10 ;;
  esac
done

az policy remediation show --name "$remediation_name" --subscription "$ARM_SUBSCRIPTION_ID" \
  --query "{state:provisioningState, deployed:deploymentStatus}" --output jsonc

echo
echo "Full detail: az policy remediation show --name $remediation_name --subscription $ARM_SUBSCRIPTION_ID"
