variable "authorized_app_id" {
  description = "Authorized client application in settings 'Expose an API'"
  type        = string
  default     = ""
  nullable    = true
}

variable "name" {
  description = "The name of the App Registration."
  type        = string
  default     = ""
  nullable    = false
}

variable "resourceIdentifier" {
  description = "Identifier of the resource e.g. api or app."
  type        = string
  default     = ""
  nullable    = false
}

variable "owners" {
  description = "IDs of the owner"
  type        = list(string)
  default     = [""]
  nullable    = false
}

variable "sign_in_audience" {
  description = <<EOT
    The Microsoft account types that are supported for the current application.
    Must be one of [AzureADMyOrg], [AzureADMultipleOrgs], [AzureADandPersonalMicrosoftAccount] or [PersonalMicrosoftAccount]. Defaults to AzureADMyOrg.
  EOT
  type        = string
  default     = "AzureADMyOrg"
}

variable "environment" {
  description = "This variable specifies the current environment. Must be on of [dev],[test] or [prod]"
  type        = string
  default     = ""
  nullable    = false
}

variable "expiration_date" {
  description = "The expiration date used for secrets etc."
  type        = string
  default     = "2099-12-31T23:59:59Z"
}

variable "is_frontend" {
  description = "Distinguish between frontend and backend registration"
  type        = bool
  default     = false
}

variable "redirect_uris" {
  description = "A set of URLs where user tokens are sent for sign-in, or the redirect URIs where OAuth 2.0 authorization codes and access tokens are sent. Must be a valid https URL."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "required_resource_access" {
  description = <<EOT
  Required resource access for this application. A collection of required_resource_access blocks as documented below. Each block supports the following:

  [resource_access] (Required) A collection of resource_access blocks as documented below, describing OAuth2.0 permission scopes and app roles that the application requires from the specified resource.
  [resource_app_id] (Required) The unique identifier for the resource that the application requires access to. This should be the Application ID of the target application.
  EOT
  type = list(
    object({
      resource_app_id = string
      resource_access = list(
        object({
          id   = string
          type = string
      }))
  }))
  nullable = false
}
variable "web_redirect_uris" {
  type    = list(string)
  default = []
}

variable "azuread_service_principal_assignment_required" {
  description = "Whether this service principal requires an app role assignment to a user or group before Azure AD will issue a user or access token to the application. Defaults to false."
  type        = bool
  default     = false
}