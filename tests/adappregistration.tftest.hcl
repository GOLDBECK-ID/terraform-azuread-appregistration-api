mock_provider "azuread" {}
mock_provider "azurerm" {}

variables {
  name        = "name"
  environment = "environment"
  owners      = ["8673a88b-805d-435f-b1da-45c74574d607"]
  app_roles = [
    {
      allowed_member_types = ["User"]
      description          = "User impersonation"
      display_name         = "User impersonation"
      value                = "user_impersonation"
      enabled              = true
    }
  ]
  required_resource_access = [
    {
      resource_app_id = "some-id"
      resource_access = [
        {
          id   = "8673a88b-805d-435f-b1da-45c74574d607"
          type = "Scope"
        }
      ]
    }
  ]
}

run "general" {
  command = plan

  variables {
    resourceIdentifier = "resourceIdentifier"
  }

  assert {
    condition     = output.display_name == "gb-${var.name}-${var.resourceIdentifier}-${var.environment}"
    error_message = "incorrect displayName"
  }

  assert {
    condition     = azuread_application.adappregistration.display_name == "gb-${var.name}-${var.resourceIdentifier}-${var.environment}"
    error_message = "incorrect displayName"
  }

  assert {
    condition     = azuread_application_password.ad_application_password.display_name != "gb-${var.name}-${var.resourceIdentifier}-${var.environment}"
    error_message = "incorrect display name in application password resource."
  }

  assert {
    condition     = azuread_application_password.ad_application_password.display_name == "gb-${var.name}-${var.resourceIdentifier}-${var.environment}-secret"
    error_message = "incorrect display name in application password resource."
  }
}

run "api" {
  command = plan

  variables {
    authorized_app_id = "8673a88b-805d-435f-b1da-45c74574d607"
    web = {
      homepage_url = "https://some-url.com"
      implicit_grant = {
        access_token_issuance_enabled = true
        id_token_issuance_enabled     = true
      }
      logout_url    = "https://some-url.com"
      redirect_uris = ["https://some-url.com/, https://some-url.com"]
    }
  }

  assert {
    condition     = length(azuread_application.adappregistration.identifier_uris) > 0
    error_message = "Api needs identifier_uris. Current length is: ${length(azuread_application.adappregistration.identifier_uris)}"
  }

  assert {
    condition     = length(azuread_application.adappregistration.web) > 0
    error_message = "With var.web.redirect_uris there are a web block. Current length is: ${length(azuread_application.adappregistration.web)}"
  }
}

run "app" {
  command = plan

  variables {
    is_frontend = true
  }

  assert {
    condition     = length(azuread_application.adappregistration.identifier_uris) == 0
    error_message = "App do not need any identifier_uris."
  }

  assert {
    condition     = length(azuread_application.adappregistration.web) == 0
    error_message = "With var.web.redirect_uris there are a web block. Current length is: ${length(azuread_application.adappregistration.web)}"
  }
}

run "empty_identifier" {
  command = plan

  assert {
    condition     = azuread_application.adappregistration.display_name == "gb-${var.name}-${var.environment}"
    error_message = "incorrect displayName"
  }
}
