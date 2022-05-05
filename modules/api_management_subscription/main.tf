terraform {
  required_version = ">=1.0.9"

  required_providers {
    azurerm = "=3.4.0"
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

locals {
  user_subs = flatten([
    for key, value in var.user_subscriptions : [for pair in setproduct([value.user_id], value.product_ids) :
    {
      user_id    = pair[0].value
      product_id = pair[1].value
      name       = "subcription-${pair[0].key}${pair[1].key}"
    }
  ]])
}

resource "azurerm_api_management_subscription" "subscription" {
  for_each = locals.user_subs
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  user_id             = each.value.user_id
  product_id          = each.value.product_id
  display_name        = each.value.name
}
