mock_provider "azuread" {}
mock_provider "azurerm" {}
mock_provider "random" {}

run "adappregistration" {
  command = plan

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

  assert {
    condition     = azuread_application.adappregistration.display_name == "gb-name-resourceIdentifier-environment"
    error_message = "incorrect displayName"
  }

}