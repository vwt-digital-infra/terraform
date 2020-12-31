terraform {
  required_version = ">=0.13.5"

  required_providers {
    azurerm = "=2.41.0"
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "storage_account" {
  name                     = var.datalake_storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = var.datalake_storage_account_kind
  account_tier             = var.datalake_storage_account_tier
  account_replication_type = var.datalake_storage_replication_type
  is_hns_enabled           = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_management_lock" "storage_account_lock" {
  name       = "${var.datalake_storage_account_name}-lock"
  scope      = azurerm_storage_account.storage_account.id
  lock_level = "CanNotDelete"
  notes      = "Locked because deleting the resource can't be undone"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "filesystem" {
  name               = var.datalake_storage_filesystem_name
  storage_account_id = azurerm_storage_account.storage_account.id
}

resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "role_assignment_sleep" {
  create_duration = "60s"

  triggers = {
    role_assignment = azurerm_role_assignment.role_assignment.id
  }
}

resource "azurerm_storage_data_lake_gen2_path" "path" {
  for_each           = var.datalake_storage_folders
  path               = each.value.path
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.filesystem.name
  storage_account_id = azurerm_storage_account.storage_account.id
  resource           = "directory"

  dynamic "ace" {
    for_each = each.value.permissions
    content {
      type        = "group"
      scope       = ace.value.scope
      id          = ace.value.object_id
      permissions = ace.value.permissions
    }
  }

  depends_on = [
    azurerm_role_assignment.role_assignment,
    time_sleep.role_assignment_sleep
  ]
}
