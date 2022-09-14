terraform {
  required_version = ">=1.1.2"

  required_providers {
    azurerm = "=3.19.1"
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_key_vault_secret" "secret" {
  for_each = {
    for index, secret in nonsensitive(var.secrets) :
    secret.secret_name => secret
  }
  name         = each.value.secret_name
  value        = each.value.secret_value
  key_vault_id = var.key_vault_id

  lifecycle {
    ignore_changes = [value]
  }
}