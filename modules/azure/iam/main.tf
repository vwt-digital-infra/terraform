terraform {
  required_version = "~> 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      // version to 3.87 due to bug in 3.88. If 3.89 is released, we can upgrade to that
      // bug in terraform https://github.com/hashicorp/terraform-provider-azurerm/issues/24560#issuecomment-1900197715
      version = ">= 3.48.0, < 3.88.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_role_assignment" "role_assignment" {
  for_each = {
    for role in var.roles :
    "${role.object_id}_${role.role_name}${role.name != null ? "_${role.name}" : ""}" => role
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_name
  principal_id         = each.value.object_id
}
