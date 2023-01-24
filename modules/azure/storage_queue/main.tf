terraform {
  required_version = ">=1.1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.40"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_storage_queue" "storage_queue" {
  for_each             = var.queue_names
  name                 = each.value
  storage_account_name = var.storage_account_name
}