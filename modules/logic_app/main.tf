terraform {
  required_version = ">=1.1.2"

  required_providers {
    azurerm = "=2.88.0"
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

locals {
  // Remove need for specifying the "value" field for every parameter
  parameters_content = {
    for key, value in var.arm_parameters :
    key => { "value" = value }
  }
}

resource "azurerm_logic_app_workflow" "workflow" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

// Deploy workflow as ARM template conditional when arm_template_path is specified
// To export the ARM template from the Azure portal go to Logic App > Automation > Export Template
resource "azurerm_resource_group_template_deployment" "workflow_deployment" {
  count               = var.arm_template_path == null ? 0 : 1
  name                = "${var.logic_app_name}-deployment"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = file(var.arm_template_path)
  parameters_content  = jsonencode(local.parameters_content)

  depends_on = [azurerm_logic_app_workflow.workflow]
}

data "azurerm_monitor_diagnostic_categories" "diagnostic_categories" {
  count       = var.log_analytics_workspace_id == null ? 0 : 1
  resource_id = azurerm_logic_app_workflow.workflow.id
}

// Write logs and metrics to log analytics if specified
resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  count                      = var.log_analytics_workspace_id == null ? 0 : 1
  name                       = "diag-${logic_app_name}"
  target_resource_id         = azurerm_logic_app_workflow.workflow.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  // TODO: not yet implemented by Azure
  // log_analytics_destination_type = "Dedicated"

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.diagnostic_categories[0].logs

    content {
      category = log.value
      enabled  = true

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
}
