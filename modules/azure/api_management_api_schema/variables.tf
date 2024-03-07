variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "api_management_name" {
  type        = string
  description = "The name of the API management service."
}

variable "schema" {
  type = object({
    file_location = string,
    type          = string,
    schema_id     = string
  })

  description = "Schema for validation of request"
}