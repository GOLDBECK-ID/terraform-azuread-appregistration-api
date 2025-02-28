data "azurerm_subscription" "current" {}

data "azuread_group" "adgroup" {
  display_name = "AZU_${data.azurerm_subscription.current.display_name}_Contributor"
}

resource "random_uuid" "app_reg_user_impersonation" {
  count = var.oauth2_permission_scopes == null ? (
    var.authorized_app_id == null ? 0 : var.is_frontend ? 0 : 1
  ) : length(var.oauth2_permission_scopes)
}

resource "random_uuid" "app_role_id" {
  count = var.app_roles == null ? 0 : length(var.app_roles)
}

locals {
  app_name = var.display_name == null ? (
    var.resourceIdentifier == null ? "gb-${var.name}-${var.environment}" : "gb-${var.name}-${var.resourceIdentifier}-${var.environment}"
  ) : var.display_name
}

# Manages an application registration within Azure Active Directory.
# 
# For a more lightweight alternative, please see the azuread_application_registration resource.
# Please note that this resource should not be used together with the azuread_application_registration resource when managing the same application.
resource "azuread_application" "adappregistration" {
  display_name = local.app_name

  identifier_uris = var.is_frontend ? [] : (
    var.identifier_uri_with_name ? [
      "api://${lower(local.app_name)}.azurewebsites.net"
    ] : []
  )

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

  dynamic "web" {
    for_each = var.web == null ? [] : [1]
    content {
      homepage_url  = var.web.homepage_url
      redirect_uris = var.web.redirect_uris
      dynamic "implicit_grant" {
        for_each = var.web.implicit_grant == null ? [] : [1]
        content {
          access_token_issuance_enabled = var.web.implicit_grant.access_token_issuance_enabled
          id_token_issuance_enabled     = var.web.implicit_grant.id_token_issuance_enabled
        }
      }
      logout_url = var.web.logout_url
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

      dynamic "oauth2_permission_scope" {
        for_each = var.oauth2_permission_scopes
        iterator = scope
        content {
          admin_consent_display_name = scope.value.admin_consent_display_name
          admin_consent_description  = scope.value.admin_consent_description
          user_consent_description   = scope.value.user_consent_description
          user_consent_display_name  = scope.value.user_consent_display_name

          enabled = scope.value.enabled
          id      = random_uuid.app_reg_user_impersonation[scope.key].result
          type    = scope.value.type
          value   = scope.value.value
        }
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

resource "azuread_application_identifier_uri" "identifier_uri" {
  count          = (var.identifier_uris == null || var.identifier_uri_with_name) ? 0 : length(var.identifier_uris)
  application_id = azuread_application.adappregistration.id
  identifier_uri = var.identifier_uris[count.index]
}

# Manages a service principal associated with an application within Azure Active Directory.
resource "azuread_service_principal" "ad_service_principal" {
  client_id                    = azuread_application.adappregistration.client_id
  app_role_assignment_required = var.azuread_service_principal_assignment_required
  owners                       = var.owners
}

resource "time_rotating" "expiration_date" {
  rotation_years = 2
}

resource "azuread_application_password" "ad_application_password" {
  application_id = azuread_application.adappregistration.id
  display_name   = "${local.app_name}-secret"
  rotate_when_changed = {
    rotation = time_rotating.expiration_date.id
  }

  lifecycle {
    ignore_changes = [
      rotate_when_changed,
      end_date,
      display_name
    ]
  }
}

resource "azuread_application_pre_authorized" "pre_authorized_clients" {
  for_each = var.authorized_app_id == null ? {} : var.oauth2_permission_scopes == null ? {} : {
    for idx, scope in var.oauth2_permission_scopes : idx => scope
  }

  application_id       = azuread_application.adappregistration.id
  authorized_client_id = var.authorized_app_id
  permission_ids = [
    random_uuid.app_reg_user_impersonation[each.key].result
  ]

  depends_on = [random_uuid.app_reg_user_impersonation]
}
