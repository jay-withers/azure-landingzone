# Loaded automatically by terraform. Non-sensitive only — the subscription comes
# from ARM_SUBSCRIPTION_ID in the environment.

environment = "dev"
location    = "uksouth"
workload    = "hub"

vnet_address_space = "10.0.0.0/22"

# Off. Turn on per session with -var, don't leave it set here — a month of it
# costs more than the whole credit.
firewall_enabled = false

# Basic is a third of Standard's hourly rate; it costs an extra public IP and a
# management subnet in exchange.
firewall_sku_tier = "Basic"

tags = {
  owner = "jay"
}
