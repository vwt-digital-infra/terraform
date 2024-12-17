terraform {
  required_version = "~> 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.48"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.36"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

locals {
  //Do this if statement here instead of twice for both api:// settings
  app_api_endpoint    = var.app_api_endpoint != null ? var.app_api_endpoint : "${lower(replace(var.application_name, " ", "-"))}"
  should_assign_group = var.group_id != null ? true : false
}

#######################################################
##########                API                ##########
#######################################################

resource "azurerm_api_management_api" "api" {
  name                  = lower(replace(var.api_settings.name, " ", "-"))
  description           = var.api_settings.description
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  service_url           = var.api_settings.service_url
  revision              = var.api_settings.revision
  display_name          = var.api_settings.name
  path                  = var.api_settings.basepath
  protocols             = ["https"]
  subscription_required = var.api_settings.subscription_required

  depends_on = [
    azurerm_api_management_authorization_server.oauth2
  ]
  oauth2_authorization {
    authorization_server_name = "${lower(replace(var.api_settings.name, " ", "-"))}-auth"
  }

  soap_pass_through = var.soap_pass_through

  import {
    content_format = var.api_settings.openapi_file_path != null ? "openapi" : "wsdl"
    content_value  = var.api_settings.openapi_file_path != null ? file(var.api_settings.openapi_file_path) : file(var.api_settings.wsdl_file_path)

    dynamic "wsdl_selector" {
      for_each = var.wsdl_selector != null ? [1] : []
      content {
        service_name  = var.wsdl_selector.service_name
        endpoint_name = var.wsdl_selector.endpoint_name
      }
    }
  }
}

######################################################
###########         API Diagnostics        ###########
######################################################

resource "azurerm_api_management_api_diagnostic" "api_diagnostic" {
  count = var.api_management_logger_id != null ? 1 : 0

  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = var.api_management_name
  api_name                 = azurerm_api_management_api.api.name
  api_management_logger_id = var.api_management_logger_id

  sampling_percentage       = var.api_diagnostic_settings.sampling_percentage
  always_log_errors         = var.api_diagnostic_settings.always_log_errors
  log_client_ip             = var.api_diagnostic_settings.log_client_ip
  verbosity                 = var.api_diagnostic_settings.verbosity
  http_correlation_protocol = var.api_diagnostic_settings.http_correlation_protocol

  frontend_request {
    body_bytes     = 32
    headers_to_log = var.api_diagnostic_settings.headers_to_log_request
  }

  frontend_response {
    body_bytes     = 32
    headers_to_log = var.api_diagnostic_settings.headers_to_log_response
  }

  backend_request {
    body_bytes     = 32
    headers_to_log = var.api_diagnostic_settings.headers_to_log_request
  }

  backend_response {
    body_bytes     = 32
    headers_to_log = var.api_diagnostic_settings.headers_to_log_response
  }
}

#######################################################
##########            API Policy             ##########
#######################################################

resource "azurerm_api_management_api_policy" "api_policy" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
  <base />
    %{if var.custom_xml_policy_prepend != null}
      ${var.custom_xml_policy_prepend}
      %{endif}

    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
      <openid-config url="${var.aad_settings.openid_url}"/>
      <required-claims>
        <claim name="aud" match="any">
          <value>${azuread_application.application.application_id}</value>
        </claim>
        <claim name="iss" match="any">
          <value>${var.aad_settings.issuer}</value>
        </claim>
        %{if var.role_assignment != null}
          <claim name="roles" match="any">
            <value>${var.role_assignment}</value>
          </claim>
        %{endif}
      </required-claims>
    </validate-jwt>
    %{if var.backend_type == "managed-identity"}
    <authentication-managed-identity resource="${var.managed_identity_resource}" output-token-variable-name="msi-access-token" ignore-error="false" />
      <set-header name="Authorization" exists-action="override">
        <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
      </set-header>
    %{endif}
    %{if var.backend_type == "basic-auth"}
    <authentication-basic username="${var.basic_auth_settings.username != null ? var.basic_auth_settings.username : data.azurerm_key_vault_secret.username[0].value}" password="${var.basic_auth_settings.password != null ? var.basic_auth_settings.password : data.azurerm_key_vault_secret.password[0].value}" />
    %{endif}
    %{if var.backend_type == "body-auth"}
    <set-body>@{
        var body = context.Request.Body.As<JObject>();
        %{if var.soap_body_key != null}
        body["${var.soap_body_key}"]["${var.body_auth_settings.username_key}"] = "${data.azurerm_key_vault_secret.body_username[0].value}";
        body["${var.soap_body_key}"]["${var.body_auth_settings.password_key}"] = "${data.azurerm_key_vault_secret.body_password[0].value}";
        %{else}
        body["${var.body_auth_settings.username_key}"] = "${data.azurerm_key_vault_secret.body_username[0].value}";
        body["${var.body_auth_settings.password_key}"] = "${data.azurerm_key_vault_secret.body_password[0].value}";
        %{endif}
        return body.ToString();
        }
    </set-body>
    %{endif}
    %{if var.backend_type == "oauth"}
    <send-request ignore-error="true" timeout="20" response-variable-name="bearerToken" mode="new">
      <set-url>https://login.microsoftonline.com/${var.oauth_settings.tenant_id}/oauth2/v2.0/token</set-url>
      <set-method>POST</set-method>
      <set-header name="Content-Type" exists-action="override">
        <value>application/x-www-form-urlencoded</value>
      </set-header>
      <set-body>@{
        return "client_id=${var.oauth_settings.client_id}&scope=${var.oauth_settings.scope}&client_secret=${var.oauth_settings.client_secret}&grant_type=client_credentials";
        }
      </set-body>
    </send-request>
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (String)((IResponse)context.Variables["bearerToken"]).Body.As<JObject>()["access_token"])</value>
    </set-header>
    %{endif}
    <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
    %{if var.backend_type == "api-token"}
    <set-header name= "Authorization" exists-action="override">
      %{if var.api_token_settings.prefix != null}
      <value>${var.api_token_settings.prefix} ${var.api_token_settings.token}</value>
      %{else}
      <value>${var.api_token_settings.token}</value>
      %{endif}
    </set-header>
    %{endif}
    %{if var.custom_xml_policy_append != null}
    ${var.custom_xml_policy_append}
    %{endif}
  </inbound>

  <backend>    
    %{if var.custom_backend_policy != null}
    ${var.custom_backend_policy}
    %{else}
    <base />
    %{endif}
  </backend>

  <outbound> 
    <base />
    %{if var.custom_outbound_policy != null}
    ${var.custom_outbound_policy}
    %{endif}
  </outbound>
</policies>
XML
}

######################################################
##########        Basic-auth serets        ###########
######################################################

data "azurerm_key_vault_secret" "username" {
  count        = var.backend_type == "basic-auth" && (var.basic_auth_settings != null ? var.basic_auth_settings.username_secret != null : false) ? 1 : 0
  name         = var.basic_auth_settings.username_secret
  key_vault_id = var.basic_auth_settings.key_vault_id
}

data "azurerm_key_vault_secret" "password" {
  count        = var.backend_type == "basic-auth" && (var.basic_auth_settings != null ? var.basic_auth_settings.password_secret != null : false) ? 1 : 0
  name         = var.basic_auth_settings.password_secret
  key_vault_id = var.basic_auth_settings.key_vault_id
}

######################################################
##########        Body-auth serets        ###########
######################################################

data "azurerm_key_vault_secret" "body_username" {
  count        = var.backend_type == "body-auth" ? 1 : 0
  name         = var.body_auth_settings.username_secret
  key_vault_id = var.body_auth_settings.key_vault_id
}

data "azurerm_key_vault_secret" "body_password" {
  count        = var.backend_type == "body-auth" ? 1 : 0
  name         = var.body_auth_settings.password_secret
  key_vault_id = var.body_auth_settings.key_vault_id
}

######################################################
#############        API products        #############
######################################################
resource "azurerm_api_management_product" "product" {
  product_id            = azurerm_api_management_api.api.name
  api_management_name   = var.api_management_name
  resource_group_name   = var.resource_group_name
  display_name          = azurerm_api_management_api.api.display_name
  subscription_required = true
  published             = true
}

resource "azurerm_api_management_product_api" "product_api" {
  api_name            = azurerm_api_management_api.api.name
  product_id          = azurerm_api_management_product.product.product_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
}

######################################################
###########      OIDC authentication       ###########
######################################################

data "azuread_client_config" "current" {}

resource "azuread_application" "application" {
  display_name     = var.application_name
  owners           = concat([data.azuread_client_config.current.object_id], var.owners)
  sign_in_audience = "AzureADMyOrg"
  identifier_uris  = ["api://${local.app_api_endpoint}"]

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Default user access to API"
      admin_consent_display_name = "Default"
      enabled                    = true
      id                         = random_uuid.oath2_uuid.result
      type                       = "Admin"
      user_consent_description   = "Default user access to API"
      user_consent_display_name  = "Default"
      value                      = "Default.OAuth"
    }
  }
  app_role {
    allowed_member_types = ["Application", "User"]
    description          = "Default application app role"
    display_name         = "Default"
    enabled              = true
    id                   = random_uuid.app_role_uuid.result
    value                = "Default.Access"
  }

  web {
    redirect_uris = ["${var.developer_portal_url}/signin-oauth/code/callback/${lower(replace(var.api_settings.name, " ", "-"))}-auth"]
  }
}

resource "azurerm_api_management_authorization_server" "oauth2" {
  name                         = "${lower(replace(var.api_settings.name, " ", "-"))}-auth"
  authorization_methods        = ["GET", "POST"]
  api_management_name          = var.api_management_name
  resource_group_name          = var.resource_group_name
  display_name                 = "${lower(replace(var.api_settings.name, " ", "-"))}-auth"
  grant_types                  = ["authorizationCode"]
  authorization_endpoint       = var.auth_endpoint != null ? var.auth_endpoint : "https://login.microsoftonline.com/${var.authorization_tenant}/oauth2/v2.0/authorize"
  token_endpoint               = var.token_endpoint != null ? var.token_endpoint : "https://login.microsoftonline.com/${var.authorization_tenant}/oauth2/v2.0/token"
  client_registration_endpoint = var.client_registration_endpoint
  client_id                    = azuread_application.application.application_id
  client_secret                = azuread_application_password.password.value
  bearer_token_sending_methods = ["authorizationHeader"]
  client_authentication_method = ["Body"]
  default_scope                = "api://${local.app_api_endpoint}/Default.OAuth"

}

resource "azuread_service_principal" "application" {
  count                        = local.should_assign_group ? 1 : 0
  application_id               = azuread_application.application.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_group_member" "registered_app_member" {
  count            = local.should_assign_group ? 1 : 0
  group_object_id  = var.group_id
  member_object_id = azuread_service_principal.application[0].object_id
}

resource "azuread_application_password" "password" {
  application_object_id = azuread_application.application.object_id
}

resource "random_uuid" "oath2_uuid" {}

resource "random_uuid" "app_role_uuid" {}
