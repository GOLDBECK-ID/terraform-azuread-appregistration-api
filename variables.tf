variable "random_uuid_app_reg_user_impersonation_result" {
  description = "Random UUID Application Registry User Impersonation."
  type        = string
  default     = "random-uuid"
}

variable "name" {
  description = "The name of the App Registration."
  type        = string
  default     = ""
}

variable "resourceIdentifier" {
  description = "Identifier of the resource e.g. api or app."
  type        = string
  default     = ""
}

variable "owners" {
  description = "IDs of the owner"
  type        = list(string)
  default     = [""]
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
  default     = ""
}

variable "client_secret_expiration_date" {
  description = "the expiration date used for secrets etc."
  type        = string
  default     = "2099-12-31T23:59:59Z"
}

variable "is_frontend" {
  description = "Distinguish between frontend and backend registration"
  type        = bool
  default     = false
}

variable "spa_redirect_uris" {
  type    = list(string)
  default = []
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
}
variable "web_redirect_uris" {
  type    = list(string)
  default = []
}