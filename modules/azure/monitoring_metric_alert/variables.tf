variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "action_group_id" {
  type        = string
  description = "ID of the action group to associate the alert with."
}


variable "monitoring_rules" {
  type = list(object({
    name                    = string
    description             = string
    monitored_resource_id   = string
    metric_namespace        = string
    metric_name             = string
    aggregation             = string
    operator                = string
    threshold               = number
    frequency               = optional(string)
    window_size             = optional(string)
    auto_mitigation_enabled = optional(bool)
    severity                = optional(number)
    enabled                 = optional(bool)
    dimension  = optional(object({
      name = string,
      operator = string,
      values = list(string)
    }))
  }))
  description = "A list of metricts we want to monitor. For details see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert#argument-reference"
  default     = []
}
