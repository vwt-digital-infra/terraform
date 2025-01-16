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

resource "azurerm_servicebus_namespace" "service_bus" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  minimum_tls_version = var.minimum_tls_version
}

resource "azurerm_servicebus_namespace_authorization_rule" "authorization_rule" {
  count        = var.authorization_rule == null ? 0 : 1
  name         = "${var.name}-authorization-rule"
  namespace_id = azurerm_servicebus_namespace.service_bus.id

  listen = var.authorization_rule.listen
  send   = var.authorization_rule.send
  manage = var.authorization_rule.manage
}

data "azurerm_monitor_diagnostic_categories" "diagnostic_categories" {
  count       = var.log_analytics_workspace_id == null ? 0 : 1
  resource_id = azurerm_servicebus_namespace.service_bus.id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  count                      = var.log_analytics_workspace_id == null ? 0 : 1
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_servicebus_namespace.service_bus.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.diagnostic_categories[0].log_category_types

    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.diagnostic_categories[0].metrics

    content {
      category = metric.value
      enabled  = true
    }
  }
}
