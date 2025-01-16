variable "location" {
  type        = string
  description = "A datacenter location in Azure."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "server_name" {
  type        = string
  description = "Name of the mysql server."
}

variable "server_sku" {
  type        = string
  description = "Specifies the sku for the mysql server"
  default     = "GP_Standard_D2ds_v4"
}

variable "server_storage_max" {
  type        = number
  description = "Max storage allowed in GB for the mysql server."
  default     = 20
}

variable "server_version" {
  type        = string
  description = "Mysql server version."
}

variable "storage_auto_grow_enabled" {
  type        = bool
  description = "Enables auto-growing of mysql server storage."
  default     = true
}

variable "backup_retention_days" {
  type        = number
  description = "Backup retention days for the mysql server."
  default     = 30
}

variable "geo_redundant_backup_enabled" {
  type        = bool
  description = "Enables geo-redundant mysql server backups."
  default     = true
}

variable "database_name" {
  type        = string
  description = "Name of the mysql database."
}

variable "database_charset" {
  type        = string
  description = "Specifies the charset for the mysql database."
  default     = "utf8mb3"
}

variable "database_collation" {
  type        = string
  description = "Specifies the collation for the mysql database."
  default     = "utf8mb3_unicode_ci"
}

variable "admin_username" {
  type        = string
  description = "The administrator login username for the mysql server."
}

variable "entra_administrator_enabled" {
  type        = bool
  description = "Specifies whether or not Entra authentication is enabled for this MySQL Server"
  default     = false
}

variable "entra_identity_id" {
  type        = string
  description = "The Entra identity id for the mysql server."
  default     = null
}

variable "entra_login" {
  type        = string
  description = "The Entra administrator login username for the mysql server."
  default     = null
}

variable "entra_object_id" {
  type        = string
  description = "The Entra object id for the mysql server."
  default     = null
}

variable "entra_tenant_id" {
  type        = string
  description = "The Entra tenant id for the mysql server."
  default     = null
}

variable "password_keeper" {
  type        = map(string)
  description = "Random map of strings, when changed the mysql admin password will rotate."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID of a log analytics workspace (optional)."
  default     = null
}

variable "slow_query_log" {
  type        = string
  description = "Slow query log. ON or OFF (default)"
  default     = "OFF"
}

variable "whitelist_ip_addresses" {
  type        = set(string)
  description = "List of IP addresses to whitelist."
  default     = []
}
