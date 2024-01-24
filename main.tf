data "azuread_group" "adgroup" {
  display_name = "AZU_${upper(var.name)}-App-${title(var.environment)}_Contributor"
}

# Manages an application registration within Azure Active Directory.
# 
# For a more lightweight alternative, please see the azuread_application_registration resource.
# Please note that this resource should not be used together with the azuread_application_registration resource when managing the same application.
resource "azuread_application" "adappregistration" {
  display_name     = "gb-${var.name}-${var.resourceIdentifier}-${var.environment}"
  identifier_uris  = var.is_frontend ? [] : ["api://gb-${lower(var.name)}-${var.resourceIdentifier}-${var.environment}.azurewebsites.net"]
  owners           = var.owners
  sign_in_audience = var.sign_in_audience

  web {
    redirect_uris = var.web_redirect_uris
    implicit_grant {
      id_token_issuance_enabled = true
    }
  }

  single_page_application {
    redirect_uris = var.redirect_uris
  }

  dynamic "required_resource_access" {
    for_each = var.required_resource_access
    iterator = resource
    content {
      resource_app_id = resource.value.resource_app_id

      dynamic "resource_access" {
        for_each = resource.value.resource_access
        iterator = access
        content {
          id   = access.value.id
          type = access.value.type
        }
      }
    }
  }

  dynamic "api" {
    for_each = var.is_frontend ? [] : [1]
    content {
      mapped_claims_enabled          = false
      requested_access_token_version = 1

      oauth2_permission_scope {
        admin_consent_display_name = "Allow the application to access (gb-${lower(var.name)}-${var.resourceIdentifier}-${var.environment}) on behalf of the signed-in user."
        admin_consent_description  = "Access api (gb-${lower(var.name)}-${var.resourceIdentifier}-${var.environment})"
        enabled                    = true
        id                         = var.random_uuid_app_reg_user_impersonation_result
        type                       = "User"
        user_consent_description   = "Allow the application to access the api on your behalf."
        user_consent_display_name  = "Access gb-${lower(var.name)}-${var.resourceIdentifier}-${var.environment}"
        value                      = "user_impersonation"
      }
    }
  }
  lifecycle {}
}

# Manages a service principal associated with an application within Azure Active Directory.
resource "azuread_service_principal" "ad_service_principal" {
  client_id                    = azuread_application.adappregistration.client_id
  app_role_assignment_required = var.azuread_service_principal_assignment_required
}

resource "azuread_application_password" "ad_application_password" {
  application_id = azuread_application.adappregistration.id
  display_name   = "gb-${var.name}-${var.resourceIdentifier}-${var.environment}-secret"
  end_date       = var.client_secret_expiration_date
}