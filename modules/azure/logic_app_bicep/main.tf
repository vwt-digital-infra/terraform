terraform {
  required_version = "~> 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.48"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
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

  do_bicep_build = var.templates_files.bicep_path != null ? true : false
}

resource "azurerm_logic_app_workflow" "workflow" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  enabled             = var.enabled

  dynamic "identity" {
    for_each = var.use_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "access_control" {
    for_each = length(var.trigger_oauth_policy_claims) > 0 ? [1] : []
    content {
      trigger {
        allowed_caller_ip_address_range = var.trigger_ip_address_range
        open_authentication_policy {
          name = "Default"
          dynamic "claim" {
            for_each = var.trigger_oauth_policy_claims
            content {
              name  = claim.key
              value = claim.value
            }
          }
        }
      }
    }
  }
}

// Deploy workflow as ARM template conditional when arm_template_path is specified
// To export the ARM template from the Azure portal go to Logic App > Automation > Export Template
resource "azurerm_resource_group_template_deployment" "workflow_deployment" {
  count               = (var.templates_files.arm_template_path == null && var.templates_files.bicep_path == null) ? 0 : 1
  name                = "${var.logic_app_name}-deployment"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = var.templates_files.arm_template_path != null ? file(var.templates_files.arm_template_path) : data.local_file.workflow_json.content
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
  name                       = "diag-${var.logic_app_name}"
  target_resource_id         = azurerm_logic_app_workflow.workflow.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  // TODO: not yet implemented by Azure
  // log_analytics_destination_type = "Dedicated"

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
}

resource "null_resource" "bicep_build" {
  count = local.do_bicep_build ? 1 : 0
  triggers = {
    timestamp = "${timestamp()}" # by setting the timestamp we will make it running every time
  }
  provisioner "local-exec" {
    command     = "az bicep build --file ${var.templates_files.bicep_path}"
    working_dir = var.module_dir
  }
}

data "local_file" "workflow_json" {
  depends_on = [null_resource.bicep_build]
  filename   = "${var.module_dir}/workflow.json"
}
