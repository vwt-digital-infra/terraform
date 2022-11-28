terraform {
  required_version = ">=1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.6.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

locals {
}

resource "azurerm_api_management_certificate" "apim_certificate" {
  name                = var.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name

  key_vault_secret_id = var.keyvault_certificate_id
  data                = var.certificate_location != null? filebase64(var.certificate_location): null
  password            = var.certificate_password

  lifecycle {
    precondition {
      condition     = (var.certificate_location != null && var.keyvault_certificate_id==null) || (var.certificate_location == null && var.keyvault_certificate_id!=null)
      error_message = "Wrong Keyvault ID and Certificate location COmbination, one and only one the those should have value"
    }
  }
}