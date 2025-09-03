data "azurerm_subscription" "current" {}

data "azuread_group" "adgroup" {
  display_name = "AZU_${data.azurerm_subscription.current.display_name}_Contributor"
}

data "azuread_service_principal" "terraform_service_principal" {
  count        = var.terraform_service_principal_object_id == null && var.terraform_service_principal_client_id == null && var.terraform_service_principal_display_name == null ? 0 : 1
  object_id    = var.terraform_service_principal_object_id
  client_id    = var.terraform_service_principal_client_id
  display_name = var.terraform_service_principal_display_name
}

resource "random_uuid" "app_role_id" {
  for_each = var.app_roles
}

resource "random_uuid" "app_reg_user_impersonation" {
  for_each = var.oauth2_permission_scopes
}

locals {
  app_name = var.display_name == null ? (
    var.resource_identifier == null ? "gb-${var.name}-${var.environment}" : "gb-${var.name}-${var.resource_identifier}-${var.environment}"
  ) : var.display_name
}

resource "azuread_application" "adappregistration" {
  display_name = local.app_name

  identifier_uris = var.is_frontend ? [] : (
    var.identifier_uri_with_name ? [
      "api://${lower(local.app_name)}.azurewebsites.net"
    ] : []
  )

  owners = length(data.azuread_service_principal.terraform_service_principal) == 0 ? var.owners : (
    concat(var.owners, [data.azuread_service_principal.terraform_service_principal[0].object_id])
  )
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
    for_each = var.app_roles
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      enabled              = app_role.value.enabled
      id                   = random_uuid.app_role_id[app_role.key].result
      value                = app_role.key
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
          value   = scope.key
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      optional_claims,
      identifier_uris
    ]
  }
}

resource "azuread_application_identifier_uri" "identifier_uri" {
  count          = (var.identifier_uris == null || var.identifier_uri_with_name) ? 0 : length(var.identifier_uris)
  application_id = azuread_application.adappregistration.id
  identifier_uri = var.identifier_uris[count.index]
}

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

  depends_on = [
    time_rotating.expiration_date
  ]
}

resource "azuread_application_pre_authorized" "pre_authorized_clients" {
  application_id       = azuread_application.adappregistration.id
  authorized_client_id = var.authorized_app_id

  permission_ids = [
    for key in random_uuid.app_reg_user_impersonation : key.result
  ]

  depends_on = [
    azuread_application.adappregistration,
    random_uuid.app_reg_user_impersonation
  ]
}
