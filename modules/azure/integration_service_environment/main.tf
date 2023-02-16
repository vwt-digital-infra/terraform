terraform {
  required_version = ">=0.14.9"

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

# TODO: Deprecated, will be removed in v4.0 of the Azure Provider https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/integration_service_environment
resource "azurerm_integration_service_environment" "ise" {
  name                       = var.ise_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku_name                   = var.sku_name
  access_endpoint_type       = var.access_endpoint_type
  virtual_network_subnet_ids = var.virtual_network_subnet_ids
}
