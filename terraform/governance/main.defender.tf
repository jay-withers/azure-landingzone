# Defender for Cloud on its free tier only: foundational CSPM, the secure score
# and its recommendations. Every paid plan (Servers, Storage, Key Vault,
# Containers...) bills per resource per month and stays off, so this costs
# nothing. Declared rather than left at Azure's default so the tier is visible
# here and a plan shows anyone switching a paid one on.
resource "azurerm_security_center_subscription_pricing" "cloud_posture" {
  #checkov:skip=CKV_AZURE_19:Standard tier bills per resource per month against a $150 credit. Foundational CSPM is the free baseline, chosen deliberately.
  tier          = "Free"
  resource_type = "CloudPosture"
}

# Where Defender sends its alerts and the weekly secure-score summary. Without a
# contact they go only to subscription owners' Entra mailboxes, which for this
# subscription isn't where alerts are read.
resource "azurerm_security_center_contact" "this" {
  #checkov:skip=CKV_AZURE_20:No phone number. Defender alerts by email, and nobody takes calls for a home lab.
  count = length(var.alert_emails) > 0 ? 1 : 0

  name                = "default"
  email               = join(";", var.alert_emails)
  alert_notifications = true
  alerts_to_admins    = true
}
