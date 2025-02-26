data "azurerm_subscription" "current" {}

data "azuread_group" "adgroup" {
  display_name = "AZU_${data.azurerm_subscription.current.display_name}_Contributor"
}

resource "random_uuid" "app_reg_user_impersonation" {
  count = var.authorized_app_id == null ? 0 : var.is_frontend ? 0 : 1
}

resource "random_uuid" "app_role_id" {
  count = var.app_roles == null ? 0 : length(var.app_roles)
}

locals {
  app_name = length(var.resourceIdentifier) == 0 ? "gb-${var.name}-${var.environment}" : "gb-${var.name}-${var.resourceIdentifier}-${var.environment}"
}

# Manages an application registration within Azure Active Directory.
# 
# For a more lightweight alternative, please see the azuread_application_registration resource.
# Please note that this resource should not be used together with the azuread_application_registration resource when managing the same application.
resource "azuread_application" "adappregistration" {
  display_name = local.app_name

  identifier_uris = var.is_frontend ? [] : [
    "api://${lower(local.app_name)}.azurewebsites.net"
  ]

  owners                         = var.owners
  sign_in_audience               = var.sign_in_audience
  group_membership_claims        = var.group_membership_claims
  fallback_public_client_enabled = var.fallback_public_client_enabled
  dynamic "feature_tags" {
    for_each = var.feature_tags == null ? [] : var.feature_tags
    content {
      custom_single_sign_on = feature_tags.value.custom_single_sign_on
      enterprise            = feature_tags.value.enterprise
      gallery               = feature_tags.value.gallery
      hide                  = feature_tags.value.hide
    }
  }

  single_page_application {
    redirect_uris = var.spa_redirect_uris
  }

  web {
    redirect_uris = var.web_redirect_uris
    implicit_grant {
      id_token_issuance_enabled = true
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

  dynamic "app_role" {
    for_each = var.app_roles == null ? [] : var.app_roles
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      enabled              = app_role.value.enabled
      id                   = random_uuid.app_role_id[app_role.key].result
      value                = app_role.value.value
    }
  }

  dynamic "api" {
    for_each = var.is_frontend ? [] : [1]
    content {
      mapped_claims_enabled          = false
      requested_access_token_version = 1

      oauth2_permission_scope {
        admin_consent_display_name = "Allow the application to access (${lower(local.app_name)}) on behalf of the signed-in user."
        admin_consent_description  = "Access api (${lower(local.app_name)})"
        user_consent_description   = "Allow the application to access the api on your behalf."
        user_consent_display_name  = "Access ${lower(local.app_name)}"

        enabled = true
        id      = random_uuid.app_reg_user_impersonation[0].result
        type    = "User"
        value   = "user_impersonation"
      }
    }
  }
  lifecycle {
    ignore_changes = [
      optional_claims,
      single_page_application
    ]
  }
}

# Manages a service principal associated with an application within Azure Active Directory.
resource "azuread_service_principal" "ad_service_principal" {
  client_id                    = azuread_application.adappregistration.client_id
  app_role_assignment_required = var.azuread_service_principal_assignment_required
  owners                       = var.owners
}

resource "azuread_application_password" "ad_application_password" {
  application_id = azuread_application.adappregistration.id
  display_name   = "${local.app_name}-secret"
  end_date       = var.expiration_date
}

resource "azuread_application_pre_authorized" "pre_authorized_clients" {
  count                = var.authorized_app_id == "" ? 0 : 1
  application_id       = azuread_application.adappregistration.id
  authorized_client_id = var.authorized_app_id
  permission_ids       = [random_uuid.app_reg_user_impersonation[0].result]

  depends_on = [random_uuid.app_reg_user_impersonation]
}
