#!/usr/bin/env bash
# Runs tflint once per component under terraform/, each against its own
# terraform.tfvars, so rules that depend on concrete variable values (naming,
# tags, region-specific checks) are evaluated against what the component
# actually deploys rather than unresolved variables.
#
# This is template-terraform-root's tflint-per-env.sh with the axis flipped.
# There, terraform/ is one module linted once per environment tfvars; here
# terraform/<component>/ is a separate root config with a single committed
# terraform.tfvars, because this repo targets one subscription and one
# environment. Components are discovered dynamically — add a directory under
# terraform/ with .tf files in it and it is covered automatically, no config
# change needed here. terraform/modules/ is picked up the same way.
#
# tflint, unlike checkov, does not recurse, so each directory is linted
# individually with the shared config. Hidden directories are pruned via
# -name '.?*' rather than -name .terraform specifically, so any future tool
# cache directory is excluded too without a code change; don't switch that to
# -name '.*' — it also matches the find root itself and silently prunes
# everything.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
tf_dir="$repo_root/terraform"
tflint_config="$tf_dir/.tflint.hcl"

# Deduplicated with sort -u rather than an associative array: `declare -A` is
# bash 4+, and macOS ships bash 3.2 at /bin/bash, so the template's own
# tflint-per-env.sh fails outside the Linux dev container. protect-branch.sh
# avoids mapfile for the same reason.
lint_dirs=()
while IFS= read -r dir; do
  lint_dirs+=("$dir")
done < <(find "$tf_dir" -type d -name '.?*' -prune -o -type f -name '*.tf' -print0 |
  xargs -0 -n1 dirname | sort -u)

if [ ${#lint_dirs[@]} -eq 0 ]; then
  echo "error: no directories containing .tf files found under $tf_dir" >&2
  exit 1
fi

tflint --init --chdir="$tf_dir" --config="$tflint_config"

status=0
for dir in "${lint_dirs[@]}"; do
  rel="${dir#"$repo_root"/}"
  args=(--chdir="$dir" --config="$tflint_config")

  # A component without a tfvars file is still linted, just with unresolved
  # variables — better than skipping it silently.
  if [[ -f "$dir/terraform.tfvars" ]]; then
    args+=(--var-file="terraform.tfvars")
  else
    echo "note: $rel has no terraform.tfvars; linting with unresolved variables"
  fi

  echo "==> tflint ($rel)"
  if ! tflint "${args[@]}"; then
    status=1
  fi
done

exit "$status"
