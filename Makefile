# Apply order, and nothing enforces it. management first because it has no
# dependencies and governance reads its Log Analytics workspace. governance before
# connectivity so the policy guardrails exist before the infrastructure that has to
# comply with them — which is also why every component tags resource groups with
# `environment`: governance's require-tag policy is a Deny. landingzones last, as it
# reads connectivity's hub VNet and DNS zones.
COMPONENTS := management governance connectivity landingzones

# Component selector. Every terraform target needs it:
#
#   make plan C=connectivity
#   make apply C=connectivity TFARGS='-var firewall_enabled=true'
#
C      ?=
TF_DIR := terraform
DIR    := $(TF_DIR)/$(C)

# CHECKS has no default here (unlike BRANCH) — it must stay unset/empty so that
# the recipe below passes an empty string through to protect-branch.sh, which
# supplies its own (newline-separated) default. A Make variable can't hold that
# default itself: GNU Make invokes a separate shell per recipe line, splitting on
# any raw newline in an expanded value — even one inside a quoted shell string —
# which would break the quoting in the recipe below.
BRANCH ?= main

.DEFAULT_GOAL := help

.PHONY: help install protect-branch lint fmt check-component init validate plan apply destroy test validate-all cost remediate

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@printf "\nComponents (apply in this order): %s\n" "$(COMPONENTS)"
	@printf "Every terraform target needs C=<component>.\n"

install: ## Install pre-commit hooks (run once after cloning)
	pre-commit install
	pre-commit install --hook-type commit-msg

protect-branch: ## Configure GitHub repo settings (auto-merge, branch protection) via gh CLI - override BRANCH/CHECKS if your repo's checks differ
	./scripts/protect-branch.sh "$(BRANCH)" "$(CHECKS)"

lint: ## Run all pre-commit hooks against every file
	pre-commit run --all-files

fmt: ## terraform fmt -recursive across every component
	terraform fmt -recursive $(TF_DIR)/

# Guard rather than defaulting to a component: applying the wrong one by accident
# is worse than being told to name it. Checked against COMPONENTS rather than just
# testing the directory exists, so terraform/modules/ (shared local modules, not a
# root config) can't be planned or applied.
check-component:
	@test -n "$(C)" || { echo "set C=<component>, one of: $(COMPONENTS)"; exit 1; }
	@echo "$(COMPONENTS)" | tr ' ' '\n' | grep -qx "$(C)" \
		|| { echo "not a component: $(C) (one of: $(COMPONENTS))"; exit 1; }

init: check-component ## terraform init
	terraform -chdir=$(DIR) init

validate: init ## terraform init + validate
	terraform -chdir=$(DIR) validate

plan: init ## terraform plan (pass extra flags with TFARGS=...)
	terraform -chdir=$(DIR) plan $(TFARGS)

apply: init ## terraform apply (pass extra flags with TFARGS=...)
	terraform -chdir=$(DIR) apply $(TFARGS)

destroy: init ## terraform destroy
	terraform -chdir=$(DIR) destroy $(TFARGS)

test: init ## terraform test (mocked providers — no Azure auth). No tests written yet.
	terraform -chdir=$(DIR) test

validate-all: ## init + validate every component
	@for c in $(COMPONENTS); do \
		echo "==> $$c"; \
		terraform -chdir=$(TF_DIR)/$$c init -backend=false >/dev/null || exit 1; \
		terraform -chdir=$(TF_DIR)/$$c validate || exit 1; \
	done

remediate: ## Sweep existing resources against a DeployIfNotExists policy (make remediate POLICY=diag-alllogs-dev)
	@test -n "$(POLICY)" || { echo "set POLICY=<policy-assignment-name>, e.g. diag-alllogs-dev"; exit 1; }
	./scripts/remediate-policy.sh "$(POLICY)"

cost: ## What is switched on, and the hourly rate of the expensive bits
	@printf "Toggles that bill by the hour:\n\n"
	@grep -H -E '^firewall_enabled' $(TF_DIR)/connectivity/terraform.tfvars || true
	@printf "\n  firewall Basic    ~\$$0.40/hr  (~\$$290/mo - exceeds the monthly credit)\n"
	@printf "  firewall Standard ~\$$1.25/hr  (~\$$910/mo)\n"
	@printf "\nStanding cost with it off is a few dollars a month: DNS zones, storage, disks.\n"
	@printf "No bastion here - spokes run the free Developer SKU themselves.\n"
