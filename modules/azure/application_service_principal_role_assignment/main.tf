terraform {
  required_version = "~> 1.3"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.36"
    }
  }

  backend "azurerm" {}
}

provider "azuread" {}

resource "azuread_service_principal" "internal" {
  for_each = toset([for assignment in var.assignments : assignment.client_id])
  client_id = each.key
  use_existing   = var.use_existing_service_principal
}

resource "azuread_app_role_assignment" "role_assignment" {
  for_each = {
    for assignment in var.assignments :
    "${assignment.role_id}_${assignment.object_id}_${assignment.client_id}" => assignment
  }
  app_role_id         = each.value.role_id
  principal_object_id = each.value.object_id
  resource_object_id  = azuread_service_principal.internal[each.value.client_id].object_id
}