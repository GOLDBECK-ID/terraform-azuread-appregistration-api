output "appregistration_client_id" {
  value     = azuread_application.adappregistration.application_id
  sensitive = false
}

output "appregistration_client_secret" {
  value     = azuread_service_principal_password.ad_service_principal_password.value
  sensitive = true
}

output "client_id" {
  value = azuread_application.adappregistration.application_id
}

output "identifier_uris" {
  value = azuread_application.adappregistration.identifier_uris
}

output "permission_scope_ids" {
  value = azuread_application.adappregistration.oauth2_permission_scope_ids
}

