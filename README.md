# azure-landingzone

Terraform for a single-subscription Azure landing zone, built as a home lab on a
Visual Studio subscription's $150/month credit.

One repo, one component per landing zone concern, one Terraform state each.
Components are applied independently and by hand; each is shaped so it can be
handed to its own pipeline later without restructuring.

## Components

| Component | Owns | Standing cost |
| --------- | ---- | ------------- |
| [`management`](terraform/management/) | Log Analytics workspace, with a daily ingestion cap | per GB ingested, capped |
| [`governance`](terraform/governance/) | Subscription policy assignments, activity log routing, spend budget | free |
| [`connectivity`](terraform/connectivity/) | Hub VNet, private DNS zones, spoke route table, Azure Firewall (off by default) | ~$2/month with the firewall off |
| [`landingzones`](terraform/landingzones/) | A resource group per landing zone, plus the identity its pipeline authenticates as and its grants on the hub | free |
| [`workloads/`](terraform/workloads/) | Empty. Spokes live in their own repos for now — its README is the spoke contract | — |

Apply in that order:

```bash
make apply C=management
make apply C=governance
make apply C=connectivity
make apply C=landingzones
```

Nothing enforces it, and it is not arbitrary:

- **`management` first** — it has no dependencies, and `governance` reads its Log
  Analytics workspace to route activity logs. Applying `governance` first fails at
  plan time with a "not found".
- **`governance` before `connectivity`** so the policy guardrails exist before the
  infrastructure that must satisfy them. This is also why every component tags its
  resource groups with `environment`: governance assigns the built-in *Require a tag
  on resource groups* policy, whose effect is **Deny**. Remove that tag from any
  component and resource group creation across the whole subscription starts failing.
- **`landingzones` last** — it reads `connectivity`'s hub VNet and discovers its
  private DNS zones to grant against them.

Spokes then deploy into the resource groups `landingzones` vends.

## Cost, because the credit is the binding constraint

$150/month is about $0.20/hour for everything combined. Two resources in a normal
landing zone blow straight through that:

| Resource | Hourly | If left running |
| -------- | ------ | --------------- |
| Azure Firewall Basic | ~$0.40 | ~$290/mo — **exceeds the whole credit in ~16 days** |
| Azure Firewall Standard | ~$1.25 | ~$910/mo |
| Azure Bastion Basic | ~$0.19 | ~$140/mo — near enough the entire credit |

The firewall is therefore **off by default** and toggled on per session. Bastion
isn't here at all — see below.

A three-hour session with the firewall on costs a few dollars, which is fine.
A month does not exist within the budget. So:

```bash
make apply C=connectivity TFARGS='-var firewall_enabled=true'
# ... work ...
make apply C=connectivity      # off again; the policy and its rules persist
```

The firewall **policy** is deliberately not toggled. Azure only bills a policy
when it is shared across multiple firewalls, so a single-firewall policy is free
to leave standing — meaning your rules survive the firewall being destroyed and
come back unchanged when you flip it on. You are cycling the compute, not the
configuration.

`make cost` prints what is currently switched on.

Three more things that matter more than the firewall on this budget:

- **The Log Analytics daily cap.** Ingestion is billed per GB with no default
  ceiling, and AKS logs will produce several GB/day unattended. `management` sets
  `daily_quota_gb = 1`. This is the most likely cause of a surprise bill.
- **The budget alert.** Set `budget_alert_emails` in
  [`governance/terraform.tfvars`](terraform/governance/terraform.tfvars) — no
  budget is created while it is empty, and a budget only notifies, it never caps.
- **There is no Bastion in this repo, on purpose.** The free Developer SKU cannot
  reach peered VNets, so it can't serve spokes from the hub — and a hub Basic
  bastion is ~$140/month. So each spoke deploys its own free Developer bastion next
  to its VM instead, which is what `terraform-root-aks` already does. Better still,
  check whether you need a VM: for a private AKS cluster `az aks command invoke`
  runs `kubectl` inside the cluster for free, with no jump box, bastion or VPN.

## A landing zone is a resource group, not a subscription

Real ALZ vends a subscription per platform or application landing zone. With one
subscription, [`landingzones`](terraform/landingzones/) makes the **resource group**
the boundary instead, and vends alongside it a user-assigned identity federated to
the workload's GitHub repository. The workload repo's pipeline authenticates as that
identity and can write only inside its own resource group.

What that keeps from the real thing:

- **A genuine RBAC boundary.** `Contributor` on one resource group cannot touch
  another, and cannot grant roles, so it cannot widen its own access.
- **Per-landing-zone policy** — `azurerm_resource_group_policy_assignment` scopes
  fine. You lose the *hierarchy*, not policy scoping.
- **Cost grouping**, since Cost Management groups by resource group — which on a
  fixed credit is the view that matters.
- **`az group delete`** as a teardown primitive.

What it loses: **quota isolation.** vCPU and public IP limits are subscription-wide,
so one landing zone can starve another. Irrelevant here — the credit runs out first.

Also note the workload no longer creates its own resource group. The group *is* the
thing being vended, and the vended identity has no rights to create resource groups,
so the workload looks its group up and deploys into it.

### Cross-boundary grants are the interesting part

Resource-group Contributor stops at the landing zone, so anything reaching into the
hub needs an explicit, targeted grant — and vending those deliberately is the whole
point. Granting `Contributor` at subscription scope to avoid the bookkeeping throws
the boundary away entirely.

- **Peering is a write on both VNets.** Without a grant on the hub the spoke creates
  only its half and the peering sits Disconnected. `landingzones` defines a **custom
  role** with just the five peering actions rather than using `Network Contributor`,
  which would also permit editing the hub's subnets and NSGs.
- **DNS zone links** are writes on the zone, so `Private DNS Zone Contributor` is
  granted per zone — a landing zone links only the zones it was given.
- **Creating role assignments** needs `Role Based Access Control Administrator`,
  which `Contributor` does not include. AKS needs it (subnet grants, ACR pull), so
  it is opt-in per landing zone via `rbac_administrator` and scoped to that landing
  zone's own resource group. Chosen over `User Access Administrator` because it
  cannot itself assign Owner or UAA, so the boundary can't be escaped.

Custom role definitions, identities, federated credentials and role assignments are
all free.

## How components find each other

Components do **not** read each other's state. A consumer reconstructs the
producer's resource names by driving the same `Azure/naming` module with the
producer's suffix, then looks the resource up with a data source —
[`governance/data.tf`](terraform/governance/data.tf) is the worked example.

This is why: the lookup is byte-identical whether state is local or remote, whether
components are applied by hand or by separate pipelines, and whether a pipeline
checks out the whole repo or one directory. Nothing about the wiring needs to
change as this grows. `terraform_remote_state` would need rewriting at every one of
those transitions.

The cost is that a consumer can only read values it can *name* — VNet IDs, subnet
IDs, zone IDs, workspace IDs. That covers landing zone layering; it would not cover
passing arbitrary computed values around.

**The contract is the `workload` variable.** Each component's `workload` plus
`environment` determines every name it produces. Changing `workload` renames
everything and breaks every consumer, so consumers declare the producer's workload
explicitly (e.g. `management_workload` in `governance`).

## State

Local, and gitignored. That is a deliberate trade while this is applied by hand,
but note the asymmetry: `connectivity` is now the *least* disposable component —
losing its state file orphans the address space and the DNS zones into an import
job, where losing a spoke's state costs nothing because you would rebuild it
anyway.

So when you outgrow local state, migrate `connectivity` first. The move is a
`backend.tf` in the component directory plus `terraform init -migrate-state`, with
no other change — which is why no backend block is committed today.

## Prerequisites

Built around the dev container at [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json),
which provides Terraform, TFLint, terraform-docs and Checkov and runs `make install`
on creation. Prefer working inside it so tool versions match CI. The Terraform
version is pinned in [`.terraform-version`](.terraform-version) at the repo root,
where tfenv/tenv and CI can find it.

- Terraform — version per `.terraform-version`
- Azure CLI, logged in, with Owner or Contributor + User Access Administrator
- The target subscription exported for the provider:

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

`azurerm` 4.x requires this explicitly — it does not infer the subscription from
your `az` context.

## Commands

```bash
make                                 # help, and the component list
make install                         # pre-commit hooks (once after cloning)
make protect-branch                  # GitHub auto-merge + branch ruleset via gh
make lint                            # all linters
make fmt                             # terraform fmt across terraform/

make plan    C=connectivity          # every terraform target needs C=
make apply   C=connectivity
make destroy C=connectivity
make validate-all                    # validate every component
make cost                            # what is currently billing hourly
```

Extra flags go through `TFARGS`:

```bash
make apply C=connectivity TFARGS='-var firewall_enabled=true -var firewall_sku_tier=Standard'
```

## Structure

```text
terraform/
  .tflint.hcl            # shared by every component
  governance/            # subscription policy, activity logs, budget
  management/            # log analytics
  connectivity/          # hub vnet, private dns, firewall
  landingzones/          # rg + federated identity + hub grants per landing zone
  workloads/             # spokes (empty — see its README for the spoke contract)
  modules/               # shared local modules (empty)
scripts/
  check-tf-file-layout.sh
  tflint-per-component.sh
  checkov-per-component.sh
  protect-branch.sh
.devcontainer/
.pre-commit-config.yaml
.terraform-version
commitlint.config.js
renovate.json
Makefile
```

Each component directory is a root module — `.tf` files sit directly in it, with a
committed `terraform.tfvars` holding non-sensitive values that Terraform loads
automatically, and a `README.md` whose `BEGIN_TF_DOCS`/`END_TF_DOCS` block is
generated by terraform-docs (don't hand-edit inside the markers).

`terraform/modules/` is not a component — `make` validates `C=` against the component
list, so it can't be planned or applied by mistake.

## Not built yet

- **`bootstrap`** — the state storage account. Needed before remote state; not needed
  while applying locally. The OIDC side is already covered by `landingzones` for
  workload repos, but this repo's own pipeline will need its own identity.
- **Pipelines.** The intended shape is one workflow with a path-filtered matrix
  over `terraform/*`, plus a single always-running gate job as the required
  check, so the check reports even when a PR touches no Terraform.
- **Wiring `terraform-root-aks` up as a spoke.** It stays in its own repo — decided
  deliberately, to keep the RBAC boundary the vended identity gives it. Two changes
  needed there: stop creating its own resource group (it looks the vended one up), and
  stop creating `privatelink.vaultcore.azure.net` (link to the hub's instead). Then
  peer to the hub and set the three repository variables from the `github_secrets`
  output.
- **Scheduled shutdown.** An Automation Account runbook to stop billable resources
  overnight. The `firewall_enabled` toggle covers most of the value already, and
  anything scheduled has to not fight Terraform's view of state.
