output "appregistration_client_id" {
  value     = azuread_application.adappregistration.client_id
  sensitive = false
}

output "appregistration_id" {
  value = azuread_application.adappregistration.id
}

output "appregistration_client_secret" {
  value     = azuread_application_password.ad_application_password.value
  sensitive = true
}

output "identifier_uris" {
  value = azuread_application.adappregistration.identifier_uris
}

output "permission_scope_ids" {
  value = azuread_application.adappregistration.oauth2_permission_scope_ids
}

