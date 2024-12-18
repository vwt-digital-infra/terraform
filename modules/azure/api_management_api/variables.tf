variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "api_management_name" {
  type        = string
  description = "The name of the API management service."
}

variable "api_settings" {
  type = object({
    name                  = string,
    description           = optional(string),
    service_url           = string,
    revision              = string,
    basepath              = string,
    subscription_required = string,
    openapi_file_path     = optional(string),
    wsdl_file_path        = optional(string)
  })
  description = "Settings to use for this API. Either Openapi or wsdl file path should be set."
}

variable "app_api_endpoint" {
  type        = string
  description = "The endpoint for the app's api. Defaults to the api's name when left empty"
  default     = null
}

variable "wsdl_selector" {
  type = object({
    service_name  = string,
    endpoint_name = string
  })
  description = "A selector for the wsdl file when only part of the document should be used"
  default     = null
}

variable "owners" {
  type        = list(any)
  description = "List of AAD object IDs to set as API management owners."
  default     = []
}

variable "group_id" {
  type        = string
  description = "Group ID where service principal of the existing application will belong to"
  default     = null
}

variable "api_management_logger_id" {
  type        = string
  description = "The Id of the API management Logger"
  default     = null
}

variable "api_diagnostic_settings" {
  type = object({
    sampling_percentage       = number,
    always_log_errors         = bool,
    log_client_ip             = bool,
    verbosity                 = string, # possible values: verbose, information, error
    http_correlation_protocol = string, # possible values: None, Legacy, W3C,
    headers_to_log_request    = list(string),
    headers_to_log_response   = list(string)
  })

  description = "Settings for api diagnostics, If not needed just privide a null value, Will be created only if api_management_logger_id have beeen provided"

  default = {
    sampling_percentage       = 5.0,
    always_log_errors         = true,
    log_client_ip             = true,
    verbosity                 = "verbose", # possible values: verbose, information, error
    http_correlation_protocol = "W3C"
    headers_to_log_request    = ["content-type", "accept", "origin"],
    headers_to_log_response   = ["content-type", "content-length", "origin"]
  }
}

variable "authorization_tenant" {
  type        = string
  description = "the tenant to use for oauth requests. If not using custom auth/token endpoints this value should be set"
  default     = null
}

variable "auth_endpoint" {
  type        = string
  description = "Override for authorization endpoint in case custom oauth2 endpoints are used."
  default     = null
}

variable "token_endpoint" {
  type        = string
  description = "Override for token endpoint in case custom oauth2 endpoints are used."
  default     = null
}

variable "client_registration_endpoint" {
  type        = string
  description = "URI/URL for the location of client & app registration."
  default     = "http://localhost"
}

variable "developer_portal_url" {
  type        = string
  description = "url to the apim developer portal where this api is located"
  default     = null
}

#######################################################
##########      Authentication Settings      ##########
#######################################################

variable "backend_type" {
  type        = string
  description = "The type of backend used by the api. Should be public, basic-auth, body-auth or managed-identity"

  validation {
    condition     = contains(["public", "basic-auth", "managed-identity", "body-auth", "oauth", "api-token"], var.backend_type)
    error_message = "Argument \"backend_type\" must be either \"public\", \"basic-auth\", \"body-auth\", \"oauth\" , \"api-token\" or \"managed-identity\"."
  }
}

variable "basic_auth_settings" {
  type = object({
    key_vault_id    = optional(string),
    username_secret = optional(string),
    password_secret = optional(string),
    username        = optional(string),
    password        = optional(string),
  })
  description = "Settings to be used for basic auth, one can either use a key vault or provide the username and password directly using named values."
  default     = null
}

variable "aad_settings" {
  type = object({
    openid_url = string,
    issuer     = string,
  })
  description = "An object representing the settings to be used for AAD authentication"
}

variable "application_name" {
  type        = string
  description = "The name to use for the application created to verify AAD authorization"
}

variable "managed_identity_resource" {
  type        = string
  description = "The resource to validate the managed identity"
  default     = null
}

variable "body_auth_settings" {
  type = object({
    key_vault_id    = string,
    username_key    = string,
    username_secret = string,
    password_secret = string,
    password_key    = string,
  })
  description = "Values used for body authentication"
  default     = null
}

variable "soap_body_key" {
  type        = string
  description = "The key used to prepend a json object in the body: {key: {object}} to transform for SOAP api as REST"
  default     = null
}

variable "soap_pass_through" {
  type        = string
  description = "defines wether soap api should be converted to REST API"
  default     = false
}

variable "oauth_settings" {
  type = object({
    tenant_id     = string, // May contain value or APIM variable: {{var_name}}
    scope         = string, // May contain value or APIM variable: {{var_name}}
    client_id     = string, // May contain value or APIM variable: {{var_name}}
    client_secret = string, // May contain value or APIM variable: {{var_name}}
  })
  description = "Values used for oAuth authentication to the back-end"
  default     = null
}

variable "api_token_settings" {
  type = object({
    prefix = optional(string), // fe Bearer or ApiToken
    token  = string            // Can be value or APIM named value: {{var_name}}
  })
  description = "Values for api-token authentication"
  default     = null
}


variable "custom_xml_policy_append" {
  type        = string
  description = "Additional xml policies to add to the policy"
  default     = null
}

variable "custom_xml_policy_prepend" {
  type        = string
  description = "Additional xml policies to add to the policy before the default authentification policies are applied"
  default     = null
}

variable "custom_outbound_policy" {
  type        = string
  description = "Additional outbound xml policies"
  default     = null
}

variable "custom_backend_policy" {
  type        = string
  description = "Additional backend xml policies"
  default     = null
}

variable "role_assignments" {
  type        = list(string)
  description = "Roles to validate in the JWT token's 'roles' claim for access control."
  default     = []
}