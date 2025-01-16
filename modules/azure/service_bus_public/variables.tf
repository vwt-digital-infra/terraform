variable "location" {
  type        = string
  description = "A datacenter location in Azure."
}

variable "name" {
  type        = string
  description = "Name of the service bus."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "sku" {
  type        = string
  description = "Stock Keeping Unit of the service bus."
  default     = "Standard"
}

variable "authorization_rule" {
  type = object({
    listen = bool
    send   = bool
    manage = bool
  })
  description = "Manages a ServiceBus Namespace authorization Rule within the ServiceBus."
  default     = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Specifies the ID of a Log Analytics Workspace where diagnostics data should be sent."
  default     = null
}

variable "minimum_tls_version" {
  type        = string
  description = "Specifies the minimum version of TLS to use (1.0 and 1.2 are deprecated from Feb 2025)"
  default     = "1.2"
}
