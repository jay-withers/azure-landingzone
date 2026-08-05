#!/usr/bin/env bash
# Runs checkov once per component under terraform/, each against its own
# terraform.tfvars, so checks that depend on concrete variable values are
# evaluated against what the component actually deploys rather than unresolved
# variables.
#
# This is template-terraform-root's checkov-per-env.sh with the axis flipped:
# there, terraform/ is one module scanned once per environment tfvars; here
# terraform/<component>/ is a separate root config with a single committed
# terraform.tfvars. Checkov recurses, but --var-file is per-invocation, so
# components are still scanned one at a time to keep each paired with its own
# variables.
#
# Not passing --download-external-modules, matching the template: it cost ~15s
# per invocation regardless of caching (checkov's own graph-building overhead,
# not network time). That trade is worse here than in the template, since this
# repo has more invocations. The consequence is that resources created inside
# the AVM modules are not scanned — only what the components declare directly —
# and checkov logs a harmless "Failed to download module" warning.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
tf_dir="$repo_root/terraform"

shopt -s nullglob
component_dirs=("$tf_dir"/*/)
shopt -u nullglob

if [ ${#component_dirs[@]} -eq 0 ]; then
  echo "error: no components found in $tf_dir" >&2
  exit 1
fi

status=0
for dir in "${component_dirs[@]}"; do
  dir="${dir%/}"
  component=$(basename "$dir")

  # Skip directories with no .tf files of their own: terraform/workloads/ while
  # spokes live in their own repositories, and terraform/modules/, whose contents
  # are one level deeper (tflint's find-based discovery still reaches those).
  shopt -s nullglob
  tf_files=("$dir"/*.tf)
  shopt -u nullglob
  if [ ${#tf_files[@]} -eq 0 ]; then
    continue
  fi

  args=(-d "$dir" --quiet --compact)
  if [[ -f "$dir/terraform.tfvars" ]]; then
    args+=(--var-file "$dir/terraform.tfvars")
  fi

  echo "==> checkov ($component)"
  if ! checkov "${args[@]}"; then
    status=1
  fi
done

exit "$status"
