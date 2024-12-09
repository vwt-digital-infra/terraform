variable "location" {
  type        = string
  description = "A datacenter location in Azure."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "logic_app_name" {
  type        = string
  description = "Specifies the name of the logic app."
}

variable "service_plan_id" {
  type        = string
  description = "The ID of the Service Plan to use for this Logic App."
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account to connect to the logic app"
}

variable "storage_account_access_key" {
  type        = string
  description = "The access key of the storage account to connect to the logic app."
}

variable "enabled" {
  type        = bool
  description = "If this workflow should be enabled by default or not, defaults to true"
  default     = true
}

variable "use_managed_identity" {
  type        = bool
  description = "Use System Assigned Managed Identity for this logic app"
  default     = false
}

variable "identity_ids" {
  type        = list(string)
  description = "User Assigned Managed Identity ids for this logic app"
  default     = []
}

variable "app_settings" {
  type        = map(string)
  description = "A map of key/value pairs to be used as application settings for the logic app."
  default     = {}
}

variable "workflows_source_path" {
  type        = string
  description = "The path to the source code of all workflows."
}

variable "integration_subnet_id" {
  type        = string
  description = "The ID of the integration subnet to enable virtual network integration."
  default     = null
}

variable "elastic_instance_minimum" {
  type        = number
  description = "Minimum amount of elastic instances."
  default     = 1
}

variable "pre_warmed_instance_count" {
  type        = number
  description = "Amount of pre-warmed instances. Requires at least 1 for VNet-integration."
  default     = 0
}

variable "deployment_wait_timeout" {
  type        = number
  description = "The amount of time to wait for the deployment to start after the logic app was deployed."
  default     = 30
}

variable "https_only" {
  type        = bool
  description = "Allow only HTTPS access."
  default     = false
}

variable "logic_app_version" {
  type        = string
  description = "The runtime version associated with the Logic App."
  default     = "~4"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Specifies the ID of a Log Analytics Workspace where diagnostics data should be sent."
  default     = null
}
