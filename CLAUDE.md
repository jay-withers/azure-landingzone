# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo does

Terraform for a single-subscription Azure landing zone, run as a home lab on a
Visual Studio subscription's **$150/month credit**. A monorepo with one component
per landing zone concern, each its own root module with its own state, applied
independently.

## Layout

`terraform/<component>/` is a root module — `.tf` files directly in the directory,
with a committed `terraform.tfvars` that Terraform loads automatically. Components:
`governance`, `management`, `connectivity`, `landingzones`, and `workloads/<name>`
for spokes. Shared local modules live in `terraform/modules/`, which is *not* a
component — the Makefile validates `C=` against the `COMPONENTS` list so it can't be
planned or applied.

`terraform/` is the top-level directory rather than `components/` so the path matches
every other repo of Jay's and the template's own tooling globs (`terraform/**` in
paths-filter, `terraform/.tflint.hcl`, `TF_DIR`).

Apply order is `management → governance → connectivity → landingzones → workloads/*`,
and nothing enforces it. `management` is first because it has no dependencies and
`governance` reads its Log Analytics workspace. `governance` precedes `connectivity`
so policy guardrails exist before the infrastructure that must comply.
`landingzones` reads `connectivity`'s hub, and spokes deploy into the resource groups
`landingzones` vends.

**Every component must tag its resource groups with `environment`.** `governance`
assigns the built-in *Require a tag on resource groups* policy, whose effect is
**Deny** — drop that tag from any component's `local.tags` and resource group
creation fails across the entire subscription. This is load-bearing, not cosmetic.

**Spokes currently live in their own repositories** — `terraform-root-aks` stays put,
by decision, to keep the RBAC boundary its vended identity provides. Do not propose
moving it in; `terraform/workloads/` is empty and its README is the spoke contract.
The vended identity is federated to a GitHub repo rather than a location, so this
choice is reversible without any RBAC change.

## A landing zone is a resource group

Single subscription, so `landingzones` makes the resource group the boundary rather
than a subscription, and vends a user-assigned identity federated to the workload's
GitHub repo alongside it. Consequences to preserve:

- **The workload does not create its own resource group** — it looks the vended one
  up. The vended identity has no rights to create resource groups.
- **Cross-boundary grants must stay targeted.** RG Contributor stops at the landing
  zone, so hub access is granted per resource: a custom five-action role for VNet
  peering (not `Network Contributor`, which would also allow editing hub subnets and
  NSGs), and `Private DNS Zone Contributor` per zone. Never "fix" an
  AuthorizationFailed by widening to subscription scope — that discards the boundary.
- **`Role Based Access Control Administrator` is opt-in** per landing zone and scoped
  to its own RG. AKS needs it because it creates role assignments; `Contributor`
  cannot. Chosen over `User Access Administrator` because it cannot assign Owner or
  UAA, so the boundary can't be escaped.
- Set `principal_type = "ServicePrincipal"` on every role assignment — without it
  azurerm does an Entra lookup that fails intermittently on a fresh identity.

## The cost constraint is a design constraint

$150/month is about $0.20/hour for everything. Treat any hourly-billed resource as
a decision, not a default:

- **Azure Firewall** (~$0.40/hr Basic, ~$1.25/hr Standard) costs more per month
  than the entire credit. It is `count`-toggled off by default in `connectivity` and
  turned on per session with `-var`, never left set in tfvars.
- **Only billable resources toggle.** The firewall subnets, the policy and the route
  table are unconditional; the firewall, its public IPs and the default route are
  `count`-gated. Do not "tidy" the subnets under `firewall_enabled` — they are free,
  and gating them mutates the VNet on every toggle for no saving.
- **Do not add a bastion to `connectivity`.** The free Developer SKU cannot reach
  peered VNets so it cannot serve spokes from the hub, and a hub Basic bastion is
  ~$0.19/hr — about $140/month, near the whole credit. Spokes deploy their own free
  Developer bastion instead; `terraform-root-aks` already does.
- The **firewall policy is not toggled**, deliberately. Policies are free when
  attached to a single firewall, so rules persist across the firewall being
  destroyed. Do not fold the policy into the toggle.
- **Never remove `daily_quota_gb`** from the Log Analytics workspace. Uncapped
  per-GB ingestion is the most likely source of a surprise bill.
- When adding anything billed hourly, add a toggle and a cost comment at the same
  time, and update the table in the README and the `make cost` target.

Prefer `az aks command invoke` over provisioning any jump box or Bastion to reach a
private cluster — it is free.

## Components find each other by name, never by state

A consumer drives the same `Azure/naming` module with the *producer's* suffix and
then uses a data source. `terraform/governance/data.tf` is the worked example.

Do not introduce `terraform_remote_state`. The naming lookup is unchanged by local
vs remote state, by hand-apply vs per-component pipelines, and by whole-repo vs
single-directory checkout; remote state breaks at each of those transitions.

The `workload` variable is the contract — it plus `environment` determines every
name a component produces. Changing it is a breaking change to every consumer, so
consumers declare the producer's workload explicitly (`management_workload` in
`governance`).

## State

Local and gitignored; no backend block is committed, which is what makes the
eventual move a `backend.tf` plus `init -migrate-state` and nothing else. Do not
add an empty `backend "azurerm" {}` — it would force `-backend-config` on every
local run for no present benefit.

`connectivity` is the least disposable component and should migrate to remote state
first: losing its state orphans the address space and DNS zones.

## Module choices

AVM modules from the Terraform Registry for VNet, NSG, private DNS zone, resource
group; `Azure/naming` for names. Native `azurerm` resources for the firewall, its
policy and public IPs — the `count` toggles and the policy/firewall lifecycle split
read more plainly on bare resources. Keep that split.

The private DNS zone module takes `parent_id` (the resource group's *resource ID*),
not `resource_group_name`, and each `virtual_network_links` entry needs an explicit
`name`.

## Commands

Every terraform target needs a component:

```bash
make plan C=connectivity
make apply C=connectivity TFARGS='-var firewall_enabled=true'
make validate-all
make cost
```

Requires `ARM_SUBSCRIPTION_ID` exported — azurerm 4.x does not infer it from the
`az` CLI context.

## Relationship to template-terraform-root

This repo is aligned to
[`jay-withers/template-terraform-root`](https://github.com/jay-withers/template-terraform-root)
— same dev container, pre-commit hook set, scripts, Renovate preset, workflow
naming (`ci-` for PR checks, `cd-` for post-merge) and file-layout enforcement.

**The one structural divergence: the template's axis is per-environment, this repo's
is per-component.** The template is one module in `terraform/` planned via
`terraform/examples/basic/`, linted once per `terraform/environments/*.tfvars`. Here
there are four root configs under `terraform/`, one environment (single
subscription), each with its own committed `terraform.tfvars`. So:

- `scripts/tflint-per-env.sh` → `scripts/tflint-per-component.sh`
- `scripts/checkov-per-env.sh` → `scripts/checkov-per-component.sh`
- `ci-terraform`'s matrix is over components, not `[dev, stg, prd]`
- there is no `examples/` — components are root configs and plan directly
- provider lock files **are** committed (the template excludes them because it is a
  reusable module; these are root configs)

Keep the rest in step with the template. Ecosystem-wide Renovate policy belongs in
`template-renovate`, not here — `renovate.json` holds only `autoApprove` and the two
regex managers for `.terraform-version` and `.tflint.hcl`.

`scripts/check-tf-file-layout.sh` is a verbatim copy; if it changes upstream,
re-copy rather than hand-editing. One fix was needed in the per-component scripts:
the template uses `declare -A`, which is bash 4+ and fails on macOS's bash 3.2, so
dedup is done with `sort -u` instead.

## File layout is enforced

`locals`/`variable`/`output` blocks must live in a matching
`locals.tf`/`variables.tf`/`outputs.tf` or a topic-scoped variant
(`outputs.network.tf`), checked by `scripts/check-tf-file-layout.sh`. TFLint's
`terraform_standard_module_structure` is deliberately left disabled in
`terraform/.tflint.hcl` in favour of that script, which also covers locals and
topic-scoped names. Put new blocks in the right file from the start.

## Checkov skips

Every skip carries a justification. Two patterns recur:

- `CKV_TF_1` on registry-sourced modules — commit-hash pinning does not apply to
  Terraform Registry sources, which are pinned by version constraint instead.
- `CKV_AZURE_220` (firewall IDPS) — Premium-only, and Premium is ~$1,280/month
  against a $150 credit. The tier is the constraint, not the setting.

Checkov does not pass `--download-external-modules` (matching the template), so
resources created inside the AVM modules are not scanned — only what the components
declare directly.

## Commit messages

Conventional Commits, enforced by commitlint at commit-msg time. Examples:
`feat: add firewall toggle`, `fix: correct subnet prefix`, `chore: bump azurerm`.

## Pre-commit config

`.pre-commit-config.yaml` at the repo root. The `no-commit-to-branch` hook blocks
direct commits to `main`. TFLint and Checkov run via the local per-component scripts
rather than `pre-commit-terraform`'s own hooks, so a new component is picked up
automatically with no config change.

## CI

- **ci-pre-commit**: all linters on PRs to `main`, via the reusable workflow in
  `template-pipelines`. Because it is a reusable-workflow call, the status check
  context is `pre-commit / Pre-commit`, not the bare job id — this matters for the
  required status checks configured in branch protection.
- **ci-terraform**: a `changes` job (dorny/paths-filter) gates `validate` and `plan`,
  both matrixed over components. `validate` replaces the template's `test` job — no
  `.tftest.hcl` files exist yet; add a `test` job when they do. `plan` is gated on
  `vars.AZURE_CLIENT_ID != ''`. The always-running `ci-terraform` gate job is the
  check to require in branch protection.
- **cd-tag**: semver tag on merge to `main`.

Note a real limitation of `plan` in CI: components resolve each other with data
sources, so a plan fails until the dependency has been applied at least once —
`governance` needs `management`, `landingzones` needs `connectivity`. `fail-fast` is
off so each leg reports independently.
