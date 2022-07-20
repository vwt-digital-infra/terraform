terraform {
  required_version = ">=1.0.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.14.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_api_management_named_value" "named_value" {
  for_each            = { for named_value in var.named_values : named_value.name => named_value }
  name                = each.value.name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  display_name        = each.value.name
  value               = each.value.value
  secret              = each.value.encrypt
}