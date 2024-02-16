mock_provider "azuread" {}
mock_provider "azurerm" {}

variables {
  name               = "name"
  resourceIdentifier = "resourceIdentifier"
  environment        = "environment"
  owners             = ["8673a88b-805d-435f-b1da-45c74574d607"]
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

  assert {
    condition     = azuread_application.adappregistration.display_name == "gb-name-resourceIdentifier-environment"
    error_message = "incorrect displayName"
  }

  assert {
    condition     = azuread_application_password.ad_application_password.display_name != "gb-name-resourceIdentifier-environment"
    error_message = "incorrect display name in application password resource."
  }

  assert {
    condition     = azuread_application_password.ad_application_password.display_name == "gb-name-resourceIdentifier-environment-secret"
    error_message = "incorrect display name in application password resource."
  }
}

run "api" {
  command = plan

  variables {
    authorized_app_id = "8673a88b-805d-435f-b1da-45c74574d607"
    web_redirect_uris = ["https://some-url.com/, https://some-url.com"]
  }

  assert {
    condition     = length(azuread_application.adappregistration.identifier_uris) > 0
    error_message = "Api needs identifier_uris. Current length is: ${length(azuread_application.adappregistration.identifier_uris)}"
  }

  assert {
    condition     = length(azuread_application.adappregistration.web) > 0
    error_message = "With var.web_redirect_uris there are a web block. Current length is: ${length(azuread_application.adappregistration.web)}"
  }
}

run "app" {
  command = plan

  variables {
    is_frontend   = true
    redirect_uris = ["http://localhost:4200/"]
  }

  assert {
    condition     = length(azuread_application.adappregistration.identifier_uris) == 0
    error_message = "App do not need any identifier_uris."
  }

  assert {
    condition     = length(azuread_application.adappregistration.web) > 0
    error_message = "With var.web_redirect_uris there are a web block. Current length is: ${length(azuread_application.adappregistration.web)}"
  }

  assert {
    condition     = length(azuread_application.adappregistration.single_page_application) != 0
    error_message = "With redirect_uris single_page_application will be created."
  }
}