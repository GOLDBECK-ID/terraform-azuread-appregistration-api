provider "azuread" {
  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
}

resource "random_uuid" "app_reg_uuid_user_impersonation" {}

data "azuread_group" "adgroup" {
  display_name = "AZU_${upper(var.name)}-App-${title(var.environment)}_Contributor"
}

resource "azuread_application" "adappregistration" {
  display_name     = "gb-${var.name}-${var.environment}"
  identifier_uris  = var.is_frontend ? [] : ["api://gb-${lower(var.name)}-${var.environment}.azurewebsites.net"]
  owners           = var.owners
  sign_in_audience = var.sign_in_audience

  web {
    redirect_uris = var.web_redirect_uris
    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
  
  dynamic "single_page_application" {
    for_each = var.is_frontend ? [1] : []
    content {
      redirect_uris = var.spa_redirect_uris
    }
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
        admin_consent_display_name = "Allow the application to access (gb-${lower(var.name)}-${var.environment}) on behalf of the signed-in user."
        admin_consent_description  = "Access api (gb-${lower(var.name)}-${var.environment})"
        enabled                    = true
        id                         = random_uuid.app_reg_uuid_user_impersonation.result
        type                       = "User"
        user_consent_description   = "Allow the application to access the api on your behalf."
        user_consent_display_name  = "Access gb-${lower(var.name)}-${var.environment}"
        value                      = "user_impersonation"
      }
    }
  }
  lifecycle {
    # ignore_changes = all
  }
}

resource "azuread_application_password" "ad_application_password" {
  application_id = azuread_application.adappregistration.id
  display_name   = "gb-${var.name}-${var.environment}-secret"
  end_date       = var.client_secret_expiration_date
}

resource "azuread_application_pre_authorized" "pre_authorized_clients" {
  application_id       = azuread_application.adappregistration.id
  authorized_client_id = var.authorized_app_id
  permission_ids       = [random_uuid.app_reg_uuid_user_impersonation.result]
}