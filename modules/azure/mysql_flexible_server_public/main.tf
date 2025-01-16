terraform {
  required_version = "~> 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.48"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "random_password" "mysql_admin_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  keepers          = var.password_keeper
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_mysql_flexible_server" "mysql_flexible_server" {
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.admin_username
  administrator_password = random_password.mysql_admin_password.result

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  sku_name = var.server_sku
  version  = var.server_version

  storage {
    auto_grow_enabled = var.storage_auto_grow_enabled
    size_gb           = var.server_storage_max
  }

  dynamic "identity" {
    for_each = var.entra_administrator_enabled == false ? [] : [1]

    content {
      type         = "UserAssigned"
      identity_ids = [var.entra_identity_id]
    }
  }

  lifecycle {
    ignore_changes  = [zone]
    prevent_destroy = true
  }
}

resource "azurerm_mysql_flexible_database" "mysql_flexible_database" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql_flexible_server.name
  charset             = var.database_charset
  collation           = var.database_collation
}

resource "azurerm_mysql_flexible_server_configuration" "mysql_flexible_server_configuration" {
  name                = "slow_query_log"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql_flexible_server.name
  value               = var.slow_query_log
}

resource "azurerm_mysql_flexible_server_active_directory_administrator" "entra_admin" {
  count = var.entra_administrator_enabled == false ? 0 : 1

  server_id   = azurerm_mysql_flexible_server.mysql_flexible_server.id
  identity_id = var.entra_identity_id
  login       = var.entra_login
  object_id   = var.entra_object_id
  tenant_id   = var.entra_tenant_id
}

data "azurerm_monitor_diagnostic_categories" "diagnostic_categories" {
  count       = var.log_analytics_workspace_id == null ? 0 : 1
  resource_id = azurerm_mysql_flexible_server.mysql_flexible_server.id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  count                      = var.log_analytics_workspace_id == null ? 0 : 1
  name                       = "diag-${var.server_name}"
  target_resource_id         = azurerm_mysql_flexible_server.mysql_flexible_server.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.diagnostic_categories[0].log_category_types

    content {
      category = enabled_log.value

      retention_policy {
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.diagnostic_categories[0].metrics

    content {
      category = metric.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }

  // TODO: not yet implemented by Azure
  // log_analytics_destination_type = "Dedicated"
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}

resource "azurerm_mysql_flexible_server_firewall_rule" "rule" {
  for_each = var.whitelist_ip_addresses

  name                = "fw-${var.server_name}-${replace(each.value, ".", "-")}"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql_flexible_server.name
  start_ip_address    = each.value
  end_ip_address      = each.value
}

