terraform {
  required_version = ">=1.1.2"

  required_providers {
    azurerm = "=2.94.0"
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = var.name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}
